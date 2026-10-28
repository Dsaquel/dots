import QtQuick
import qs.core
import qs.kit

Item {
    id: f

    required property var win
    property bool focused: false
    property string screen: f.win ? f.win.monitor : ""
    property var above: []
    property int moveMs: 0
    property var moveCurve: [0.25, 0.1, 0.25, 1, 1, 1]
    property double eventAt: 0
    property bool dimmed: false
    property bool closing: false
    property var clock: null
    property real slideX: 0
    property real slideY: 0
    property real shown: 1

    readonly property real margin: 72
    readonly property bool compact: !!(f.win && (f.win.special || f.win.w < 360 || f.win.h < 220))
    readonly property bool floating: !!(f.win && f.win.floating)
    readonly property bool dark: Theme.dark
    readonly property real rate: Hypr.monitors[f.screen] ? Hypr.monitors[f.screen].rate : 60
    readonly property bool lit: f.focused && !f.closing
    property var from: ({ x: 0, y: 0, w: 0, h: 0 })
    property var to: ({ x: 0, y: 0, w: 0, h: 0 })
    property var curve: f.moveCurve
    property real gp: 1
    readonly property real ease: f.gp >= 1 ? 1 : f.bezier(f.gp, f.curve)
    readonly property real gx: f.from.x + (f.to.x - f.from.x) * f.ease
    readonly property real gy: f.from.y + (f.to.y - f.from.y) * f.ease
    readonly property real gw: f.from.w + (f.to.w - f.from.w) * f.ease
    readonly property real gh: f.from.h + (f.to.h - f.from.h) * f.ease
    property bool placed: false
    property double lastMove: 0
    onWinChanged: f.place()

    function bezier(x: real, c: var): real {
        const bx = s => 3 * (1 - s) * (1 - s) * s * c[0] + 3 * (1 - s) * s * s * c[2] + s * s * s;
        const by = s => 3 * (1 - s) * (1 - s) * s * c[1] + 3 * (1 - s) * s * s * c[3] + s * s * s;
        let lo = 0;
        let hi = 1;
        let s = x;
        for (let i = 0; i < 18; i++) {
            const v = bx(s);
            if (Math.abs(v - x) < 1e-4)
                break;
            if (v < x)
                lo = s;
            else
                hi = s;
            s = (lo + hi) / 2;
        }
        return by(s);
    }

    function place(): void {
        if (!f.win)
            return;
        const w = f.win;
        if (f.placed && w.lx === f.to.x && w.ly === f.to.y && w.w === f.to.w && w.h === f.to.h)
            return;
        const now = Date.now();
        const quick = now - f.lastMove < 150;
        f.lastMove = now;
        glide.stop();
        const target = { x: w.lx, y: w.ly, w: w.w, h: w.h };
        if (!f.placed || quick || f.moveMs <= 0) {
            f.from = target;
            f.to = target;
            f.gp = 1;
            f.placed = true;
            return;
        }
        const age = now - f.eventAt;
        const heard = age >= 0 && age < 200;
        f.from = { x: f.gx, y: f.gy, w: f.gw, h: f.gh };
        f.to = target;
        f.curve = heard ? f.moveCurve : [0.33, 1, 0.68, 1, 1, 1];
        const ms = heard ? f.moveMs : Math.min(f.moveMs, 180);
        const start = heard ? Math.min(0.9, age / f.moveMs) : 0;
        f.gp = start;
        glide.from = start;
        glide.duration = Math.max(1, ms * (1 - start));
        glide.start();
    }
    NumberAnimation {
        id: glide
        target: f
        property: "gp"
        to: 1
        easing.type: Easing.Linear
    }
    readonly property rect rect: Qt.rect(f.margin, f.margin, f.gw, f.gh)
    readonly property real cameOut: f.compact ? 6.5 : 8

    readonly property real rr: 8 + 3.5
    readonly property real ex: Math.max(0, f.gw / 2 - 8)
    readonly property real ey: Math.max(0, f.gh / 2 - 8)
    readonly property real arc: Math.PI / 2 * f.rr
    readonly property real per: 4 * (f.ex + f.ey) + 4 * f.arc
    function uOf(px: real, py: real): real {
        const qx = px - (f.gx + f.gw / 2);
        const qy = py - (f.gy + f.gh / 2);
        const ex = f.ex;
        const ey = f.ey;
        const a = f.arc;
        const lx = 2 * ex;
        const ly = 2 * ey;
        if (Math.abs(qx) <= ex)
            return qy < 0 ? qx + ex : lx + 2 * a + ly + (ex - qx);
        if (Math.abs(qy) <= ey)
            return qx > 0 ? lx + a + (qy + ey) : 2 * lx + 3 * a + ly + (ey - qy);
        const dx = Math.abs(qx) - ex;
        const dy = Math.abs(qy) - ey;
        if (qx > 0 && qy < 0)
            return lx + Math.atan2(dx, dy + 1e-5) * f.rr;
        if (qx > 0)
            return lx + a + ly + Math.atan2(dy, dx + 1e-5) * f.rr;
        if (qy > 0)
            return 2 * lx + 2 * a + ly + Math.atan2(dx, dy + 1e-5) * f.rr;
        return 2 * lx + 3 * a + 2 * ly + Math.atan2(dy, dx + 1e-5) * f.rr;
    }
    function circ(a: real, b: real): real {
        const d = Math.abs(a - b) % Math.max(1, f.per);
        return Math.min(d, f.per - d);
    }

    property real litAt: 0
    property real litReach: 1e5
    property real litIn: 0
    property real litOut: 0
    property bool litTarget: false
    property real reachFrom: 0
    property real reachTo: 0
    property int lightDelay: 0
    property double lightAt: 0
    readonly property real level: f.litOut + (f.litIn - f.litOut) * Math.max(0, Math.min(1, f.litReach / Math.max(1, f.per / 2)))
    function litOf(u: real): real {
        const k = Math.max(0, Math.min(1, (f.litReach - f.circ(u, f.litAt)) / 90));
        return f.litOut + (f.litIn - f.litOut) * k * k * (3 - 2 * k);
    }
    function shine(at: var, delay: int, on: bool): void {
        const p = at || worldLight.pos;
        const now = f.level;
        lightTw.stop();
        f.litAt = f.uOf(p.x, p.y);
        f.litTarget = on;
        f.litOut = on ? Math.min(now, 1) : 0;
        f.litIn = on ? 1 : Math.max(now, 0);
        f.reachFrom = on ? -90 : f.per / 2 + 90;
        f.reachTo = on ? f.per / 2 + 90 : -90;
        f.litReach = f.reachFrom;
        f.lightDelay = delay;
        f.lightAt = Date.now();
        lightTw.duration = delay + (on ? 240 : 170);
        lightTw.start();
    }
    function relight(): void {
        if (f.closing || (f.litTarget === f.lit && Date.now() - f.lightAt < 60))
            return;
        f.shine(null, 0, f.lit);
    }
    Tween {
        id: lightTw
        rate: f.rate
        clock: f.clock
        onProgressChanged: {
            if (progress >= 1) {
                f.litIn = f.litTarget ? 1 : 0;
                f.litOut = f.litIn;
                f.litReach = 1e5;
                return;
            }
            const ms = progress * duration - f.lightDelay;
            if (ms < 0)
                return;
            const k = ms / Math.max(1, duration - f.lightDelay);
            f.litReach = f.reachFrom + (f.reachTo - f.reachFrom) * (f.litTarget ? outCubic(k) : inQuad(k));
        }
    }

    property real laidAt: 0
    property real laidHalf: 1e5
    property real laidHeat: 0
    property int gapSide: -1
    property real gapFrac: 0
    property real gapHeat: 0
    property real sealAt: 0
    property real sealReach: 1e5
    property real sealHeat: 0
    property var tracks: []
    function sideMid(s: int): real {
        return [f.ex, 2 * f.ex + f.arc + f.ey, 3 * f.ex + 2 * f.arc + 2 * f.ey, 4 * f.ex + 3 * f.arc + 3 * f.ey][s];
    }
    readonly property real gapCentre: f.gapSide < 0 ? 0 : f.sideMid(f.gapSide)
    readonly property real gapReach: f.gapSide < 0 ? 0 : f.gapFrac * ((f.gapSide % 2 === 0 ? f.ex : f.ey) + f.arc / 2)
    readonly property real sealFrom: f.gapSide < 0 ? f.sealAt : f.gapCentre
    function laidOf(u: real): real {
        return f.circ(u, f.laidAt) <= f.laidHalf && (f.gapSide < 0 || f.circ(u, f.gapCentre) >= f.gapReach) ? 1 : 0;
    }
    function play(tracks: var): void {
        f.tracks = tracks;
        lifeTw.duration = Math.max(1, Math.max.apply(null, tracks.map(t => t.at + t.ms)));
        f.step(0);
        lifeTw.start();
    }
    function step(ms: real): void {
        for (const t of f.tracks) {
            if (t.hold && ms < t.at)
                continue;
            const k = Math.max(0, Math.min(1, (ms - t.at) / Math.max(1, t.ms)));
            const e = t.ease === "in" ? k * k * k : (t.ease === "io" ? (k < 0.5 ? 4 * k * k * k : 1 - Math.pow(-2 * k + 2, 3) / 2) : (t.ease === "lin" ? k : (t.ease === "quad" ? 1 - (1 - k) * (1 - k) : 1 - Math.pow(1 - k, 3))));
            f[t.p] = t.a + (t.b - t.a) * e;
        }
    }
    function settle(): void {
        f.laidHalf = 1e5;
        f.laidHeat = 0;
        f.gapSide = -1;
        f.gapFrac = 0;
        f.gapHeat = 0;
        f.sealReach = 1e5;
        f.sealHeat = 0;
    }
    Tween {
        id: lifeTw
        rate: f.rate
        clock: f.clock
        onProgressChanged: f.step(progress * duration)
        onDone: f.settle()
    }

    property real lift: 0
    onFloatingChanged: {
        liftTw.from = f.lift;
        liftTw.to = f.floating ? 1 : 0;
        liftTw.start();
        if (!f.closing) {
            f.sealAt = f.ex;
            f.play([
                { p: "sealReach", a: -40, b: f.per / 2 + 60, at: 60, ms: 280, ease: "lin" },
                { p: "sealHeat", a: 0.75, b: 0, at: 200, ms: 220, ease: "lin" }
            ]);
        }
    }
    Tween {
        id: liftTw
        property real from: 0
        property real to: 0
        rate: f.rate
        clock: f.clock
        duration: 300
        onProgressChanged: f.lift = from + (to - from) * outCubic(progress)
    }

    property real callGlow: 0
    function call(): void {
        callTw.start();
    }
    Tween {
        id: callTw
        rate: f.rate
        clock: f.clock
        duration: 1500
        onProgressChanged: {
            const s = Math.sin(3 * Math.PI * progress);
            f.callGlow = progress >= 1 ? 0 : s * s * (1 - 0.35 * progress);
        }
    }

    onLitChanged: {
        if (f.lit)
            f.richWanted = true;
        else
            richKeep.restart();
        Qt.callLater(f.relight);
    }

    x: f.gx - f.margin
    y: f.gy - f.margin
    width: f.gw + 2 * f.margin
    height: f.gh + 2 * f.margin
    opacity: f.shown * (f.dimmed ? 0.45 : 1)
    transform: Translate {
        x: f.slideX
        y: f.slideY
    }

    function slide(dx: real, dy: real, a0: real, tx: real, ty: real, a1: real, ms: int, curve: var): void {
        slideFx.stop();
        f.slideX = dx;
        f.slideY = dy;
        f.shown = a0;
        sx.to = tx;
        sy.to = ty;
        sa.to = a1;
        for (const anim of [sx, sy, sa]) {
            anim.duration = Math.max(1, ms);
            anim.easing.bezierCurve = curve;
        }
        slideFx.start();
    }
    ParallelAnimation {
        id: slideFx
        NumberAnimation { id: sx; target: f; property: "slideX"; easing.type: Easing.BezierSpline }
        NumberAnimation { id: sy; target: f; property: "slideY"; easing.type: Easing.BezierSpline }
        NumberAnimation { id: sa; target: f; property: "shown"; easing.type: Easing.BezierSpline }
    }

    Light {
        id: worldLight
        screen: f.screen
    }
    AppInfo {
        id: appInfo
        cls: f.win ? f.win.cls : ""
        pid: f.win ? f.win.pid : 0
    }

    readonly property point light: Qt.point(worldLight.pos.x - f.x, worldLight.pos.y - f.y)
    function cornerGlow(px: real, py: real): real {
        const dx = worldLight.pos.x - (f.x + px);
        const dy = worldLight.pos.y - (f.y + py);
        return 0.28 + 0.72 * Math.exp(-(dx * dx + dy * dy) / (820 * 820));
    }
    readonly property var occ: {
        const out = [];
        for (const r of f.above.slice(0, 4))
            out.push(Qt.vector4d(r.x - f.x, r.y - f.y, r.w, r.h));
        while (out.length < 4)
            out.push(Qt.vector4d(0, 0, 0, 0));
        return out;
    }

    ShaderEffect {
        anchors.fill: parent
        property vector2d box: Qt.vector2d(width, height)
        property rect win: f.rect
        property real radius: 8
        property color veil: f.dark ? Qt.rgba(0.04, 0.05, 0.13, 0.2 * (1 - f.level)) : Qt.rgba(0.48, 0.25, 0.32, 0.1 * (1 - f.level))
        property color shadow: f.dark ? Qt.rgba(0.01, 0.015, 0.05, 0.66 * f.lift) : Qt.rgba(0.08, 0.07, 0.28, 0.5 * f.lift)
        property vector2d shadowOffset: Qt.vector2d(0, 4 + 12 * f.lift)
        property real shadowBlur: 16 + 24 * f.lift
        property vector4d occ0: f.occ[0]
        property vector4d occ1: f.occ[1]
        property vector4d occ2: f.occ[2]
        property vector4d occ3: f.occ[3]
        property real occRadius: 8
        fragmentShader: Qt.resolvedUrl("../../shaders/veil.frag.qsb")
    }

    Skin {
        anchors.fill: parent
        win: f.rect
        offset: f.cameOut
        hwOff: f.compact ? 1.0 : 1.15
        hwOn: f.compact ? 1.7 : 2.2
        lightPos: Qt.vector4d(f.light.x, f.light.y, 520, 640)
        pool: Qt.darker(worldLight.color, f.dark ? 1.6 : 2.2)
        lit: Qt.vector4d(f.litAt, f.litReach, f.litOut, f.litIn)
        laid: Qt.vector4d(f.laidAt, f.laidHalf, f.laidHeat, 0)
        gap: Qt.vector4d(f.gapCentre, f.gapReach, f.gapHeat, 0)
        seal: Qt.vector4d(f.sealFrom, f.sealReach, f.sealHeat, 0)
        call: Qt.vector4d(Theme.alert.r, Theme.alert.g, Theme.alert.b, f.callGlow)
        occ: f.occ
    }

    property bool richWanted: false
    Timer {
        id: richKeep
        interval: 60000
        onTriggered: if (!f.lit) f.richWanted = false
    }
    readonly property var cornerU: [f.per - f.arc / 2, 2 * f.ex + f.arc / 2, 2 * f.ex + f.arc + 2 * f.ey + f.arc / 2, 4 * f.ex + 2 * f.arc + 2 * f.ey + f.arc / 2]
    Loader {
        anchors.fill: parent
        active: f.richWanted
        sourceComponent: richFrame
    }
    Component {
        id: richFrame
        Item {
            id: rich
            visible: f.litIn > 0.003 || f.litOut > 0.003
            layer.enabled: true
            layer.effect: Holdout {
                occ: f.occ
            }

            Repeater {
                model: 4
                Corner {
                    required property int index
                    quarter: index
                    scaleBy: f.compact ? 0.72 : 1
                    bloom: f.litOf(f.cornerU[index]) * f.laidOf(f.cornerU[index])
                    at: Qt.point(index === 0 || index === 3 ? f.margin - f.cameOut : f.margin + f.gw + f.cameOut,
                                 index < 2 ? f.margin - f.cameOut : f.margin + f.gh + f.cameOut)
                    light: f.light
                    glow: f.cornerGlow(at.x, at.y)
                }
            }

            Repeater {
                model: f.dark ? 0 : 8
                Pearl {
                    required property int index
                    readonly property int corner: Math.floor(index / 2)
                    readonly property bool along: index % 2 === 0
                    readonly property real reach: (f.compact ? 0.72 : 1) * 70
                    readonly property real cx: corner === 0 || corner === 3 ? f.margin - f.cameOut : f.margin + f.gw + f.cameOut
                    readonly property real cy: corner < 2 ? f.margin - f.cameOut : f.margin + f.gh + f.cameOut
                    readonly property real sx: corner === 0 || corner === 3 ? 1 : -1
                    readonly property real sy: corner < 2 ? 1 : -1
                    width: 8
                    height: 8
                    x: (along ? cx + sx * reach : cx) - 4
                    y: (along ? cy : cy + sy * reach) - 4
                    opacity: f.litOf(f.cornerU[corner]) * f.laidOf(f.cornerU[corner])
                }
            }

            Crest {
                visible: !f.compact && opacity > 0.003
                opacity: f.litOf(f.ex) * f.laidOf(f.ex)
                scale: 0.7 + 0.3 * opacity
                app: appInfo
                x: f.margin + f.gw / 2 - width / 2
                y: f.margin - f.cameOut - height / 2
                light: Qt.point((f.light.x - x) / width, (f.light.y - y) / height)
                glow: f.cornerGlow(x + width / 2, y + height / 2)
            }

            Plate {
                readonly property real u: Math.max(0, x + width / 2 - f.margin - 8)
                opacity: f.litOf(u) * f.laidOf(u)
                x: f.margin + (f.compact ? 48 : 64)
                y: f.margin - f.cameOut - height / 2
                app: appInfo.name
                title: f.win ? f.win.title : ""
                maxWidth: Math.max(80, f.compact ? f.gw - 128 : f.gw / 2 - 64 - 26 - 28)
                light: Qt.point(f.light.x - x, f.light.y - y)
            }
        }
    }

    Component.onCompleted: {
        f.place();
        f.litIn = f.lit ? 1 : 0;
        f.litOut = f.litIn;
        f.litTarget = f.lit;
        f.richWanted = f.lit;
        f.lift = f.floating ? 1 : 0;
    }
}
