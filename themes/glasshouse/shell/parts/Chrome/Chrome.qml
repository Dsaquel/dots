import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.core

Scope {
    id: part

    required property ShellScreen screen
    readonly property string name: part.screen.name

    property var model: []
    property var closing: ({})
    property var leaving: ({})
    property var opening: ({})
    property var lastShown: []
    property var hoists: ({})
    property var gone: ({})
    property string lastWs: ""
    property var enterSpec: null
    property double eventAt: 0
    property var testScratch: ({})
    readonly property bool voices: Screens.list.length > 0 && Screens.list[0].name === part.name

    Anim {
        id: anim
    }
    FxClock {
        id: fxClock
        rate: Hypr.monitors[part.name] ? Hypr.monitors[part.name].rate : 60
    }

    function showsWorkspace(ws: string): bool {
        const m = Hypr.monitors[part.name];
        if (!m)
            return false;
        return String(m.ws) === ws || (m.special !== "" && (m.special === ws || "special:" + m.special === ws));
    }

    function isAbove(o: var, w: var): bool {
        if (o.special !== w.special)
            return o.special;
        if (o.floating !== w.floating)
            return o.floating;
        return o.floating && o.history < w.history;
    }

    function overlaps(o: var, w: var, m: real): bool {
        return o.lx < w.lx + w.w + m && o.lx + o.w > w.lx - m && o.ly < w.ly + w.h + m && o.ly + o.h > w.ly - m;
    }

    function sync(): void {
        const m = Hypr.monitors[part.name];
        const ws = m ? m.ws + "|" + m.special : "";
        const now = Date.now();
        const shown = Hypr.on(part.name).map(w => Test.on && part.testScratch[w.address] ? Object.assign({}, w, { special: true, wsName: "special:test" }) : w);
        if (Hypr.vitrail) {
            part.lastWs = ws;
            part.lastShown = shown;
            part.closing = {};
            part.leaving = {};
            part.model = [];
            return;
        }
        if (part.lastWs !== "" && ws !== part.lastWs) {
            const [oldWs, oldSpecial] = part.lastWs.split("|");
            const regular = String(m ? m.ws : "") !== oldWs;
            const special = (m ? m.special : "") !== oldSpecial;
            const dir = Number(m ? m.ws : 0) >= Number(oldWs) ? 1 : -1;
            const leave = Object.assign({}, part.leaving);
            for (const r of part.lastShown) {
                if (shown.some(w => w.address === r.address) || part.closing[r.address])
                    continue;
                const spec = r.special ? anim.specialOut : anim.wsOut;
                const dx = r.special || spec.vertical ? 0 : -dir * spec.slide * (m ? m.w : part.screen.width);
                const dy = r.special || spec.vertical ? spec.slide * (m ? m.h : part.screen.height) : 0;
                leave[r.address] = Object.assign({}, r, { leaveSpec: { dx: dx, dy: dy, ms: spec.ms, curve: spec.curve }, until: now + spec.ms + 40 });
            }
            part.leaving = leave;
            const inSpec = special && !regular ? anim.specialIn : anim.wsIn;
            part.enterSpec = {
                at: now,
                special: special && !regular,
                dx: inSpec.vertical ? 0 : dir * inSpec.slide * (m ? m.w : part.screen.width),
                dy: inSpec.vertical ? inSpec.slide * (m ? m.h : part.screen.height) : 0,
                ms: inSpec.ms,
                curve: inSpec.curve
            };
            leaveTimer.restart();
        }
        part.lastWs = ws;
        part.lastShown = shown;
        const full = shown.some(w => w.fullscreen && !w.special);
        const anySpecial = shown.some(w => w.special);
        const live = shown.filter(w => !w.fullscreen && !(full && !w.special) && !part.closing[w.address]);
        const list = [];
        for (const w of live) {
            const above = live.filter(o => o !== w && part.isAbove(o, w) && part.overlaps(o, w, 72)).map(o => ({ x: o.lx, y: o.ly, w: o.w, h: o.h }));
            list.push(Object.assign({}, w, { key: w.address, above: above, dimmed: anySpecial && !w.special, closing: false }));
        }
        for (const a in part.closing)
            list.push(Object.assign({}, part.closing[a], { key: a, above: [], dimmed: false, closing: true }));
        for (const a in part.leaving)
            if (!list.some(r => r.key === a))
                list.push(Object.assign({}, part.leaving[a], { key: a, above: [], dimmed: false, closing: false }));
        part.model = list;
    }

    function frame(address: string): var {
        for (let i = 0; i < frames.count; i++) {
            const f = frames.itemAt(i);
            if (f && f.win && f.win.address === address)
                return f;
        }
        return null;
    }
    function toward(a: var, b: var): point {
        const cx = Math.max(b.gx, Math.min(b.gx + b.gw, a.gx + a.gw / 2));
        const cy = Math.max(b.gy, Math.min(b.gy + b.gh, a.gy + a.gh / 2));
        return Qt.point(Math.max(a.gx, Math.min(a.gx + a.gw, cx)), Math.max(a.gy, Math.min(a.gy + a.gh, cy)));
    }
    readonly property int carryMs: 120
    readonly property int closeMs: anim.fadeOut.ms

    function voiced(kind: string, address: string, cues: var): var {
        const at = name => cues.find(c => c.name === name);
        if (kind === "swap" || kind === "pivot") {
            const lead = at("shatter"), slam = at("slam");
            return lead ? [{ name: kind, gain: 1, delay: lead.delay }] : slam ? [{ name: kind + "-slam", gain: 1, delay: slam.delay }] : [];
        }
        if (kind === "relay") {
            const swing = part.voiced("swap", address, cues);
            return swing.length ? cues.filter(c => c.name === "give").concat(swing) : cues;
        }
        if (kind === "pyre") {
            const as = { blaze: ["pyre-lift", 0], draft: ["pyre-flight", -20], strike: ["pyre-strike", 0], athanor: ["athanor-pyre", 0] };
            const alone = !!at("athanor");
            return cues.filter(c => as[c.name] && (c.name !== "strike" || alone)).map(c => ({ name: as[c.name][0], gain: 1, delay: Math.max(0, c.delay + as[c.name][1]) }));
        }
        if (kind === "glaze") {
            const crack = at("glaze-crack"), slam = at("glaze-slam"), gild = at("glaze-gild");
            if (crack)
                return [{ name: "scratch-hide", gain: 1, delay: crack.delay }];
            const rows = cues.filter(c => /^glaze-\d$/.test(c.name));
            const lead = rows.length && rows[0].name === "glaze-2" && rows[0].delay >= 80 ? [{ name: "scratch-row-1", gain: 1, delay: 50 }] : [];
            return lead.concat(rows.map(c => ({ name: "scratch-row-" + c.name.slice(6), gain: 1, delay: c.delay })))
                .concat(slam ? [{ name: "scratch-slam", gain: 1, delay: Math.max(0, slam.delay - 168) }] : [])
                .concat(gild ? [{ name: "scratch-gild", gain: 1, delay: gild.delay }] : []);
        }
        if (kind === "mullion") {
            const open = at("unframe") || at("melt"), blink = at("blink"), boom = at("boom");
            const stones = cues.filter(c => c.name.startsWith("stone-"));
            return (open ? [{ name: "crystal-open", gain: 1, delay: open.delay }] : [])
                .concat(stones.reduce((out, c, j) => out.concat([{ name: "crystal-shard-" + Math.min(j + 1, 16), gain: j === 0 || c.name !== stones[j - 1].name ? 1 : 0.56, delay: c.delay },
                                                                 { name: "crystal-spark-" + (j % 6 + 1), gain: 1, delay: c.delay + 4 }]), []))
                .concat(blink ? [{ name: "crystal-flash", gain: 1, delay: blink.delay }] : [])
                .concat(boom ? [{ name: "crystal-ring", gain: 1, delay: boom.delay }] : []);
        }
        if (kind === "hoist") {
            part.hoists = Object.assign({}, part.hoists, { [address]: Date.now() });
            const shatter = at("shatter"), slam = at("slam");
            return [{ name: "crystal-rise", gain: 1, delay: 0 }]
                .concat(shatter ? [{ name: "crystal-burst", gain: 1, delay: shatter.delay }] : [])
                .concat(cues.filter(c => c.name.startsWith("stone-")).map(c => ({ name: "crystal-row-" + Math.min(Number(c.name.slice(6)), 8), gain: 1, delay: c.delay })))
                .concat(slam ? [{ name: "crystal-slam", gain: 1, delay: Math.max(0, slam.delay - 22) }] : []);
        }
        return cues;
    }

    function heard(data: string): void {
        const f = data.split(",");
        if (f[0] === "open" && part.opening[f[1]]) {
            const o = Object.assign({}, part.opening);
            delete o[f[1]];
            part.opening = o;
            if (f[2] !== "mullion")
                Sfx.play(f[2] === "share" ? "share" : "athanor");
        } else if (f[0] === "mullion" || f[0] === "pyre" || f[0] === "pivot" || f[0] === "swap" || f[0] === "relay" || f[0] === "glaze" || f[0] === "hoist" || (f[0] === "arrive" && part.lastShown.some(w => w.address === f[1]))) {
            const cues = f.slice(2).map(cue => {
                const c = cue.split("@");
                return { name: c[0], delay: Number(c[1]), gain: c.length > 2 ? Number(c[2]) : 1 };
            });
            const voiced = part.voiced(f[0], f[1], cues);
            if (part.voices || f[0] === "arrive")
                for (const c of voiced)
                    Sfx.play(c.name, c.gain, c.delay);
        } else if (f[0] === "hush") {
            Sfx.hush();
        } else if (f[0] === "close") {
            const rec = part.gone[f[1]] || part.lastShown.find(w => w.address === f[1]);
            delete part.gone[f[1]];
            if (rec && !rec.fullscreen && !(f[2] === "give" && Date.now() - (part.hoists[f[3]] || 0) < 250))
                Sfx.play(f[2] === "give" ? "give" : "burn");
        } else if (f[0] === "focus" && f[2] && part.lastShown.some(w => w.address === f[2])) {
            Sfx.play("focus");
        } else if (part.voices && f[0] === "translate") {
            Sfx.play("shatter");
        } else if (part.voices && f[0] === "set") {
            Sfx.play("set");
        } else if (part.voices && f[0] === "relead") {
            Sfx.play("relead", 0.8);
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event: HyprlandEvent): void {
            part.eventAt = Date.now();
            if (event.name === "closewindow") {
                const rec = part.lastShown.find(w => w.address === Hypr.clean(event.data));
                if (rec)
                    part.gone[rec.address] = rec;
            }
            if (event.name === "vitrail")
                part.heard(event.data);
            if (event.name === "urgent") {
                const f = part.frame(Hypr.clean(event.data));
                if (f && !f.focused && !f.closing)
                    f.call();
            }
        }
    }

    Connections {
        target: Hypr
        function onWindowsChanged(): void {
            part.sync();
        }
        function onMonitorsChanged(): void {
            part.sync();
        }
        function onVitrailChanged(): void {
            part.sync();
        }
        function onOpening(address: string, workspace: string, cls: string): void {
            if (!part.showsWorkspace(workspace))
                return;
            const o = Object.assign({}, part.opening);
            o[address] = Date.now();
            part.opening = o;
        }
        function onOpened(win: var): void {
            if (Hypr.vitrail || win.monitor !== part.name || !part.opening[win.address])
                return;
            const o = Object.assign({}, part.opening);
            delete o[win.address];
            part.opening = o;
            const rec = Hypr.on(part.name).find(w => w.address === win.address);
            if (!rec || rec.fullscreen)
                return;
            const born = part.frame(rec.address);
            if (born)
                born.slide(0, 0, 0, 0, 0, 1, anim.fadeIn.ms, anim.fadeIn.curve);
            Sfx.play("open");
        }
        function onClosed(win: var): void {
            const rec = part.lastShown.find(w => w.address === win.address);
            if (Hypr.vitrail || !rec || rec.fullscreen)
                return;
            const c = Object.assign({}, part.closing);
            c[win.address] = Object.assign({}, rec, { until: Date.now() + part.closeMs });
            part.closing = c;
            part.sync();
            const gone = part.frame(win.address);
            if (gone)
                gone.slide(0, 0, gone.shown, 0, 0, 0, part.closeMs, anim.fadeOut.curve);
            closeTimer.restart();
            Sfx.play("close");
        }
        function onFocusMoved(from: string, to: string): void {
            const gone = part.frame(from) && part.frame(from).closing ? part.frame(from) : null;
            const prev = part.frame(from) && !gone ? part.frame(from) : null;
            const next = part.frame(to);
            if (!prev && !next)
                return;
            if (gone && next) {
                next.shine(part.toward(next, gone), part.closeMs, true);
                Sfx.play("focus");
                return;
            }
            const exit = prev && next ? part.toward(prev, next) : null;
            const entry = exit ? part.toward(next, prev) : null;
            if (prev)
                prev.shine(exit, 0, false);
            if (next) {
                next.shine(entry, exit ? part.carryMs : 0, true);
                Sfx.play("focus");
            }
            if (exit)
                lantern.carry(exit, entry);
        }
    }

    Timer {
        id: closeTimer
        interval: 120
        repeat: true
        running: Object.keys(part.closing).length > 0
        onTriggered: {
            const now = Date.now();
            const c = {};
            for (const a in part.closing)
                if (part.closing[a].until > now)
                    c[a] = part.closing[a];
            if (Object.keys(c).length !== Object.keys(part.closing).length) {
                part.closing = c;
                part.sync();
            }
        }
    }
    Timer {
        id: leaveTimer
        interval: 60
        repeat: true
        running: Object.keys(part.leaving).length > 0
        onTriggered: {
            const now = Date.now();
            const l = {};
            for (const a in part.leaving)
                if (part.leaving[a].until > now)
                    l[a] = part.leaving[a];
            if (Object.keys(l).length !== Object.keys(part.leaving).length) {
                part.leaving = l;
                part.sync();
            }
        }
    }

    PanelWindow {
        id: surface
        screen: part.screen
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "glasshouse-chrome"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        mask: Region {}

        Repeater {
            id: frames
            model: ScriptModel {
                values: part.model
                objectProp: "key"
            }
            Frame {
                id: frame
                required property var modelData
                win: modelData
                focused: modelData.address === Hypr.active
                above: modelData.above
                dimmed: modelData.dimmed
                closing: modelData.closing
                moveMs: anim.move.ms
                moveCurve: anim.move.curve
                eventAt: part.eventAt
                clock: fxClock
                z: (modelData.special ? 3 : (modelData.floating ? 2 : 1)) + (focused ? 0.5 : 0)

                readonly property var leaveSpec: modelData.leaveSpec || null
                onLeaveSpecChanged: {
                    if (frame.leaveSpec)
                        frame.slide(0, 0, 1, frame.leaveSpec.dx, frame.leaveSpec.dy, 0, frame.leaveSpec.ms, frame.leaveSpec.curve);
                    else if (part.leaving[modelData.address])
                        frame.slide(frame.slideX, frame.slideY, frame.shown, 0, 0, 1, anim.wsIn.ms, anim.wsIn.curve);
                }

                Component.onCompleted: {
                    const e = part.enterSpec;
                    if (e && Date.now() - e.at < 80 && e.ms > 0 && (!e.special || modelData.special))
                        frame.slide(e.dx, e.dy, 0, 0, 0, 1, e.ms, e.curve);
                    if (frame.leaveSpec)
                        frame.slide(0, 0, 1, frame.leaveSpec.dx, frame.leaveSpec.dy, 0, frame.leaveSpec.ms, frame.leaveSpec.curve);
                }
            }
        }

        ShaderEffect {
            id: lantern
            z: 20
            width: 132
            height: 132
            visible: lanternTw.running
            property point a: Qt.point(0, 0)
            property point b: Qt.point(0, 0)
            property real k: 0
            x: lantern.a.x + (lantern.b.x - lantern.a.x) * lantern.k - width / 2
            y: lantern.a.y + (lantern.b.y - lantern.a.y) * lantern.k - height / 2
            opacity: Math.sin(Math.PI * Math.min(1, lanternTw.progress * 1.15))
            property color color: lightOfSurface.color
            property real core: 0.09
            property real intensity: 1.35
            fragmentShader: Qt.resolvedUrl("../../shaders/glow.frag.qsb")
            function carry(from: point, to: point): void {
                lantern.a = from;
                lantern.b = to;
                lanternTw.start();
            }
            Light {
                id: lightOfSurface
                screen: part.name
            }
            Tween {
                id: lanternTw
                rate: fxClock.rate
                clock: fxClock
                duration: part.carryMs + 90
                onProgressChanged: lantern.k = inOutCubic(Math.min(1, progress * duration / part.carryMs))
            }
        }
    }

    IpcHandler {
        target: "chrome"
        enabled: Screens.list.length > 0 && Screens.list[0].name === part.name
        function dump(): string {
            return JSON.stringify({
                screen: part.name,
                vitrail: Hypr.vitrail,
                frames: part.model.map(r => [r.key, r.cls, r.lx, r.ly, r.w, r.h, r.floating, r.special, r.closing, r.above.length]),
                active: Hypr.active,
                move: anim.move,
                wsIn: anim.wsIn
            });
        }
        function scratch(address: string): void {
            if (!Test.on)
                return;
            const s = {};
            if (address !== "")
                s[address.replace(/^0x/, "")] = true;
            part.testScratch = s;
            part.sync();
        }
    }
    Component.onCompleted: part.sync()
}
