import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.core
import qs.parts.Chat

Scope {
    id: ledger

    readonly property string scene: Quickshell.env("GLASSHOUSE_LEDGER") || Assets.root + "/ledger/scene"
    readonly property string her: Quickshell.env("GLASSHOUSE_LEDGER_HER") || Assets.root + "/ledger/her"
    readonly property string film: Quickshell.env("GLASSHOUSE_LEDGER_FILM") || Assets.root + "/clips/ledger-fpv-dark.mp4"
    readonly property string cls: "ledgerscene"
    readonly property string log: Settings.dir + "/ledger.log"
    readonly property ShellScreen pick: Screens.list.find(s => Screens.role(s.name) === "main") || Screens.list.find(s => s.name === Hypr.focusedMonitor) || Screens.list[0] || null
    readonly property string appid: Test.on ? "glasshouse-test" : "glasshouse"

    readonly property int fadeMs: 450
    readonly property int handMs: ledger.dark ? 250 : 600
    readonly property int closeMs: 450
    readonly property int readyMs: ledger.dark ? 15000 : 8000
    readonly property var limits: ({ check: 3000, fade: 4000, hand: 3000, leave: 3500, close: 5000 })
    readonly property string room: "name:ledger"

    property string phase: "rest"
    property ShellScreen at: null
    property bool dark: true
    property bool herData: false
    property bool heard: false
    property bool closing: false
    property bool stopping: false
    property bool seen: false
    property bool capturing: false
    property string fault: ""
    property int origin: -1
    property bool moved: false
    property var marks: ({})
    readonly property var self: ledger
    readonly property MediaPlayer backend: MediaPlayer {}
    readonly property string main: ledger.at ? ledger.at.name : ""
    readonly property bool alive: godot.running
    readonly property int pid: godot.processId || 0
    readonly property var win: ledger.pid > 0 ? Hypr.windows.find(w => w.pid === ledger.pid) || null : null
    readonly property bool ready: ledger.heard && ledger.win !== null
    readonly property bool focused: !!ledger.win && !!Hyprland.activeToplevel && Hypr.clean(Hyprland.activeToplevel.address) === ledger.win.address && Hypr.focusedMonitor === ledger.main && Hypr.activeWs(ledger.main) === ledger.win.ws
    readonly property bool shown: ["rest", "check"].indexOf(ledger.phase) < 0 && (ledger.phase !== "open" || !ledger.win || Hypr.activeWs(ledger.main) === ledger.win.ws)

    function mark(name: string): void {
        const m = Object.assign({}, ledger.marks);
        m[name] = Date.now() - (ledger.marks.key || Date.now());
        ledger.marks = m;
    }

    function say(title: string, body: string): void {
        Bus.say({ key: "ledger", title: title, body: body, kind: "error" });
    }

    function install(): void {
        Hypr.dispatch("function() hl.workspace_rule({ workspace = \"" + ledger.room + "\", monitor = \"" + ledger.main + "\" }); hl.window_rule({ name = \"glasshouse-ledger-screen\", match = { class = \"^(" + ledger.cls + ")$\" }, monitor = \"" + ledger.main + "\", workspace = \"" + ledger.room + "\" }) end");
    }

    function hush(): void {
        Hypr.dispatch("function() local on = hl.get_config(\"plugin:vitrail:enfilade\"); if on ~= nil and glasshouse_ledger_enfilade == nil then glasshouse_ledger_enfilade = on; hl.config({ plugin = { vitrail = { enfilade = false } } }) end end");
        unhush.restart();
    }

    function cover(): void {
        if (ledger.moved)
            return;
        ledger.origin = Hypr.activeWs(ledger.main);
        ledger.moved = true;
        ledger.hush();
        Hypr.dispatch("hl.dsp.focus({ workspace = \"" + ledger.room + "\" })");
    }

    function back(): void {
        if (!ledger.moved)
            return;
        ledger.moved = false;
        if (Hypr.activeWs(ledger.main) === ledger.origin)
            return;
        ledger.hush();
        Hypr.focusWorkspace(ledger.origin);
    }

    function open(): void {
        if (ledger.phase === "open")
            return ledger.focused ? ledger.close() : ledger.focus();
        if (ledger.phase !== "rest")
            return;
        if (!ledger.pick)
            return ledger.say("the Ledger did not open", "there is no screen to open it on");
        ledger.marks = { key: Date.now() };
        ledger.at = ledger.pick;
        ledger.dark = World.dark;
        ledger.fault = "";
        ledger.capturing = false;
        ledger.phase = "check";
        checker.running = true;
    }

    function begin(lines: var): void {
        if (ledger.phase !== "check")
            return;
        const missing = lines.filter(l => l !== "her");
        if (missing.length > 0) {
            ledger.rest();
            ledger.say("the Ledger is missing", missing.join("\n"));
            return;
        }
        ledger.herData = lines.indexOf("her") >= 0;
        ledger.heard = false;
        ledger.closing = false;
        ledger.stopping = false;
        ledger.seen = false;
        ledger.install();
        Inbox.hold = true;
        ledger.phase = "fade";
    }

    function fading(): void {
        ledger.mark("fading");
        if (!ledger.dark)
            spawner.restart();
    }

    function spawn(): void {
        if (godot.running || ["fade", "film", "hold"].indexOf(ledger.phase) < 0)
            return;
        ledger.mark("spawn");
        godot.running = true;
        watchdog.restart();
    }

    function faded(): void {
        if (ledger.phase !== "fade")
            return;
        ledger.mark("faded");
        ledger.phase = ledger.dark ? "film" : "hold";
        if (!ledger.dark)
            ledger.spawn();
        ledger.proceed();
    }

    function ended(): void {
        if (ledger.phase !== "film")
            return;
        ledger.mark("ended");
        ledger.spawn();
        ledger.phase = "hold";
        ledger.proceed();
    }

    function proceed(): void {
        if (ledger.phase !== "hold" || !ledger.ready)
            return;
        watchdog.stop();
        ledger.mark("hand");
        ledger.phase = "hand";
        focuser.restart();
    }

    function focus(): void {
        if (ledger.win)
            Hypr.focusWindow(ledger.win.address);
    }

    function landed(): void {
        if (ledger.phase !== "hand")
            return;
        ledger.mark("open");
        ledger.phase = "open";
        ledger.focus();
        Inbox.hold = false;
        if (ledger.dark)
            godot.write("ledger:arrive\n");
        if (ledger.closing)
            ledger.close();
    }

    function close(): void {
        switch (ledger.phase) {
        case "check":
            ledger.rest();
            break;
        case "fade":
        case "film":
        case "hold":
            ledger.mark("close");
            ledger.phase = "close";
            ledger.away();
            break;
        case "hand":
            ledger.closing = true;
            break;
        case "open":
            ledger.mark("leave");
            ledger.phase = "leave";
            godot.write("ledger:leave\n");
            break;
        case "leave":
            ledger.left();
            break;
        }
    }

    function left(): void {
        if (ledger.phase !== "leave")
            return;
        ledger.mark("close");
        ledger.capturing = true;
        ledger.phase = "close";
    }

    function fail(why: string): void {
        if (ledger.fault === "")
            ledger.fault = why;
        ledger.close();
    }

    function away(): void {
        watchdog.stop();
        spawner.stop();
        ledger.mark("away");
        ledger.stopping = true;
        if (!godot.running)
            return;
        godot.signal(15);
        killer.restart();
    }

    function rest(): void {
        ledger.mark("rest");
        ledger.phase = "rest";
        ledger.at = null;
        ledger.capturing = false;
        Inbox.hold = false;
        ledger.back();
        if (ledger.fault !== "")
            ledger.say("the Ledger did not open", ledger.fault + "\n" + ledger.log);
    }

    function exited(code: int): void {
        ledger.mark("exited");
        killer.stop();
        if (["fade", "film", "hold"].indexOf(ledger.phase) >= 0)
            ledger.fail("the settings scene stopped (exit " + code + ")");
        else if (["hand", "open", "leave"].indexOf(ledger.phase) >= 0) {
            if (code !== 0 && !ledger.stopping)
                ledger.fault = "the settings scene stopped (exit " + code + ")";
            ledger.rest();
        }
    }

    function read(line: string): void {
        if (line === "ledger:ready" && !ledger.heard) {
            ledger.mark("ready");
            ledger.heard = true;
        } else if (line === "ledger:close") {
            ledger.close();
        } else if (line === "ledger:left") {
            ledger.left();
        }
    }

    onWinChanged: {
        if (ledger.win)
            ledger.seen = true;
        if (ledger.win && !ledger.win.fullscreen && ["fade", "film", "hold"].indexOf(ledger.phase) >= 0)
            Hypr.dispatch("hl.dsp.window.fullscreen({ action = \"set\", window = \"address:0x" + ledger.win.address + "\" })");
        if (!ledger.win && ledger.seen && godot.running && ["fade", "film", "hold", "open", "leave"].indexOf(ledger.phase) >= 0)
            gone.restart();
    }
    onReadyChanged: ledger.proceed()
    onAtChanged: if (!ledger.at && ledger.phase !== "rest") {
        ledger.fault = "its screen went away";
        ledger.away();
        ledger.rest();
    }

    Process {
        id: checker
        command: ["sh", "-c", 'command -v godot >/dev/null || echo godot; [ -f "$1/project.godot" ] || echo "$1"; [ -z "$2" ] || [ -f "$2" ] || echo "$2"; [ -f "$3/graph.json" ] && echo her; true', "sh", ledger.scene, ledger.dark ? ledger.film : "", ledger.her]
        stdout: StdioCollector {
            onStreamFinished: ledger.begin(text.split("\n").filter(l => l !== ""))
        }
    }

    Process {
        id: godot
        command: ["sh", "-c", 'log=$1; shift; exec setpriv --pdeathsig TERM -- "$@" 2>"$log"', "sh", ledger.log, "godot", "--path", ledger.scene, "--display-driver", "wayland"].concat(Sfx.enabled && !Sfx.target ? [] : ["--audio-driver", "Dummy"]).concat(["--", "--spread", ledger.dark ? "about" : "index", "--sound-level", Settings.soundLevel.toFixed(3)]).concat(ledger.dark ? ["--arrive", "index"] : []).concat(ledger.herData ? ["--her-data", ledger.her] : [])
        workingDirectory: ledger.scene
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => ledger.read(line)
        }
        onExited: (code, status) => ledger.exited(code)
    }

    Timer {
        interval: ledger.limits[ledger.phase] || 0
        running: interval > 0
        onTriggered: {
            if (ledger.phase === "hand")
                return ledger.landed();
            if (ledger.phase === "leave")
                return ledger.left();
            if (ledger.phase !== "close" && ledger.fault === "")
                ledger.fault = "the opening stalled (" + ledger.phase + ")";
            ledger.away();
            ledger.rest();
        }
    }
    Timer {
        id: watchdog
        interval: ledger.readyMs
        onTriggered: ledger.fail("the settings scene did not start in " + Math.round(ledger.readyMs / 1000) + " s")
    }
    Timer {
        id: spawner
        interval: ledger.fadeMs / 2
        onTriggered: ledger.spawn()
    }
    Timer {
        id: focuser
        interval: 60
        onTriggered: ledger.focus()
    }
    Timer {
        id: unhush
        interval: 400
        onTriggered: Hypr.dispatch("function() if glasshouse_ledger_enfilade ~= nil then hl.config({ plugin = { vitrail = { enfilade = glasshouse_ledger_enfilade } } }); glasshouse_ledger_enfilade = nil end end")
    }
    Timer {
        id: killer
        interval: 2000
        onTriggered: if (godot.running)
            godot.signal(9)
    }
    Timer {
        id: gone
        interval: 300
        onTriggered: {
            if (ledger.win || !godot.running)
                return;
            if (ledger.phase === "open" || ledger.phase === "leave")
                ledger.away();
            else if (["fade", "film", "hold"].indexOf(ledger.phase) >= 0)
                ledger.fail("the settings scene lost its window");
        }
    }

    LazyLoader {
        active: !!ledger.at && ["check", "fade", "film", "hold", "hand", "close"].indexOf(ledger.phase) >= 0
        Film {
            ledger: self
            capture: self.capturing
        }
    }

    component Veil: Scope {
        id: veil

        required property ShellScreen modelData
        property real k: ledger.shown ? 1 : 0
        Behavior on k {
            NumberAnimation {
                duration: ledger.fadeMs
                easing.type: Easing.InOutSine
            }
        }

        LazyLoader {
            active: veil.k > 0
            PanelWindow {
                screen: veil.modelData
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "glasshouse-ledger-veil"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"
                mask: Region {}

                Rectangle {
                    anchors.fill: parent
                    color: Theme.ground
                    opacity: 0.55 * veil.k
                }
            }
        }
    }

    Variants {
        model: Screens.list.filter(s => s.name !== (ledger.at ? ledger.at.name : ledger.pick ? ledger.pick.name : ""))
        Veil {}
    }

    Connections {
        target: Bus
        function onSettings(): void {
            ledger.open();
        }
    }

    GlobalShortcut {
        appid: ledger.appid
        name: "settings"
        description: "The Ledger: the settings"
        onPressed: ledger.open()
    }

    IpcHandler {
        target: "settings"
        function open(): void {
            ledger.open();
        }
        function close(): void {
            ledger.close();
        }
        function status(): string {
            return JSON.stringify({ phase: ledger.phase, screen: ledger.main, dark: ledger.dark, ready: ledger.ready, pid: ledger.pid, window: ledger.win ? ledger.win.address : "", origin: ledger.origin, moved: ledger.moved, fault: ledger.fault, marks: ledger.marks });
        }
    }

    Component.onDestruction: {
        if (godot.running)
            godot.signal(15);
        if (ledger.phase !== "rest")
            Inbox.hold = false;
    }
}
