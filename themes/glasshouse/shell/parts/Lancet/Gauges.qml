pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs.core

Singleton {
    id: g

    readonly property var sink: Audio.sink
    readonly property var source: Audio.source
    readonly property bool sinkReady: Audio.sinkReady
    readonly property bool sourceReady: Audio.sourceReady
    readonly property real volume: Audio.volume
    readonly property bool muted: Audio.muted
    readonly property real micVolume: Audio.micVolume
    readonly property bool micMuted: Audio.micMuted
    readonly property string sinkLabel: Audio.sinkLabel
    readonly property string sourceLabel: Audio.sourceLabel
    readonly property bool sinkPrimed: Audio.sinkPrimed
    readonly property bool sourcePrimed: Audio.sourcePrimed

    signal volumeTouched()
    signal micTouched()

    function iconFor(cls: string): string {
        const e = DesktopEntries.heuristicLookup(cls);
        const named = n => n && (n.startsWith("/") || Quickshell.hasThemeIcon(n)) ? Quickshell.iconPath(n) : "";
        return (e ? named(e.icon) : "") || named((cls || "").toLowerCase()) || named("application-x-executable");
    }
    function setVolume(v: real): void {
        Audio.setVolume(v);
    }
    function toggleMute(): void {
        Audio.toggleMute();
    }
    function setMic(v: real): void {
        Audio.setMic(v);
    }
    function toggleMic(): void {
        Audio.toggleMic();
    }

    Connections {
        target: Audio
        function onVolumeTouched(): void {
            g.volumeTouched();
        }
        function onMicTouched(): void {
            g.micTouched();
        }
    }

    property real cpu: 0
    property int threads: 0
    property var prevStat: null
    property string load: ""
    property real memTotal: 0
    property real memUsed: 0
    readonly property real memory: g.memTotal > 0 ? g.memUsed / g.memTotal : 0

    signal sampled()

    function readStat(text: string): void {
        const lines = text.split("\n");
        const f = lines[0].trim().split(/\s+/).slice(1, 9).map(Number);
        if (f.length < 4)
            return;
        const idle = f[3] + (f[4] || 0);
        const total = f.reduce((a, b) => a + b, 0);
        if (g.prevStat && total > g.prevStat.total)
            g.cpu = Math.max(0, Math.min(1, 1 - (idle - g.prevStat.idle) / (total - g.prevStat.total)));
        g.prevStat = { total: total, idle: idle };
        g.threads = lines.filter(l => /^cpu\d/.test(l)).length;
        g.sampled();
    }
    function readMem(text: string): void {
        const kb = key => {
            const m = text.match(new RegExp("^" + key + ":\\s+(\\d+)", "m"));
            return m ? Number(m[1]) : 0;
        };
        const total = kb("MemTotal");
        const used = Math.max(0, total - kb("MemAvailable"));
        if (total !== g.memTotal)
            g.memTotal = total;
        if (Math.abs(used - g.memUsed) > total * 0.001)
            g.memUsed = used;
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: g.readStat(text())
    }
    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: g.readMem(text())
    }
    FileView {
        id: loadavg
        path: "/proc/loadavg"
        onLoaded: g.load = text().split(" ").slice(0, 3).join("  ")
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            loadavg.reload();
        }
    }

    readonly property real moonPhase: g.lunarPhase(hour.date)
    readonly property real moonLit: (1 - Math.cos(2 * Math.PI * g.moonPhase)) / 2
    readonly property string moonName: ["new moon", "waxing crescent", "first quarter", "waxing gibbous", "full moon", "waning gibbous", "last quarter", "waning crescent"][Math.round(g.moonPhase * 8) % 8]
    readonly property var latlon: (Quickshell.env("GLASSHOUSE_LATLON") || "").split(",").map(Number)
    readonly property var sun: g.latlon.length === 2 && g.latlon.every(Number.isFinite) ? g.sunTimes(hour.date, g.latlon[0], g.latlon[1]) : g.fixedSun(hour.date)

    function lunarPhase(date: var): real {
        const rad = Math.PI / 180;
        const T = (date.getTime() / 86400000 + 2440587.5 - 2451545.0) / 36525;
        const n = x => ((x % 360) + 360) % 360;
        const D = n(297.8501921 + 445267.1114034 * T);
        const M = n(357.5291092 + 35999.0502909 * T);
        const Mp = n(134.9633964 + 477198.8675055 * T);
        const e = D + 6.289 * Math.sin(Mp * rad) - 2.100 * Math.sin(M * rad) + 1.274 * Math.sin((2 * D - Mp) * rad) + 0.658 * Math.sin(2 * D * rad) + 0.214 * Math.sin(2 * Mp * rad) + 0.110 * Math.sin(D * rad);
        return n(e) / 360;
    }
    function fixedSun(date: var): var {
        return { rise: new Date(date.getFullYear(), date.getMonth(), date.getDate(), 7), set: new Date(date.getFullYear(), date.getMonth(), date.getDate(), 19) };
    }
    function sunTimes(date: var, lat: real, lon: real): var {
        const rad = Math.PI / 180;
        const noon = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 12);
        const nDay = Math.round(noon.getTime() / 86400000 + 2440587.5 - 2451545.0 + 0.0008);
        const Js = nDay - lon / 360;
        const M = ((357.5291 + 0.98560028 * Js) % 360 + 360) % 360;
        const C = 1.9148 * Math.sin(M * rad) + 0.02 * Math.sin(2 * M * rad) + 0.0003 * Math.sin(3 * M * rad);
        const lam = (M + C + 180 + 102.9372) % 360;
        const Jt = 2451545.0 + Js + 0.0053 * Math.sin(M * rad) - 0.0069 * Math.sin(2 * lam * rad);
        const dec = Math.asin(Math.sin(lam * rad) * Math.sin(23.44 * rad));
        const cw = (Math.sin(-0.833 * rad) - Math.sin(lat * rad) * Math.sin(dec)) / (Math.cos(lat * rad) * Math.cos(dec));
        const w = Math.acos(Math.max(-1, Math.min(1, cw))) / rad;
        const at = j => new Date((j - 2440587.5) * 86400000);
        return { rise: at(Jt - w / 360), set: at(Jt + w / 360) };
    }

    SystemClock {
        id: hour
        precision: SystemClock.Hours
    }

    readonly property bool idle: idleMon.isIdle

    IdleMonitor {
        id: idleMon
        timeout: 300
        respectInhibitors: true
    }

    function terminalOf(session: var): var {
        if (!session)
            return null;
        const home = Quickshell.env("HOME") || "";
        const label = (session.label || "").toLowerCase();
        const cwd = (session.cwd || "").toLowerCase();
        const tilde = cwd && home && cwd.startsWith(home.toLowerCase()) ? "~" + cwd.slice(home.length) : "";
        const titled = w => {
            const t = (w.title || "").toLowerCase();
            return (label && t.indexOf(label) >= 0) || (tilde && t.indexOf(tilde) >= 0) || (cwd && t.indexOf(cwd) >= 0);
        };
        let pool = session.pid > 0 ? Hypr.windows.filter(w => w.pid === session.pid) : [];
        let how = "pid";
        if (pool.length > 1 && pool.some(titled)) {
            pool = pool.filter(titled);
            how = "pid+title";
        }
        if (!pool.length) {
            pool = Hypr.windows.filter(w => /kitty/i.test(w.cls) && titled(w));
            how = "title";
        }
        if (!pool.length)
            return null;
        const w = pool.slice().sort((x, y) => x.history - y.history)[0];
        return { address: w.address, cls: w.cls, title: w.title, ws: w.ws, monitor: w.monitor, how: how };
    }

    GlobalShortcut {
        appid: Test.on ? "glasshouse-test" : "glasshouse"
        name: "lancet"
        description: "The lancet of the focused output folds or unfolds"
        onPressed: Fold.toggle("focused")
    }

    IpcHandler {
        target: "lancet"

        function terminal(sid: string): string {
            return JSON.stringify(g.terminalOf(Agents.sessions.find(s => s.sid === sid) || null));
        }
        function icon(cls: string): string {
            return g.iconFor(cls);
        }
        function dnd(on: bool): void {
            Settings.dnd = on;
        }
        function fold(which: string): void {
            Fold.set(which, true);
        }
        function unfold(which: string): void {
            Fold.set(which, false);
        }
        function toggle(which: string): void {
            Fold.toggle(which);
        }
        function status(): string {
            return Fold.status();
        }
        function state(): string {
            return JSON.stringify({
                sink: g.sink ? g.sink.name : null,
                volume: g.volume,
                muted: g.muted,
                source: g.source ? g.source.name : null,
                sourceInfo: g.source ? { audio: !!g.source.audio, ready: g.source.ready, type: PwNodeType.toString(g.source.type), isSink: g.source.isSink } : null,
                mic: g.micVolume,
                micMuted: g.micMuted,
                cpu: g.cpu,
                threads: g.threads,
                load: g.load,
                memory: g.memory,
                memUsedGiB: g.memUsed / 1048576,
                moon: { phase: g.moonPhase, lit: g.moonLit, name: g.moonName },
                sun: { rise: g.sun.rise.toString(), set: g.sun.set.toString() },
                idle: g.idle,
                agents: Agents.live.map(s => [s.sid, s.state, s.label])
            });
        }
    }
}
