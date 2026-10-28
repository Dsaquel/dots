pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: h

    property var windows: []
    property var byAddress: ({})
    property var monitors: ({})
    property var urgent: ({})
    readonly property string active: Test.on && Test.focus !== "" ? Test.focus : (Hyprland.activeToplevel ? h.clean(Hyprland.activeToplevel.address) : h.lastFocused)
    property string lastFocused: ""
    readonly property string focusedMonitor: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    property bool primed: false
    property int phase: 0
    property var steps: []
    property var again: []
    property int burstLeft: 0
    property string lastSig: ""
    property string lastActive: ""
    property real guessAt: 0
    property var pending: ({})
    property bool vitrail: false
    property int vitrailHeard: 0

    signal opening(string address, string workspace, string cls)
    signal opened(var win)
    signal closed(var win)
    signal focusMoved(string from, string to)
    signal workspaceSwitched(string monitor, int from, int to)

    function clean(a: string): string {
        return (a || "").replace(/^0x/, "");
    }

    function find(address: string): var {
        return h.byAddress[h.clean(address)] || null;
    }

    function on(monitor: string): var {
        const m = h.monitors[monitor];
        if (!m)
            return [];
        return h.windows.filter(w => w.monitor === monitor && (w.ws === m.ws || (w.special && w.wsName === m.special))).map(w => Object.assign({}, w, { lx: w.x - m.x, ly: w.y - m.y }));
    }

    function activeWs(monitor: string): int {
        const m = h.monitors[monitor];
        return m ? m.ws : -1;
    }

    function home(ws: int, monitor: string): string {
        if (monitor !== "")
            return monitor;
        const w = h.windows.find(x => x.ws === ws);
        return w ? w.monitor : Screens.owner(ws);
    }

    function guess(m: var): void {
        const mons = Object.assign({}, h.monitors);
        const p = Object.assign({}, h.pending);
        p[m.name] = { to: { ws: m.ws, special: m.special }, at: Date.now() };
        h.pending = p;
        mons[m.name] = m;
        h.monitors = mons;
        h.guessAt = Date.now();
        confirm.restart();
    }

    function shown(ws: int, monitor: string): void {
        const name = h.home(ws, monitor);
        const m = h.monitors[name];
        if (!h.primed || !m || !(ws > 0) || m.ws === ws)
            return;
        h.guess(Object.assign({}, m, { ws: ws }));
        h.workspaceSwitched(name, m.ws, ws);
    }

    function scratch(monitor: string, name: string): void {
        const m = h.monitors[monitor];
        if (!h.primed || !m || m.special === name)
            return;
        h.guess(Object.assign({}, m, { special: name }));
    }

    function wsCount(id: int): int {
        return h.windows.filter(w => w.ws === id).length;
    }

    function wsUrgent(id: int): bool {
        return !!h.urgent[id];
    }

    function wsWindows(id: int): var {
        return h.windows.filter(w => w.ws === id);
    }

    function dispatch(lua: string): void {
        Hyprland.dispatch(lua);
    }

    function focusWorkspace(id: int): void {
        h.dispatch("hl.dsp.focus({ workspace = " + id + " })");
    }

    function focusWindow(address: string): void {
        h.dispatch("hl.dsp.focus({ window = \"address:0x" + h.clean(address) + "\" })");
    }

    // Quickshell 0.3.1 drops monitors when the three refreshes are sent at once: send them in turn,
    // 12 ms apart ("m" monitors, "w" workspaces, "t" toplevels); the first one at once once primed (at
    // start it can meet a refresh Quickshell sends on its own and the monitors are lost)
    function run(steps: var): void {
        if (seq.running) {
            h.again = h.again.concat(steps.filter(s => h.again.indexOf(s) < 0));
            return;
        }
        h.steps = steps;
        h.phase = 0;
        if (h.primed)
            h.step();
        seq.start();
    }

    function step(): void {
        switch (h.steps[h.phase++]) {
        case "m":
            Hyprland.refreshMonitors();
            break;
        case "w":
            Hyprland.refreshWorkspaces();
            break;
        case "t":
            Hyprland.refreshToplevels();
            break;
        default:
            seq.stop();
            if (h.steps.indexOf("w") >= 0)
                debounce.restart();
            if (h.again.length > 0) {
                const next = h.again;
                h.again = [];
                h.run(next);
            }
        }
    }

    function askPlugins(): void {
        plugins.running = false;
        plugins.heard = h.vitrailHeard;
        plugins.running = true;
    }

    function refresh(): void {
        h.run(["m", "w", "t"]);
    }

    function glance(): void {
        h.run(["m", "t"]);
    }

    function settle(steps: var): void {
        h.run(steps || ["m", "w", "t"]);
        h.burstLeft = 6;
        burst.restart();
        late.restart();
    }

    function touch(): void {
        h.run(["t"]);
        if (h.burstLeft < 3)
            h.burstLeft = 3;
        burst.restart();
    }

    function rebuild(): void {
        const mons = {};
        const idToName = {};
        for (const m of Hyprland.monitors.values) {
            const o = m.lastIpcObject || {};
            idToName[m.id] = m.name;
            mons[m.name] = {
                id: m.id,
                name: m.name,
                x: m.x,
                y: m.y,
                w: m.width,
                h: m.height,
                ws: o.activeWorkspace ? o.activeWorkspace.id : -1,
                special: o.specialWorkspace ? o.specialWorkspace.name : "",
                focused: m.focused,
                rate: o.refreshRate || 60
            };
        }
        const p = Object.assign({}, h.pending);
        for (const n in p) {
            const g = p[n];
            const m = mons[n];
            if (m && Date.now() - g.at < 1000 && (m.ws !== g.to.ws || m.special !== g.to.special)) {
                m.ws = g.to.ws;
                m.special = g.to.special;
            } else {
                delete p[n];
            }
        }
        h.pending = p;
        const list = [];
        const map = {};
        for (const t of Hyprland.toplevels.values) {
            const o = t.lastIpcObject;
            if (!o || !o.at || !o.mapped || o.hidden)
                continue;
            const w = {
                address: h.clean(o.address),
                cls: o.class || "",
                title: o.title || "",
                pid: o.pid || 0,
                monitor: idToName[o.monitor] || "",
                ws: o.workspace ? o.workspace.id : -1,
                wsName: o.workspace ? o.workspace.name : "",
                special: o.workspace ? o.workspace.id < 0 : false,
                x: o.at[0],
                y: o.at[1],
                w: o.size[0],
                h: o.size[1],
                floating: !!o.floating,
                fullscreen: (o.fullscreen || 0) > 0,
                history: o.focusHistoryID === undefined ? 99 : o.focusHistoryID,
                toplevel: t,
                wayland: t.wayland
            };
            list.push(w);
            map[w.address] = w;
            if (w.history === 0)
                h.lastFocused = w.address;
        }
        const urg = {};
        for (const ws of Hyprland.workspaces.values)
            if (ws.urgent)
                urg[ws.id] = true;
        const sig = JSON.stringify(mons) + "|" + JSON.stringify(urg) + "|" + list.map(w => [w.address, w.cls, w.title, w.monitor, w.ws, w.wsName, w.x, w.y, w.w, w.h, w.floating, w.fullscreen, w.history].join(",")).join(";");
        if (sig === h.lastSig && (h.guessAt === 0 || Date.now() - h.guessAt < 200))
            return;
        h.guessAt = 0;
        h.lastSig = sig;
        const prevMons = h.monitors;
        const prev = h.byAddress;
        h.monitors = mons;
        h.urgent = urg;
        h.byAddress = map;
        h.windows = list;
        if (h.primed) {
            for (const a in map)
                if (!prev[a])
                    h.opened(map[a]);
            for (const n in mons)
                if (prevMons[n] && prevMons[n].ws !== mons[n].ws)
                    h.workspaceSwitched(n, prevMons[n].ws, mons[n].ws);
        }
        h.primed = true;
    }

    onActiveChanged: {
        const from = h.lastActive;
        h.lastActive = h.active;
        h.focusMoved(from, h.active);
        h.run(["t"]);
    }

    Timer {
        id: burst
        interval: 70
        repeat: true
        onTriggered: {
            h.run(["t"]);
            if (--h.burstLeft <= 0)
                stop();
        }
    }

    Timer {
        id: seq
        interval: 12
        repeat: true
        onTriggered: h.step()
    }

    Timer {
        id: debounce
        interval: 0
        onTriggered: h.rebuild()
    }

    Timer {
        id: late
        interval: 60
        onTriggered: h.rebuild()
    }

    Timer {
        id: confirm
        interval: 250
        onTriggered: h.rebuild()
    }

    Timer {
        running: true
        repeat: true
        interval: Number(Quickshell.env("GLASSHOUSE_POLL_MS") || 1000)
        onTriggered: h.run(["t"])
    }

    Timer {
        id: recheck
        interval: 2000
        onTriggered: h.askPlugins()
    }

    Process {
        id: plugins
        property int heard: 0
        command: ["hyprctl", "-j", "plugin", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (plugins.heard === h.vitrailHeard)
                        h.vitrail = JSON.parse(text).some(p => p.name === "vitrail");
                } catch (e) {}
            }
        }
    }

    Instantiator {
        model: Hyprland.toplevels
        delegate: Connections {
            required property var modelData
            target: modelData
            function onLastIpcObjectChanged(): void {
                debounce.restart();
            }
        }
    }

    Instantiator {
        model: Hyprland.monitors
        delegate: Connections {
            required property var modelData
            target: modelData
            function onLastIpcObjectChanged(): void {
                debounce.restart();
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            switch (event.name) {
            case "closewindow":
                {
                    const gone = h.byAddress[h.clean(event.data)];
                    if (gone)
                        h.closed(gone);
                    h.settle();
                    break;
                }
            case "openwindow":
                {
                    const f = event.data.split(",");
                    h.opening(h.clean(f[0]), f[1] || "", f[2] || "");
                    h.settle(["t", "m", "w"]);
                    break;
                }
            case "changefloatingmode":
            case "fullscreen":
            case "windowtitlev2":
            case "pin":
                h.touch();
                break;
            case "custom":
                if (event.data.startsWith("glasshouse"))
                    h.touch();
                if (event.data === "vitrail-leaving") {
                    h.vitrail = false;
                    h.vitrailHeard++;
                    recheck.restart();
                }
                break;
            case "workspacev2":
                h.shown(parseInt(event.data), "");
                h.glance();
                break;
            case "focusedmonv2":
                {
                    const f = event.data.split(",");
                    h.shown(parseInt(f[1]), f[0]);
                    h.glance();
                    break;
                }
            case "activespecialv2":
                {
                    const f = event.data.split(",");
                    h.scratch(f[2] || "", f[1] || "");
                    h.glance();
                    break;
                }
            case "vitrail":
                if (event.data === "ready" || event.data === "gone") {
                    h.vitrail = event.data === "ready";
                    h.vitrailHeard++;
                }
                break;
            case "configreloaded":
                h.askPlugins();
                h.settle();
                break;
            case "movewindowv2":
            case "moveworkspacev2":
            case "createworkspacev2":
            case "destroyworkspacev2":
            case "monitoraddedv2":
            case "monitorremovedv2":
            case "urgent":
            case "minimized":
                h.settle();
                break;
            }
        }
    }

    Component.onCompleted: {
        h.askPlugins();
        h.settle();
    }
}
