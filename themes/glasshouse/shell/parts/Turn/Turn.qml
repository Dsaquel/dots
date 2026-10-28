import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.core
import qs.parts.Chat

Score {
    id: turn

    signal begin(string dir)
    signal clipStarted()
    signal contact(real at)
    signal switched(bool ok)
    signal waiting(bool on)
    signal rebuild()
    signal ended(bool ok)

    readonly property string target: turn.switchState === "failed" ? turn.leave : turn.arrive

    property bool warming: false
    property bool open: false
    property bool ok: false
    property string switchState: "idle"
    property real contactT: -1
    readonly property int contactFrame: dawn ? 70 : 35
    property var mainPane: null
    readonly property int clipFrame: turn.clap.landed
    property bool holdFirst: false
    property bool holdLast: false
    property bool heldFirst: false
    property bool heldLast: false

    property real slow: 1
    property bool fired: false

    property bool turned: false
    readonly property real clipPos: turn.mainPane ? turn.mainPane.clipPos : 0
    readonly property bool clipPlaying: turn.mainPane ? turn.mainPane.clipPlaying : false

    readonly property real shown: turn.holdLast || !turn.running ? 1 : 1 - turn.win(turn.fadeT, turn.endT)

    readonly property QtObject clap: Clap {
        turn: self
    }
    Connections {
        target: turn.clap.sink
        function onVideoFrameChanged(): void {
            if (turn.clipPlaying)
                turn.clap.arrivals++;
        }
    }
    onClipPosChanged: {
        if (!turn.clipPlaying)
            return;
        const p = turn.clipPos * 1000;
        if (p <= 0)
            return;
        const f = Math.round(p * 24 / 1000);
        const pts = f * 1000 / 24;
        const now = Date.now();
        turn.clap.offset = Math.min(turn.clap.offset, f - turn.clap.arrivals);
        turn.clap.hi = Math.min(turn.clap.hi, now - pts);
        turn.clap.lo = Math.max(turn.clap.lo, now - pts - 1000 / 24);
    }
    onClipPlayingChanged: if (turn.clipPlaying) turn.clap.reset()
    FrameAnimation {
        running: turn.running || turn.phase === "prep"
        onTriggered: {
            turn.clap.tick(smoothFrameTime);
            if (Test.on && frameTime > 0.024 && !turn.warming)
                turn.slowFrames.push([turn.phase === "prep" ? "prep" : Math.round(turn.t * 1000) / 1000, Math.round(frameTime * 1000)]);

        }
    }
    property var slowFrames: []

    NumberAnimation {
        id: anim
        target: turn
        property: "t"
        from: turn.startT
        to: turn.endT
        duration: (turn.endT - turn.startT) * 1000 * turn.slow
        onFinished: turn.finish()
    }

    onTChanged: {
        if (!turn.running || turn.warming)
            return;
        if (turn.switchState === "idle" && turn.t >= turn.switchT)
            turn.runSwitch();
        if (!turn.fired && turn.t >= turn.clipT) {
            turn.fired = true;
            for (const p of turn.panes)
                p.playClip();
            turn.clipStarted();
        }
        for (const p of turn.panes)
            p.guardClip();
        if (!turn.rebuilt && turn.t >= turn.rbFrom) {
            if (turn.switchState === "running") {
                anim.pause();
                turn.t = turn.rbFrom;
                turn.waited = true;
                turn.waiting(true);
                return;
            }
            turn.rebuilt = true;
            turn.rebuild();
        }
    }
    property bool rebuilt: false
    property bool waited: false
    property var panes: []
    readonly property var self: turn

    function register(pane: var, on: bool): void {
        turn.panes = on ? turn.panes.concat([pane]) : turn.panes.filter(p => p !== pane);
        if (on && pane.role === "main")
            turn.mainPane = pane;
        else if (!on && turn.mainPane === pane)
            turn.mainPane = turn.panes.find(p => p.role === "main") || null;
    }

    readonly property string switchCmd: Quickshell.env("GLASSHOUSE_SWITCH") || "~/.local/bin/theme-switch.sh toggle"
    readonly property string switchLog: Settings.dir + "/turn-switch.log"

    function runSwitch(): void {
        turn.switchState = "running";
        switcher.running = true;
        watchdog.restart();
    }

    function settle(good: bool): void {
        if (turn.switchState !== "running")
            return;
        turn.ok = good;
        turn.switchState = turn.ok ? "done" : "failed";
        if (turn.turned && !turn.ok)
            World.pin = turn.leave;
        turn.switched(turn.ok);
        if (turn.waited && turn.phase === "run") {
            turn.waited = false;
            turn.waiting(false);
            turn.rebuilt = true;
            turn.rebuild();
            anim.resume();
        }
    }

    Timer {
        id: watchdog
        interval: 30000
        onTriggered: {
            if (switcher.running)
                switcher.running = false;
            turn.settle(false);
        }
    }

    Process {
        id: switcher
        command: ["sh", "-c", "exec " + turn.switchCmd + ' >"$1" 2>&1', "sh", turn.switchLog]
        environment: ({ GLASSHOUSE_QUIET: "1" })
        onExited: (code, status) => {
            watchdog.stop();
            turn.settle(code === 0);
        }
    }

    property real prepAt: 0
    property bool clipAsked: false
    property real clipAt: 0
    property int openFrames: 0
    property int prepTicks: 0

    function start(): void {
        if (turn.phase !== "rest" || turn.panes.length === 0)
            return;
        warmer.stop();
        turn.warming = false;
        turn.warmDir = "";
        turn.warmAt = -1;
        turn.runDir = World.name === "light" ? "dusk" : "dawn";
        turn.ok = false;
        turn.switchState = "idle";
        turn.contactT = -1;
        turn.fired = false;
        turn.rebuilt = false;
        turn.waited = false;
        turn.heldFirst = false;
        turn.heldLast = false;
        turn.t = 0;
        turn.running = false;
        turn.clap.reset();
        turn.slowFrames = [];
        turn.turned = false;
        World.pin = World.name;
        if (typeof Inbox !== "undefined")
            Inbox.hold = true;
        turn.prepAt = Date.now();
        turn.prepTicks = 0;
        turn.clipAsked = false;
        turn.phase = "prep";
        for (const p of turn.panes)
            p.prepare();
        stepper.restart();
    }

    Timer {
        id: stepper
        interval: 16
        repeat: true
        onTriggered: {
            const late = Date.now() - turn.prepAt > 900;
            if (turn.phase !== "prep") {
                stop();
                return;
            }
            if (!turn.open) {
                if (++turn.prepTicks < 5 || (!late && turn.panes.some(p => !p.prepared)))
                    return;
                for (const p of turn.panes)
                    p.snapMask();
                turn.open = true;
                turn.openFrames = 0;
                return;
            }
            if (!turn.turned && turn.openFrames >= 1) {
                turn.turned = true;
                World.pin = turn.arrive;
            }
            if (turn.panes.some(p => !(p.shown && p.reveal)) && !late)
                return;
            if (++turn.openFrames < 3)
                return;
            if (!turn.clipAsked) {
                turn.clipAsked = true;
                turn.clipAt = Date.now();
                for (const p of turn.panes)
                    p.loadClip();
                if (turn.panes.some(p => !p.clipReady))
                    return;
            }
            if (turn.panes.some(p => !p.clipReady) && Date.now() - turn.clipAt < 3000)
                return;
            if (turn.holdFirst) {
                turn.heldFirst = true;
                return;
            }
            turn.heldFirst = false;
            stop();
            turn.run();
        }
    }

    function run(): void {
        turn.phase = "run";
        turn.t = turn.startT;
        turn.running = true;
        anim.duration = (turn.endT - turn.startT) * 1000 * turn.slow;
        anim.restart();
        turn.begin(turn.dir);
    }

    function finish(): void {
        if (turn.holdLast) {
            turn.heldLast = true;
            return;
        }
        turn.handOver();
    }

    function handOver(): void {
        turn.heldLast = false;
        turn.phase = "end";
        turn.running = false;
        turn.open = false;
        World.pin = "auto";
        if (typeof Inbox !== "undefined")
            Inbox.hold = false;
        const good = turn.switchState === "done";
        if (!good) {
            Her.react("error", 8000);
            Bus.say({ title: "the Turn failed", body: turn.switchState === "failed" ? turn.switchLog : "the switch did not run", kind: "error" });
        }
        turn.phase = "rest";
        turn.ended(good);
        cleanup.restart();
    }

    Timer {
        id: cleanup
        interval: 600
        onTriggered: {
            for (const p of turn.panes)
                p.release();
        }
    }

    readonly property var warmSteps: [0.1, 0.5, 0.97, 1.3, 1.6, 1.96, 2.05, 2.21, 2.4, 2.6, 2.98, 3.3, 3.43, 3.52, 3.58, 3.62, 3.8, 4.2, 5.0, 8.75, 9.2, 9.6, 10.02, 10.2, 10.4, 10.7, 11.0]
    property int warmAt: -1

    function warmUp(): void {
        if (turn.phase !== "rest" || turn.panes.length === 0)
            return;
        turn.warming = true;
        turn.running = true;
        turn.warmAt = 0;
        turn.warmDir = turn.dir === "dawn" ? "dusk" : "dawn";
        warmer.restart();
    }
    Timer {
        id: warmer
        interval: 34
        repeat: true
        onTriggered: {
            const n = turn.warmSteps.length;
            const k = turn.warmAt++;
            if (k < 2 * n) {
                if (k === n)
                    turn.warmDir = turn.warmDir === "dawn" ? "dusk" : "dawn";
                turn.t = turn.warmSteps[k % n];
                return;
            }
            if (k === 2 * n) {
                turn.t = 0;
                turn.running = false;
                turn.warming = false;
                return;
            }
            if (k < 2 * n + 8) {
                turn.warmDir = k % 2 ? "dawn" : "dusk";
                return;
            }
            stop();
            turn.warmDir = "";
            turn.warmAt = -1;
        }
    }
    Timer {
        id: warmLater
        interval: Math.max(2500, 10000 - (Date.now() - Quickshell.launchTime.getTime()))
        running: true
        onTriggered: turn.warmUp()
    }

    FileView {
        id: soundFile
        path: Quickshell.shellPath("parts/Turn/Sound.qml")
        printErrors: false
    }
    LazyLoader {
        active: soundFile.loaded
        source: Qt.resolvedUrl("Sound.qml")
        onItemChanged: if (item) item.turn = turn
    }

    Variants {
        model: Screens.list
        Scene {
            required property ShellScreen modelData
            screen: modelData
            turn: self
        }
    }

    Connections {
        target: Bus
        function onTurn(): void {
            turn.start();
        }
    }

    function install(): void {
        Hypr.dispatch("function() hl.layer_rule({ name = \"glasshouse-turn\", match = { namespace = \"glasshouse-turn\" }, no_anim = true }) end");
    }
    Connections {
        target: Hyprland
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded")
                turn.install();
        }
    }
    Component.onCompleted: turn.install()

    GlobalShortcut {
        appid: Test.on ? "glasshouse-test" : "glasshouse"
        name: "turn"
        description: "The Turn"
        onPressed: turn.start()
    }

    Remote {
        turn: self
    }
}
