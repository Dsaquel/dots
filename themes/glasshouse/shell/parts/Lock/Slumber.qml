pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.core
import qs.parts.Chat

Singleton {
    id: s

    property bool engaged: false
    property bool real: false
    property bool shown: false
    property double began: 0
    property string pinBefore: ""

    property double now: Date.now()
    property double busyUntil: 0
    readonly property bool fast: s.now < s.busyUntil || s.checking
    readonly property bool living: s.engaged && s.shown && s.asleep && !s.deep
    readonly property real t: (s.now - s.began) / 1000
    property real life: 0

    property double introAt: -1
    property double asleepAt: -1
    readonly property bool asleep: s.asleepAt > 0
    property bool awake: false
    readonly property bool deep: s.engaged && s.shown && s.idleShort && !s.raised

    property bool raised: false
    property double raisedAt: -1
    property double loweredAt: -1
    property var chars: []
    property string buffer: ""
    property string pending: ""
    property bool checking: false
    property double checkAt: -1
    property double wrongAt: -1
    property int tries: 0
    property double acceptAt: -1
    property string notice: ""
    property double lastKeyAt: 0
    readonly property int count: s.chars.filter(c => c.gone < 0).length

    property bool releasing: false
    property bool shattering: false
    property double handAt: -1
    property int ready: 0
    property int needed: 1
    property bool shardsDone: false
    property int handMs: 0
    property bool wakeDone: false

    property int dimS: 300
    property int lockS: 3600
    readonly property string flag: Quickshell.env("GLASSHOUSE_LOCK_FLAG") || Quickshell.env("HOME") + "/.config/glasshouse/lock"
    readonly property bool idleShort: shortIdle.object ? shortIdle.object.isIdle : false
    readonly property bool idleLong: longIdle.object ? longIdle.object.isIdle : false
    readonly property bool dimmed: s.idleShort && !s.engaged
    property double dimAt: -1
    property real dimFrom: 0
    readonly property real dim: s.dimLevel(s.dimmed)
    function dimLevel(on: bool): real {
        if (s.dimAt < 0)
            return 0;
        return on ? s.dimFrom + (1 - s.dimFrom) * s.inOut3(s.span(s.dimAt, 0, 4.0)) : s.dimFrom * (1 - s.out3(s.span(s.dimAt, 0, 0.8)));
    }

    property bool fake: false
    property real holdShards: 0
    property string probeResult: ""

    property point fieldAt: Qt.point(1500, 640)
    property var layout: ({})
    readonly property bool hasMain: Screens.list.some(sc => Screens.role(sc.name) === "main")

    function clamp(v: real, a: real, b: real): real {
        return Math.max(a, Math.min(b, v));
    }
    function span(at: double, delay: real, dur: real): real {
        if (at < 0)
            return 0;
        return s.clamp((s.now - at - delay * 1000) / Math.max(1, dur * 1000), 0, 1);
    }
    function since(at: double): real {
        return at < 0 ? 1e9 : (s.now - at) / 1000;
    }
    function out3(x: real): real {
        const u = 1 - s.clamp(x, 0, 1);
        return 1 - u * u * u;
    }
    function inOut3(x: real): real {
        const v = s.clamp(x, 0, 1);
        if (v < 0.5)
            return 4 * v * v * v;
        const u = -2 * v + 2;
        return 1 - u * u * u / 2;
    }
    function busy(ms: int): void {
        s.now = Date.now();
        s.busyUntil = Math.max(s.busyUntil, s.now + ms);
    }

    function play(name: string, gain: real): void {
        if (!Sfx.enabled)
            return;
        const g = (gain === undefined || isNaN(gain) ? 1 : gain) * Settings.soundLevel;
        const file = name.startsWith("lock-") ? Quickshell.shellPath("assets/" + World.name + "/" + name + ".wav") : Quickshell.shellPath("sounds/" + World.name + "/" + name + ".wav");
        Quickshell.execDetached(Sfx.target ? ["pw-play", "--target", Sfx.target, "-P", "{ node.dont-fallback = true }", "--latency", "256", "--volume", g.toFixed(3), file] : ["pw-play", "--latency", "256", "--volume", g.toFixed(3), file]);
    }

    function reset(): void {
        s.awake = false;
        s.introAt = -1;
        s.asleepAt = -1;
        s.raised = false;
        s.raisedAt = -1;
        s.loweredAt = -1;
        s.chars = [];
        s.buffer = "";
        s.pending = "";
        s.checking = false;
        s.checkAt = -1;
        s.wrongAt = -1;
        s.tries = 0;
        s.acceptAt = -1;
        s.notice = "";
        s.releasing = false;
        s.shattering = false;
        s.handAt = -1;
        s.ready = 0;
        s.shardsDone = false;
        s.wakeDone = false;
    }

    function begin(isReal: bool, world: string): void {
        if (s.engaged)
            return;
        s.reset();
        s.pinBefore = "";
        if ((world === "dark" || world === "light") && world !== World.name) {
            s.pinBefore = World.pin;
            World.pin = world;
        }
        s.real = isReal && !Test.on;
        s.began = Date.now();
        s.lastKeyAt = s.began;
        s.engaged = true;
        s.shown = true;
        s.busy(4200);
        Inbox.hold = true;
        s.play("lock", 1);
        asleepGuard.interval = 8500;
        asleepGuard.restart();
        introGuard.restart();
    }

    function intro(): void {
        if (s.introAt > 0 || !s.engaged)
            return;
        s.introAt = Date.now();
        s.busy(4200);
        asleepGuard.interval = 6300;
        asleepGuard.restart();
    }

    function lockNow(): void {
        if (s.engaged && !s.real && !Test.on)
            s.abort();
        s.begin(!Test.on, "");
    }

    function fallAsleep(): void {
        if (s.asleepAt > 0)
            return;
        s.asleepAt = Date.now();
        s.busy(1500);
        wakeMaker.restart();
    }
    Timer {
        id: wakeMaker
        interval: 1500
        onTriggered: s.awake = s.engaged
    }

    function abort(): void {
        if (!s.engaged || s.real)
            return;
        verdictTimer.stop();
        guard.stop();
        endShards.stop();
        endWake.stop();
        s.shown = false;
        s.finish();
    }

    function lost(): void {
        console.warn("lock: the session lock ended without the password; the lock is reset");
        verdictTimer.stop();
        guard.stop();
        s.finish();
    }

    function wakeGone(): void {
        s.wakeDone = true;
        s.tryFinish();
    }
    function tryFinish(): void {
        if (s.shardsDone && (s.wakeDone || !s.hasMain))
            s.finish();
    }

    function finish(): void {
        endWake.stop();
        asleepGuard.stop();
        introGuard.stop();
        s.engaged = false;
        s.real = false;
        s.shown = false;
        s.releasing = false;
        s.shattering = false;
        s.buffer = "";
        s.pending = "";
        s.chars = [];
        Inbox.hold = false;
        if (s.pinBefore !== "") {
            World.pin = s.pinBefore;
            s.pinBefore = "";
        }
    }

    function raise(): void {
        if (s.raised)
            return;
        s.raised = true;
        s.raisedAt = Date.now();
        s.busy(900);
    }
    function lower(): void {
        if (!s.raised)
            return;
        s.drop();
        s.raised = false;
        s.loweredAt = Date.now();
        s.busy(700);
    }
    function drop(): void {
        const t0 = Date.now();
        s.chars = s.chars.filter(c => c.gone < 0 || t0 - c.gone < 400).map(c => c.gone < 0 ? { at: c.at, gone: t0, n: c.n } : c);
        s.buffer = "";
        s.busy(500);
    }

    function key(code: int, text: string, mods: int): void {
        if (!s.engaged || !s.shown || s.acceptAt > 0)
            return;
        s.lastKeyAt = Date.now();
        const fresh = !s.raised;
        s.raise();
        if (s.checking)
            return;
        const ctrl = (mods & Qt.ControlModifier) !== 0;
        if (code === Qt.Key_Return || code === Qt.Key_Enter) {
            s.submit();
            return;
        }
        if (code === Qt.Key_Escape) {
            if (s.count === 0 && !fresh && !s.real && !Test.on)
                s.abort();
            else
                s.drop();
            return;
        }
        if (code === Qt.Key_Backspace) {
            if (ctrl)
                s.drop();
            else
                s.erase();
            return;
        }
        if (ctrl && code === Qt.Key_U) {
            s.drop();
            return;
        }
        if (ctrl || !text || text.length === 0)
            return;
        const c0 = text.charCodeAt(0);
        if (c0 < 32 || c0 === 127)
            return;
        const t0 = Date.now();
        s.buffer += text;
        s.chars = s.chars.filter(c => c.gone < 0 || t0 - c.gone < 400).concat([{ at: t0, gone: -1, n: text.length }]);
        s.busy(600);
        s.play("lock-key-" + ((s.count - 1) % 5 + 1), 0.9);
    }

    function erase(): void {
        const live = s.chars.filter(c => c.gone < 0);
        if (live.length === 0)
            return;
        const last = live[live.length - 1];
        const t0 = Date.now();
        s.buffer = s.buffer.slice(0, Math.max(0, s.buffer.length - last.n));
        s.chars = s.chars.map(c => c === last ? { at: c.at, gone: t0, n: c.n } : c);
        s.busy(400);
    }

    function submit(): void {
        if (s.checking || s.buffer.length === 0)
            return;
        s.checking = true;
        s.checkAt = Date.now();
        s.notice = "";
        s.busy(500);
        if (Test.on) {
            s.buffer = "";
            verdictTimer.interval = s.fake ? 420 : 1600;
            verdictTimer.restart();
            return;
        }
        s.pending = s.buffer;
        s.buffer = "";
        if (!pam.start())
            s.verdict(false, "PAM did not start");
    }

    function verdict(ok: bool, why: string): void {
        if (!s.checking)
            return;
        s.checking = false;
        s.pending = "";
        if (ok) {
            s.accept();
            return;
        }
        s.tries++;
        s.wrongAt = Date.now();
        s.busy(2400);
        s.chars = s.chars.map(c => c.gone < 0 ? { at: c.at, gone: s.wrongAt, n: c.n } : c);
        s.notice = why === "" || why === "Failed" ? "" : why;
        if (s.notice !== "")
            noticeTimer.restart();
        s.play("lock-crack", 1);
    }

    function accept(): void {
        s.acceptAt = Date.now();
        s.busy(4000);
        s.play("unlock", 1);
        s.ready = 0;
        s.needed = Screens.list.length + (s.hasMain ? 1 : 0);
        s.releasing = true;
        s.shattering = true;
        guard.restart();
    }
    function readyOne(): void {
        s.ready++;
        if (s.ready >= s.needed)
            handTimer.restart();
    }
    function handover(): void {
        if (s.handAt > 0 || !s.engaged)
            return;
        guard.stop();
        handTimer.stop();
        s.shown = false;
        s.handAt = Date.now();
        s.handMs = s.handAt - s.acceptAt;
        s.busy(2200 + Math.round(s.holdShards * 1000));
        s.play("lock-break", 0.9);
        endShards.interval = 1800 + Math.round(s.holdShards * 1000);
        endShards.restart();
        endWake.restart();
    }

    Timer {
        interval: 16
        repeat: true
        running: s.fast
        onTriggered: {
            s.now = Date.now();
            if (s.living)
                s.life = (s.now - s.began) / 1000;
        }
    }
    Timer {
        interval: 67
        repeat: true
        running: s.living && !s.fast
        onTriggered: s.life = (Date.now() - s.began) / 1000
    }
    Timer {
        id: noticeTimer
        interval: 6000
        onTriggered: s.notice = ""
    }
    Timer {
        id: verdictTimer
        onTriggered: {
            const ok = s.fake;
            s.fake = false;
            s.verdict(ok, ok ? "" : "Failed");
        }
    }
    Timer {
        id: guard
        interval: 800
        onTriggered: s.handover()
    }
    Timer {
        id: handTimer
        interval: 34
        onTriggered: s.handover()
    }
    Timer {
        id: endShards
        interval: 1800
        onTriggered: {
            s.shattering = false;
            s.shardsDone = true;
            Inbox.hold = false;
            s.tryFinish();
        }
    }
    Timer {
        id: endWake
        interval: 8000
        onTriggered: s.finish()
    }
    Timer {
        id: introGuard
        interval: 1600
        onTriggered: s.intro()
    }
    Timer {
        id: asleepGuard
        interval: 8500
        onTriggered: if (s.engaged)
            s.fallAsleep()
    }
    Timer {
        interval: 1000
        repeat: true
        running: s.engaged && s.shown && s.raised && !s.checking
        onTriggered: {
            const idle = (Date.now() - s.lastKeyAt) / 1000;
            if ((s.count === 0 && idle > 12) || idle > 30)
                s.lower();
        }
    }

    onDimmedChanged: {
        s.now = Date.now();
        const was = s.dimLevel(!s.dimmed);
        s.dimFrom = was;
        s.dimAt = s.now;
        s.busy(s.dimmed ? 4100 : 900);
    }

    Binding {
        target: Her
        property: "idle"
        value: s.engaged || s.dimmed
    }

    // Quickshell 0.3.1 arms an IdleMonitor's timeout once: a new timeout = a new monitor
    Instantiator {
        id: shortIdle
        model: [s.dimS]
        delegate: IdleMonitor {
            required property int modelData
            timeout: modelData
            respectInhibitors: true
        }
    }
    Instantiator {
        id: longIdle
        model: [s.lockS]
        delegate: IdleMonitor {
            required property int modelData
            timeout: modelData
            respectInhibitors: true
        }
    }
    onIdleLongChanged: {
        if (s.idleLong && !s.real)
            flagCheck.running = true;
    }
    Process {
        id: flagCheck
        command: ["test", "-f", s.flag]
        onExited: code => {
            if (code === 0 && s.idleLong && !s.real)
                s.lockNow();
        }
    }

    PamContext {
        id: pam
        configDirectory: s.probing ? Quickshell.shellPath("parts/Lock/pam") : "/etc/pam.d"
        config: s.probing ? "password.conf" : "login"
        onPamMessage: {
            if (pam.responseRequired) {
                pam.respond(s.probing ? "glasshouse-probe-never-a-password" : s.pending);
                s.pending = "";
            } else if (pam.messageIsError) {
                s.notice = pam.message;
            }
        }
        onCompleted: result => {
            if (s.probing) {
                s.probing = false;
                s.probeResult = PamResult.toString(result);
                console.log("lock: PAM probe ->", s.probeResult);
                return;
            }
            s.verdict(result === PamResult.Success, PamResult.toString(result));
        }
        onError: error => {
            if (s.probing) {
                s.probing = false;
                s.probeResult = "error " + PamError.toString(error);
                console.log("lock: PAM probe ->", s.probeResult);
                return;
            }
            s.verdict(false, PamError.toString(error));
        }
    }
    property bool probing: false
    function probe(): string {
        if (!Test.on || s.checking || s.probing)
            return "busy";
        s.probing = true;
        s.probeResult = "";
        if (pam.start())
            return "started";
        s.probing = false;
        return "PAM did not start";
    }
}
