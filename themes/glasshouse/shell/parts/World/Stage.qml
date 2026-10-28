pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.core

Singleton {
    id: st

    readonly property real k: 1.025
    readonly property size source: Qt.size(2560, 1440)
    readonly property real deepPx: 0
    readonly property int panMs: Theme.panMs
    readonly property int lifeMs: 67
    readonly property int fastMs: 33
    readonly property int sideEvery: 3
    readonly property int coveredEvery: 2
    property int tick: 0
    readonly property bool fast: Object.keys(st.outs).some(n => st.outs[n].live && st.outs[n].boost > 0)
    property int idleS: 60

    property var outs: ({})
    property var wants: ({})
    property bool woken: false
    property bool bare: false
    property bool held: false
    property bool hosted: false
    readonly property bool idle: idler.object ? idler.object.isIdle : false
    readonly property bool anyLive: Object.keys(st.outs).some(n => st.outs[n].live)

    function of(name: string): var {
        return st.outs[name] || null;
    }

    function hurry(name: string, n: int): void {
        const o = st.of(name);
        if (o)
            o.boost = Math.max(0, o.boost + n);
    }

    function want(name: string, n: int): void {
        const m = Object.assign({}, st.wants);
        m[name] = Math.max(0, (m[name] || 0) + n);
        st.wants = m;
    }

    readonly property var effects: ({
            main: {
                dark: [
                    { id: "flow", kind: "Flow", area: [180, 1140, 1480, 300], ride: "far", mask: "world/layers/room-floor.png", poly: st.water },
                    { id: "lantern", kind: "Lantern", area: [988, 122, 680, 680], ride: "far" },
                    { id: "moon", kind: "Moonlight", area: [1120, 520, 820, 920], ride: "far" },
                    { id: "embers", kind: "Motes", area: [250, 560, 1000, 760], ride: "far", seed: 1 },
                    { id: "glint", kind: "Glint", area: [470, 320, 220, 140], ride: "far", seed: 3 }
                ],
                light: [
                    { id: "flow", kind: "Flow", area: [180, 1140, 1480, 300], ride: "far", mask: "world/layers/room-floor.png", poly: st.water, tint: "#ffe3b8", lo: 0.05, hi: 0.28, gain: 2.6 },
                    { id: "dust-l", kind: "Motes", area: [180, 120, 520, 800], ride: "far", seed: 5, look: "dust" },
                    { id: "dust-r", kind: "Motes", area: [1660, 80, 700, 980], ride: "far", seed: 9, look: "dust" },
                    { id: "glass", kind: "Sparkles", area: [640, 0, 1040, 1000], ride: "deep", seed: 2, spots: st.lightGlass },
                    { id: "brass", kind: "Sparkles", area: [690, 110, 140, 710], ride: "far", seed: 7, spots: st.lightBrass, slots: 1 },
                    { id: "glint", kind: "Glint", area: [470, 320, 220, 140], ride: "far", seed: 3, tint: "#fff0c8", power: 0.55 }
                ]
            },
            side: {
                dark: [
                    { id: "orb", kind: "Orb", area: [1249.33, 622.67, 373.33, 373.33], ride: "far" },
                    { id: "sea", kind: "Sea", area: [400, 720, 800, 128], ride: "far", seed: 4 }
                ],
                light: [
                    { id: "table", kind: "Caustics", area: [480, 1000, 1800, 200], ride: "far", poly: [[486.67, 1009.33], [2273.33, 1080], [2273.33, 1122.67], [1376, 1190.67], [496, 1053.33]], cellX: 320, zScale: 3.2, back: 0.55, gain: 0.42, tilt: 0.04 },
                    { id: "bubbles", kind: "Sparkles", area: [240, 0, 1066.67, 1093.33], ride: "far", seed: 6, spots: st.dinerSpots, size: 8, slots: 2 }
                ]
            }
        })
    readonly property var water: [[262, 1190], [600, 1180], [1640, 1168], [1600, 1440], [200, 1440]]
    readonly property var lightGlass: [[815, 690], [950, 81], [1132, 117], [908, 108], [935, 341], [837, 347], [1106, 244], [1097, 287], [901, 145], [1057, 91], [1502, 712], [1090, 178], [974, 173], [862, 198], [929, 223], [1531, 472], [1293, 213], [1135, 42], [889, 615], [1024, 259], [1281, 291], [1067, 49], [1516, 598], [943, 263], [1590, 739], [1412, 685], [1351, 275], [1380, 120], [1450, 330], [1560, 250], [1600, 420], [1230, 160]]
    readonly property var lightBrass: [[787, 797], [780, 260], [766, 315], [715, 513], [730, 453], [810, 133]]
    readonly property var dinerSpots: [[450.67, 96], [309.33, 273.33], [1016, 354.67], [1206.67, 493.33], [997.33, 632], [810.67, 989.33], [1185.33, 1037.33]]

    function props(spec: var, output: string, world: string, origin: point): var {
        const p = { output: output, world: world, origin: origin, area: Qt.rect(spec.area[0], spec.area[1], spec.area[2], spec.area[3]), ride: spec.ride || "far", seed: spec.seed || 0 };
        for (const k in spec)
            if (["id", "kind", "area", "ride", "seed"].indexOf(k) < 0)
                p[k] = spec[k];
        return p;
    }

    function fx(role: string, world: string): var {
        const r = st.effects[role === "side" ? "side" : "main"];
        return r ? (r[world] || []) : [];
    }

    function base(role: string): string {
        return role === "side" ? "diner" : "room";
    }

    function still(role: string, world: string): string {
        return role === "side" ? Assets.diner(world) : Assets.room(world);
    }
    function card(role: string, world: string, which: string): string {
        return Assets.url("world/layers/" + st.base(role) + "-" + world + "-" + which + ".png");
    }
    function deep(role: string, world: string): string {
        return st.card(role, world, "front") ? st.card(role, world, "bay") : "";
    }
    function plate(role: string, world: string): string {
        return st.deep(role, world) ? st.card(role, world, "front") : st.still(role, world);
    }
    function cut(role: string, world: string): string {
        return st.card(role, world, "near");
    }
    function layers(name: string, world: string): var {
        const o = st.of(name);
        const role = o ? o.role : "main";
        return { still: st.still(role, world), plate: st.plate(role, world), deep: st.deep(role, world), cut: st.cut(role, world), source: [st.source.width, st.source.height] };
    }

    function place(name: string, area: rect, ride: string, p: real): rect {
        const o = st.of(name);
        if (!o)
            return Qt.rect(0, 0, 0, 0);
        const x0 = o.cx - p * (ride === "deep" ? st.deepPx : o.farPx);
        return Qt.rect(x0 + area.x * o.s, o.fy + area.y * o.s, area.width * o.s, area.height * o.s);
    }

    function holdAll(name: string, world: string): rect {
        const o = st.of(name);
        const list = o ? st.fx(o.role, world) : [];
        if (!list.length)
            return Qt.rect(0, 0, 1, 1);
        let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
        for (const e of list) {
            const r = st.hold(name, Qt.rect(e.area[0], e.area[1], e.area[2], e.area[3]), e.ride || "far");
            x0 = Math.min(x0, r.x);
            y0 = Math.min(y0, r.y);
            x1 = Math.max(x1, r.x + r.width);
            y1 = Math.max(y1, r.y + r.height);
        }
        return Qt.rect(x0, y0, x1 - x0, y1 - y0);
    }

    function hold(name: string, area: rect, ride: string): rect {
        const o = st.of(name);
        if (!o)
            return Qt.rect(0, 0, 1, 1);
        const a = st.place(name, area, ride, 1);
        const b = st.place(name, area, ride, -1);
        const x0 = Math.max(0, Math.floor(Math.min(a.x, b.x)));
        const y0 = Math.max(0, Math.floor(a.y));
        const x1 = Math.min(o.sw, Math.ceil(Math.max(a.x, b.x) + a.width));
        const y1 = Math.min(o.sh, Math.ceil(a.y + a.height));
        return Qt.rect(x0, y0, Math.max(1, x1 - x0), Math.max(1, y1 - y0));
    }

    function reserved(name: string): var {
        const m = Hyprland.monitors.values.find(v => v.name === name);
        const r = m && m.lastIpcObject ? m.lastIpcObject.reserved : null;
        return r && r.length === 4 ? r : [0, 0, 0, 0];
    }

    function cover(name: string, x: real, y: real, w: real, h: real): real {
        const o = st.of(name);
        if (!o || w <= 0 || h <= 0)
            return 0;
        const r = st.reserved(name);
        const rects = Hypr.on(name).map(v => [v.lx, v.ly, v.lx + v.w, v.ly + v.h]).concat([[0, 0, r[0], o.sh], [0, 0, o.sw, r[1]], [o.sw - r[2], 0, o.sw, o.sh], [0, o.sh - r[3], o.sw, o.sh]]);
        const cl = rects.map(q => [Math.max(q[0], x), Math.max(q[1], y), Math.min(q[2], x + w), Math.min(q[3], y + h)]).filter(q => q[2] > q[0] && q[3] > q[1]);
        if (!cl.length)
            return 0;
        const xs = Array.from(new Set(cl.reduce((a, q) => a.concat([q[0], q[2]]), []))).sort((a, b) => a - b);
        let area = 0;
        for (let i = 0; i + 1 < xs.length; i++) {
            const spans = cl.filter(q => q[0] <= xs[i] && q[2] >= xs[i + 1]).map(q => [q[1], q[3]]).sort((a, b) => a[0] - b[0]);
            let len = 0;
            let top = -1e9;
            for (const s of spans) {
                const lo = Math.max(s[0], top);
                if (s[1] > lo)
                    len += s[1] - lo;
                top = Math.max(top, s[1]);
            }
            area += len * (xs[i + 1] - xs[i]);
        }
        return area / (w * h);
    }

    component Out: QtObject {
        id: o

        required property ShellScreen modelData
        readonly property string name: modelData.name
        readonly property string role: Screens.role(name) || "main"
        readonly property real sw: modelData.width
        readonly property real sh: modelData.height
        readonly property var workspaces: Screens.workspaces(name)
        readonly property int index: workspaces.indexOf(Hypr.activeWs(name))
        readonly property real aim: index < 0 ? NaN : (workspaces.length < 2 ? 0 : 2 * index / (workspaces.length - 1) - 1)
        property real pan: 0
        property bool primed: false
        property int boost: 0

        readonly property real fw: Math.round(Math.max(sw, sh * 16 / 9) * st.k)
        readonly property real fh: Math.round(fw * 9 / 16)
        readonly property real fy: Math.floor((sh - fh) / 2)
        readonly property real cx: (sw - fw) / 2
        readonly property real farPx: (Math.round(sw * st.k) - sw) / 4
        readonly property real farX: cx - pan * farPx
        readonly property real deepX: cx - pan * st.deepPx
        readonly property rect frame: Qt.rect(farX, fy, fw, fh)
        readonly property real s: fw / st.source.width

        property real t: 0
        property real stamp: 0
        readonly property int wanted: st.wants[name] || 0
        onLiveChanged: o.stamp = Date.now()
        readonly property var shown: Hypr.on(name)
        readonly property bool fullscreen: shown.some(w => w.fullscreen)
        readonly property real covered: st.cover(name, 0, 0, sw, sh)
        readonly property bool live: wanted > 0 && !fullscreen && (st.woken || !st.idle)

        readonly property NumberAnimation glide: NumberAnimation {
            target: o
            property: "pan"
            duration: st.panMs
            easing.type: Easing.OutCubic
        }

        onAimChanged: {
            if (isNaN(o.aim))
                return;
            if (!o.primed) {
                o.primed = true;
                o.pan = o.aim;
                return;
            }
            o.glide.stop();
            o.glide.to = o.aim;
            o.glide.start();
        }
        Component.onCompleted: {
            if (!isNaN(o.aim)) {
                o.primed = true;
                o.pan = o.aim;
            }
        }
    }

    Instantiator {
        model: Screens.list
        delegate: Out {}
        onObjectAdded: (index, object) => {
            const m = Object.assign({}, st.outs);
            m[object.name] = object;
            st.outs = m;
        }
        onObjectRemoved: (index, object) => {
            const m = Object.assign({}, st.outs);
            delete m[object.name];
            st.outs = m;
        }
    }

    // Quickshell 0.3.1 arms an IdleMonitor's timeout once: a new timeout needs a new monitor
    Instantiator {
        id: idler
        model: [st.idleS]
        delegate: IdleMonitor {
            required property int modelData
            timeout: modelData
            respectInhibitors: true
        }
    }

    Timer {
        interval: st.fast ? st.fastMs : st.lifeMs
        repeat: true
        running: st.anyLive && !st.held
        onRunningChanged: {
            const now = Date.now();
            for (const n in st.outs)
                st.outs[n].stamp = now;
        }
        onTriggered: {
            const now = Date.now();
            st.tick++;
            for (const n in st.outs) {
                const o = st.outs[n];
                const every = o.role === "side" ? st.sideEvery : (o.covered >= 0.9 ? st.coveredEvery : 1);
                if (!o.live || st.tick % every)
                    continue;
                o.t += Math.min(0.2, Math.max(0, (now - o.stamp) / 1000));
                o.stamp = now;
            }
        }
    }

    Timer {
        id: wake
        onTriggered: st.woken = false
    }

    IpcHandler {
        target: "stage"

        function frame(name: string): string {
            const o = st.of(name);
            return o ? JSON.stringify({ frame: [o.farX, o.fy, o.fw, o.fh], farX: o.farX, deepX: o.deepX, pan: o.pan, s: o.s, layers: st.layers(name, World.name) }) : "{}";
        }
        function dump(): string {
            const r = {};
            for (const n in st.outs) {
                const o = st.outs[n];
                r[n] = { role: o.role, pan: o.pan, ws: o.index, t: Math.round(o.t * 100) / 100, live: o.live, wanted: o.wanted, covered: Math.round(o.covered * 1000) / 1000, fullscreen: o.fullscreen, idle: st.idle, woken: st.woken };
            }
            return JSON.stringify(r);
        }
        function idle(seconds: int): void {
            if (Test.on)
                st.idleS = Math.max(1, seconds);
        }
        function hold(on: bool): void {
            if (Test.on)
                st.held = on;
        }
        function host(on: bool): void {
            if (Test.on)
                st.hosted = on;
        }
        function life(on: bool): void {
            if (Test.on)
                st.bare = !on;
        }
        function pan(name: string, p: real): void {
            const o = st.of(name);
            if (Test.on && o) {
                o.glide.stop();
                o.pan = Math.max(-1, Math.min(1, p));
            }
        }
        function glide(name: string, p: real): void {
            const o = st.of(name);
            if (Test.on && o) {
                o.glide.stop();
                o.glide.to = Math.max(-1, Math.min(1, p));
                o.glide.start();
            }
        }
        function seek(name: string, seconds: real): void {
            const o = st.of(name);
            if (Test.on && o)
                o.t = seconds;
        }
        function wake(seconds: int): void {
            if (!Test.on)
                return;
            st.woken = seconds > 0;
            wake.interval = Math.max(1, seconds) * 1000;
            wake.restart();
        }
    }
}
