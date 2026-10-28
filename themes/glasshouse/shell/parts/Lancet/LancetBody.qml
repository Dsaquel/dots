import QtQuick
import Quickshell
import qs.core

Item {
    id: body

    required property string output
    property bool interactive: true
    readonly property var geo: Anchor.of(body.output)
    readonly property var lay: body.geo ? body.geo.layout : null
    readonly property bool main: !!body.lay && body.lay.kind === "main"
    readonly property string kind: body.main ? "main" : "side"
    readonly property var workspaces: Screens.workspaces(body.output)
    readonly property int current: Hypr.activeWs(body.output)
    readonly property point light: Theme.dark ? Qt.point(0.9, 0.02) : Qt.point(0.15, 0.0)
    readonly property color gold: Theme.dark ? Theme.rare : Theme.sun
    readonly property var en: Qt.locale("en_GB")
    readonly property var shelf: Theme.dark ? [
            { key: "volume", sprite: "night-moon-flask", tint: "#cfd8ec" },
            { key: "mic", sprite: "night-tide-ampoule", tint: "#4fd0d8" },
            { key: "cpu", sprite: "night-mercury-alembic", tint: "#d6d3f2" },
            { key: "memory", sprite: "night-sea-jar", tint: "#5fc8d8" }
        ] : [
            { key: "volume", sprite: "day-sky-orb", tint: "#7fc6ff" },
            { key: "mic", sprite: "day-pearl-drop", tint: "#ffe3a0" },
            { key: "cpu", sprite: "day-sun-crystal", tint: "#ffa37a" },
            { key: "memory", sprite: "day-crown-bottle", tint: "#ffb347" }
        ]

    readonly property real unit: Screens.unitOf(body)
    width: body.lay ? body.lay.W : 0
    height: body.lay ? body.lay.H : 0

    property string hoverKey: ""
    property string osdKey: ""
    readonly property string activeKey: body.interactive ? (body.hoverKey || (Test.on ? Test.hover : "")) : ""
    readonly property var tip: body.interactive ? body.info(body.activeKey || body.osdKey) : null

    function osd(key: string): void {
        if (!body.interactive)
            return;
        body.osdKey = key;
        osdTimer.restart();
    }
    Timer {
        id: osdTimer
        interval: 1200
        onTriggered: body.osdKey = ""
    }

    readonly property real epoch: Date.now()
    property real t: 0
    property real until: 0
    readonly property bool covered: Hypr.on(body.output).some(w => w.fullscreen)
    readonly property bool oneShot: body.t < body.until
    readonly property bool continuous: rose.pulsing || (body.main && vials.busy)

    function now(): real {
        return (Date.now() - body.epoch) / 1000;
    }
    function kick(seconds: real): real {
        const n = body.now();
        body.t = n;
        body.until = Math.max(body.until, n + seconds);
        return n;
    }
    function ease(x: real): real {
        const c = Math.max(0, Math.min(1, x));
        return 1 - Math.pow(1 - c, 3);
    }
    Timer {
        interval: body.switching ? 16 : body.oneShot ? 50 : 100
        repeat: true
        running: body.visible && !body.covered && (body.oneShot || (body.continuous && !Gauges.idle))
        onTriggered: body.t = body.now()
    }

    property var glide: ({ volume: { from: 0, to: 0, at: -9 }, mic: { from: 0, to: 0, at: -9 }, cpu: { from: 0, to: 0, at: -9 }, memory: { from: 0, to: 0, at: -9 } })
    readonly property real volumeLevel: body.glided("volume")
    readonly property real micLevel: body.glided("mic")
    property var sloshAt: ({ volume: -9, mic: -9, memory: -9 })
    property real burstAt: -9
    property real burstStrength: 0.5
    property int samples: 0
    readonly property bool bursts: Quickshell.env("GLASSHOUSE_LANCET_BURST") !== "0"
    readonly property real cpuLevel: body.glided("cpu")
    readonly property real memoryLevel: body.glided("memory")

    function glided(key: string): real {
        const g = body.glide[key];
        return g.from + (g.to - g.from) * body.ease((body.t - g.at) / 0.8);
    }
    function glideTo(key: string, v: real, step: real): void {
        const cur = body.glided(key);
        if (Math.abs(cur - v) < step)
            return;
        const o = Object.assign({}, body.glide);
        o[key] = { from: cur, to: v, at: body.kick(0.85) };
        body.glide = o;
    }
    function slosh(key: string): void {
        const o = Object.assign({}, body.sloshAt);
        o[key] = body.kick(1.25);
        body.sloshAt = o;
    }
    function wave(key: string): real {
        const d = body.t - body.sloshAt[key];
        if (d < 0 || d > 1.2)
            return 0;
        return 0.028 * (d < 0.12 ? d / 0.12 : Math.pow(1 - (d - 0.12) / 1.08, 3));
    }
    function bubbles(): real {
        const d = body.t - body.burstAt;
        if (d < 0 || d > 0.88)
            return 0;
        return body.burstStrength * (d < 0.14 ? d / 0.14 : d < 0.55 ? 1 : 1 - (d - 0.55) / 0.33);
    }

    Connections {
        target: Gauges
        function onSampled(): void {
            if (!body.main)
                return;
            body.samples++;
            if (body.samples <= 2) {
                body.glideTo("cpu", Gauges.cpu, 0.004);
                return;
            }
            const every = Gauges.cpu < 0.15 ? 4 : Gauges.cpu < 0.4 ? 3 : Gauges.cpu < 0.7 ? 2 : 1;
            if (body.samples % every !== 0 || body.covered || Gauges.idle)
                return;
            if (body.bursts) {
                body.burstStrength = 0.3 + 0.7 * Gauges.cpu;
                body.burstAt = body.kick(0.9);
                body.glideTo("cpu", Gauges.cpu, 0.004);
            } else {
                body.glideTo("cpu", Gauges.cpu, 0.05);
            }
        }
        function onMemoryChanged(): void {
            if (body.main)
                body.glideTo("memory", Gauges.memory, 0.01);
        }
        function onVolumeTouched(): void {
            if (!body.main)
                return;
            body.glideTo("volume", Gauges.volume, 0.001);
            body.slosh("volume");
            body.osd("volume");
        }
        function onMicTouched(): void {
            if (!body.main)
                return;
            body.glideTo("mic", Gauges.micVolume, 0.001);
            body.slosh("mic");
            body.osd("mic");
        }
        function onVolumeChanged(): void {
            if (!Gauges.sinkPrimed)
                body.glideTo("volume", Gauges.volume, 0.001);
        }
        function onMicVolumeChanged(): void {
            if (!Gauges.sourcePrimed)
                body.glideTo("mic", Gauges.micVolume, 0.001);
        }
    }

    property real switchAt: -9
    property int previousWs: -1
    readonly property real sw: body.t - body.switchAt
    readonly property bool switching: body.sw >= 0 && body.sw < 0.45
    Connections {
        target: Hypr
        function onWorkspaceSwitched(monitor: string, from: int, to: int): void {
            if (monitor !== body.output || body.workspaces.indexOf(to) < 0)
                return;
            body.previousWs = from;
            body.switchAt = body.kick(0.45);
        }
    }

    Casement {
        host: body
    }

    Rose {
        id: rose
        kind: body.kind
        rose: body.lay ? body.lay.rose : ({ cx: 0, cy: 0, r: 44, heart: 13 })
        x: rose.rose.cx - width / 2
        y: rose.rose.cy - height / 2
        workspaces: body.workspaces
        current: body.current
        pulse: rose.pulsing ? 0.5 + 0.5 * Math.sin(body.t * 4.5) : 0
        t: body.t
        switchAt: body.switchAt
        previous: body.previousWs
        interactive: body.interactive
        hoverKey: body.activeKey
        onHovered: key => body.hoverKey = key
    }

    Hour {
        host: body
        stamp: clock.date
    }

    Repeater {
        model: body.main ? body.shelf : []
        Niche {
            host: body
        }
    }

    Vials {
        id: vials
        visible: body.main
        host: body
        interactive: body.interactive
        readonly property var n: body.main ? body.lay.vials : ({ x: 0, y: 0, w: 0, h: 0 })
        x: n.x
        y: n.y
        width: n.w
        height: n.h
    }

    MouseArea {
        id: roundelArea
        visible: body.main
        enabled: body.interactive
        readonly property var rd: body.main ? body.lay.roundel : ({ cx: 0, cy: 0, r: 0 })
        x: rd.cx - rd.r - 4
        y: rd.cy - rd.r - 4
        width: 2 * rd.r + 8
        height: width
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onEntered: body.hoverKey = "her"
        onExited: if (body.hoverKey === "her") body.hoverKey = ""
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Settings.dnd = !Settings.dnd;
            else
                Fold.set(body.kind, true);
        }
    }

    Bead {
        host: body
        roundelHovered: roundelArea.containsMouse
    }

    Handle {
        visible: !body.main && !!body.lay && !!body.lay.latch
        output: body.output
        interactive: false
        signals: false
        lit: body.activeKey === "fold"
        x: body.lay && body.lay.latch ? body.lay.latch.cx - width / 2 : 0
        y: body.lay && body.lay.latch ? body.lay.latch.cy - height / 2 : 0
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            enabled: body.interactive
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: body.hoverKey = "fold"
            onExited: if (body.hoverKey === "fold") body.hoverKey = ""
            onClicked: Fold.set(body.kind, true)
        }
    }

    Sigil {
        host: body
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Component.onCompleted: {
        const at = v => ({ from: v, to: v, at: -9 });
        body.glide = { volume: at(Gauges.volume), mic: at(Gauges.micVolume), cpu: at(Gauges.cpu), memory: at(Gauges.memory) };
    }

    function pct(v: real): string {
        return Math.round(v * 100) + " %";
    }
    function gib(kb: real): string {
        return (kb / 1048576).toFixed(1);
    }
    function isoWeek(d: var): int {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
        return Math.ceil(((t - Date.UTC(t.getUTCFullYear(), 0, 1)) / 86400000 + 1) / 7);
    }
    function iconsOf(id: int): var {
        const out = [];
        const seen = {};
        for (const w of Hypr.wsWindows(id)) {
            if (seen[w.cls])
                continue;
            seen[w.cls] = true;
            const p = Gauges.iconFor(w.cls);
            if (p)
                out.push(p);
            if (out.length >= 6)
                break;
        }
        return out;
    }
    function info(key: string): var {
        if (!key || !body.lay)
            return null;
        const L = body.lay;
        if (key === "time")
            return { key: key, y: L.time.y + L.time.h / 2, label: clock.date.toLocaleDateString(body.en, "dddd").toUpperCase(), value: clock.date.toLocaleDateString(body.en, "d MMMM"), detail: "week " + body.isoWeek(clock.date) };
        if (key === "rose") {
            if (Theme.dark)
                return { key: key, y: L.rose.cy, label: "MOON", value: body.pct(Gauges.moonLit), detail: Gauges.moonName };
            const n = new Date();
            const night = n < Gauges.sun.rise || n > Gauges.sun.set;
            const next = night ? (n > Gauges.sun.set ? new Date(Gauges.sun.rise.getTime() + 86400000) : Gauges.sun.rise) : Gauges.sun.set;
            const day = Math.round((Gauges.sun.set - Gauges.sun.rise) / 60000);
            return { key: key, y: L.rose.cy, label: night ? "SUNRISE" : "SUNSET", value: Qt.formatTime(next, "hh:mm"), detail: "daylight " + Math.floor(day / 60) + " h " + String(day % 60).padStart(2, "0") };
        }
        if (key.startsWith("ws")) {
            const id = Number(key.slice(2));
            const p = body.workspaces.indexOf(id) >= 0 ? rose.tipOf(key) : null;
            if (!p)
                return null;
            const icons = body.iconsOf(id);
            return { key: key, y: rose.y + p.y, label: "WORKSPACE", value: String(id), detail: icons.length ? "" : "empty", icons: icons };
        }
        if (key === "fold" && L.latch)
            return { key: key, y: L.latch.cy, label: "FOLD AWAY", value: "", detail: "" };
        if (!body.main)
            return null;
        const cy = i => L.niches[i].y + L.niches[i].h * 0.58;
        switch (key) {
        case "volume":
            return { key: key, y: cy(0), label: Gauges.muted ? "VOLUME  ·  MUTED" : "VOLUME", value: body.pct(Gauges.volume), detail: Gauges.sinkLabel, alert: Gauges.muted };
        case "mic":
            return { key: key, y: cy(1), label: Gauges.micMuted ? "MICROPHONE  ·  MUTED" : "MICROPHONE", value: body.pct(Gauges.micVolume), detail: Gauges.sourceLabel, alert: Gauges.micMuted };
        case "cpu":
            return { key: key, y: cy(2), label: "PROCESSOR", value: body.pct(Gauges.cpu), detail: "load " + Gauges.load + "   ·   " + Gauges.threads + " threads" };
        case "memory":
            return { key: key, y: cy(3), label: "MEMORY", value: body.pct(Gauges.memory), detail: body.gib(Gauges.memUsed) + " of " + body.gib(Gauges.memTotal) + " GiB" };
        case "her":
            if (Settings.dnd)
                return { key: key, y: L.roundel.cy, label: "DO NOT DISTURB", value: "", detail: "her bubbles wait silently in the thread  ·  click folds away" };
            return { key: key, y: L.roundel.cy, label: "FOLD AWAY", value: "", detail: "right click: do not disturb" };
        case "thread":
            if (Her.unread > 0)
                return { key: key, y: L.roundel.cy - (L.roundel.r - 3) * 0.7071, label: "UNREAD", value: String(Her.unread), detail: "click for her thread" };
            return { key: key, y: L.roundel.cy - (L.roundel.r - 3) * 0.7071, label: "HER THREAD", value: "", detail: "today's letters" };
        case "page":
            return { key: key, y: (L.roundel.cy + L.roundel.r + L.sill.y) / 2 + 2, label: "HER PAGE", value: "", detail: "her portrait, her mood" };
        case "agents+":
            return { key: key, y: L.vials.y + 30, label: "MORE SESSIONS", value: "+" + vials.extra, detail: Agents.live.slice(4).map(s => s.label).join("  ·  ") };
        }
        if (key.startsWith("agent:")) {
            const s = Agents.live.find(x => x.sid === key.slice(6));
            if (!s)
                return null;
            const st = { working: "WORKING", needs: "NEEDS YOU", done: "DONE", idle: "IDLE" }[s.state] || s.state.toUpperCase();
            const home = Quickshell.env("HOME") || "";
            const where = s.cwd ? (home && s.cwd.startsWith(home) ? "~" + s.cwd.slice(home.length) : s.cwd) : "";
            return { key: key, y: L.vials.y + L.vials.h * 0.55, label: st + "  ·  " + vials.elapsed(Agents.now - (s.since || s.updated)), value: s.label, word: true, detail: s.detail || where, alert: s.state === "needs" };
        }
        return null;
    }
}
