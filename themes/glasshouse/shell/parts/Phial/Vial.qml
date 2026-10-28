import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.kit

Item {
    id: v

    required property var host
    required property real u
    signal done()

    readonly property alias hit: hit
    readonly property bool mic: v.host.kind === "mic"
    readonly property real rad: 24 * v.u
    readonly property real tall: 150 * v.u
    readonly property real capH: 34 * v.u
    readonly property real wallW: 2.1 * v.u
    readonly property real homeX: v.width / 2
    readonly property real homeY: v.height - 46 * v.u
    readonly property real yb: v.wallW
    readonly property real yt: v.tall - 0.3 * v.rad
    readonly property real span: v.yt - v.yb

    property real form: 0
    property real gone: 0
    property bool leaving: false
    property bool poured: false
    property real lv: 0
    property real lvV: 0
    property real lvA: 0
    property real s1: 0
    property real s1V: 0
    property real s2: 0
    property real s2V: 0
    property real tilt: 0
    property real tiltV: 0
    property real ox: 0
    property real oxV: 0
    property real oxA: 0
    property real oy: 0
    property real oyV: 0
    property real ripple: 0
    property real clock: 0
    property real stillness: v.host.muted ? 1 : 0
    Behavior on stillness {
        NumberAnimation { duration: 700; easing.type: Easing.InOutQuad }
    }
    readonly property real boil: Math.max(0, Math.min(1, (v.host.level - 1) / 0.5)) * (1 - v.stillness)
    property var blobs: []
    property var rings: []

    property bool dragging: false
    property bool hovered: false
    readonly property bool held: v.dragging || v.hovered
    property real dragLevel: 0
    property real pressX: 0
    property real pressY: 0
    property real pressLevel: 0
    property bool moved: false
    property real pourAt: 0
    property real pourLevel: 0
    property real sloshAt: 0
    property real fillAt: 0
    property real setAt: 0
    property bool landing: false
    property real seenLevel: v.host.level
    property bool seenMuted: v.host.muted
    property string seenKind: v.host.kind

    readonly property real target: v.leaving ? 0 : !v.poured ? 0 : v.dragging ? v.dragLevel : v.host.level
    readonly property color deep: v.mic ? (Theme.dark ? "#1c0638" : "#4a1a9a") : (Theme.dark ? "#030c3a" : "#0f3aa8")
    readonly property color bright: v.mic ? (Theme.dark ? "#9b4dff" : "#c38bff") : (Theme.dark ? "#2f72ff" : "#4fb4ff")

    function ease(x: real): real {
        return 1 - Math.pow(1 - Math.max(0, Math.min(1, x)), 3);
    }
    function back(x: real): real {
        const c = 1.9;
        const t = Math.max(0, Math.min(1, x)) - 1;
        return 1 + (c + 1) * t * t * t + c * t * t;
    }
    function rand(a: real, b: real): real {
        return a + Math.random() * (b - a);
    }
    function halfAt(y: real): real {
        return (y > v.tall - 1.2 * v.rad ? v.rad * 0.56 : v.rad) - v.wallW;
    }
    function surfaceY(): real {
        return v.yb + 0.5 * v.u + Math.max(0, Math.min(1, v.lv)) * (v.span - 0.5 * v.u);
    }
    function spawn(n: int, scale: real, fast: bool): void {
        const out = v.blobs.slice();
        for (let i = 0; i < n && out.length < 12; i++) {
            const r = v.rand(1.5, 3.6) * v.u * scale;
            out.push({ x: v.rand(-1, 1) * (v.rad - v.wallW - r) * 0.8, y: v.yb + r + v.rand(0, 4) * v.u, r: r, vy: fast ? v.rand(90, 160) * v.u : v.rand(0, 20) * v.u, ph: v.rand(0, 6.28), age: 0 });
        }
        v.blobs = out;
    }
    function sound(name: string, gain: real): void {
        Sfx.play(name, gain);
    }
    function pitch(level: real, steps: int): int {
        return 1 + Math.round(Math.max(0, Math.min(1, level)) * (steps - 1));
    }

    function step(dt: real): void {
        dt = Math.min(dt, 1 / 30);
        v.clock += dt;
        const k = v.dragging ? 160 : 70;
        const a = k * (v.target - v.lv) - 2 * Math.sqrt(k) * 0.62 * v.lvV;
        v.lvV += a * dt;
        v.lv += v.lvV * dt;
        v.lvA = a;

        const kx = 140;
        const oxT = v.dragging ? Math.max(-64 * v.u, Math.min(64 * v.u, (hitArea.mouseX - v.pressX) * 0.7)) : 0;
        const ax = kx * (oxT - v.ox) - 2 * Math.sqrt(kx) * 0.8 * v.oxV;
        v.oxV += ax * dt;
        v.ox += v.oxV * dt;
        v.oxA = ax;

        const ky = v.dragging ? 160 : 260;
        const oyT = v.dragging ? -10 * v.u : v.leaving ? 34 * v.u * v.gone * v.gone : 0;
        const ay = ky * (oyT - v.oy) - 2 * Math.sqrt(ky) * (v.dragging ? 0.8 : 0.22) * v.oyV;
        const wasAbove = v.oy < -0.6 * v.u;
        v.oyV += ay * dt;
        v.oy += v.oyV * dt;
        if (v.landing && wasAbove && v.oy >= -0.6 * v.u && v.oyV > 0) {
            v.landing = false;
            v.sound("phial-clink", Math.min(1, 0.45 + Math.abs(v.oyV) / (300 * v.u)));
            v.spawn(2, 0.8, false);
            v.ripple = Math.max(v.ripple, 0.9);
        }

        const kt = 55;
        const tT = v.dragging ? Math.max(-0.42, Math.min(0.42, v.oxV / (v.u * 900))) : 0;
        const at = kt * (tT - v.tilt) - 2 * Math.sqrt(kt) * 0.32 * v.tiltV;
        v.tiltV += at * dt;
        v.tilt += v.tiltV * dt;

        const damp = 0.07 + 0.5 * v.stillness;
        const w1 = 2 * Math.PI * 1.55;
        const eq1 = -v.rad * Math.tan(v.tilt) - v.rad * ax / (2600 * v.u);
        const a1 = w1 * w1 * (eq1 - v.s1) - 2 * damp * w1 * v.s1V;
        v.s1V += a1 * dt;
        v.s1 += v.s1V * dt;
        const w2 = 2 * Math.PI * 2.4;
        const a2 = -w2 * w2 * v.s2 - 2 * damp * w2 * v.s2V + v.lvA * v.tall * 0.0035;
        v.s2V += a2 * dt;
        v.s2 += v.s2V * dt;
        v.s1 = Math.max(-v.rad, Math.min(v.rad, v.s1));
        v.s2 = Math.max(-0.4 * v.rad, Math.min(0.4 * v.rad, v.s2));
        v.ripple *= Math.exp(-dt * 2.2);

        if (v.dragging && Math.abs(v.s1V) > 120 * v.u && v.clock - v.sloshAt > 0.28) {
            v.sloshAt = v.clock;
            v.sound("phial-slosh", Math.min(1, Math.abs(v.s1V) / (400 * v.u)));
        }

        const ys = v.surfaceY();
        const out = [];
        const rings = v.rings.map(r => Object.assign({}, r, { age: r.age + dt / 0.7 })).filter(r => r.age < 1);
        for (const b0 of v.blobs) {
            const b = Object.assign({}, b0);
            b.age += dt;
            if (v.stillness > 0.5) {
                b.vy += (-420 * v.u - b.vy * 2) * dt;
                b.y = Math.max(v.yb + b.r * 0.75, b.y + b.vy * dt);
                if (b.y <= v.yb + b.r * 0.75)
                    b.vy = 0;
            } else {
                const lift = 230 * v.u * (b.r / (3 * v.u)) + 60 * v.u;
                b.vy += (lift - 3.2 * b.vy) * dt;
                b.y += b.vy * dt;
                b.x += Math.sin(b.age * 5.5 + b.ph) * 16 * v.u * dt - v.oxA * 0.00012 * dt * 60;
            }
            const half = v.halfAt(b.y) - b.r;
            b.x = Math.max(-half, Math.min(half, b.x));
            b.ph += dt * 3;
            const top = ys + v.s1 * (b.x / v.halfAt(ys));
            if (v.stillness <= 0.5 && b.y + b.r * 0.4 > top) {
                if (rings.length < 4)
                    rings.push({ x: b.x, age: 0, s: Math.min(1.6, b.r / v.u * 0.38) });
                continue;
            }
            if (v.lv < 0.015 && v.stillness <= 0.5)
                continue;
            out.push(b);
        }
        for (let i = 0; i < out.length; i++) {
            for (let j = i + 1; j < out.length; j++) {
                const p = out[i], q = out[j];
                if (!p || !q)
                    continue;
                if (Math.hypot(p.x - q.x, p.y - q.y) < (p.r + q.r) * 0.62 && v.stillness <= 0.5) {
                    const vp = p.r * p.r * p.r, vq = q.r * q.r * q.r;
                    const w = vp / (vp + vq);
                    out[i] = { x: p.x * w + q.x * (1 - w), y: p.y * w + q.y * (1 - w), r: Math.min(6.5 * v.u, Math.cbrt(vp + vq)), vy: p.vy * w + q.vy * (1 - w), ph: p.ph, age: Math.min(p.age, q.age) };
                    out[j] = null;
                }
            }
        }
        const merged = out.filter(b => !!b);
        const split = [];
        for (const b of merged) {
            if (b.r > 4.6 * v.u && v.stillness <= 0.5 && Math.random() < dt * 1.4 && merged.length + split.length < 12) {
                const r = b.r / 1.26;
                split.push(Object.assign({}, b, { x: b.x - r * 0.55, r: r, ph: b.ph + 1 }));
                split.push(Object.assign({}, b, { x: b.x + r * 0.55, r: r, vy: b.vy * 1.15, ph: b.ph + 2.5 }));
            } else {
                split.push(b);
            }
        }
        v.blobs = split;
        v.rings = rings;
        if (!v.leaving && v.stillness < 0.5 && v.lv > 0.04 && Math.random() < dt * (0.7 + 22 * v.boil))
            v.spawn(1, v.boil > 0 ? 0.7 : 0.75, v.boil > 0);

        fluid.b0 = v.packBlob(0);
        fluid.b1 = v.packBlob(1);
        fluid.b2 = v.packBlob(2);
        fluid.b3 = v.packBlob(3);
        fluid.b4 = v.packBlob(4);
        fluid.b5 = v.packBlob(5);
        fluid.b6 = v.packBlob(6);
        fluid.b7 = v.packBlob(7);
        fluid.b8 = v.packBlob(8);
        fluid.b9 = v.packBlob(9);
        fluid.b10 = v.packBlob(10);
        fluid.b11 = v.packBlob(11);
        fluid.r0 = v.packRing(0);
        fluid.r1 = v.packRing(1);
        fluid.r2 = v.packRing(2);
        fluid.r3 = v.packRing(3);
    }
    function packBlob(i: int): vector4d {
        const b = v.blobs[i];
        return b ? Qt.vector4d(b.x, b.y, b.r, b.ph) : Qt.vector4d(0, 0, 0, 0);
    }
    function packRing(i: int): vector4d {
        const r = v.rings[i];
        return r ? Qt.vector4d(r.x, r.age, r.s, 0) : Qt.vector4d(0, 0, 0, 0);
    }

    function stay(): void {
        if (!v.leaving)
            return;
        v.leaving = false;
        leave.stop();
        unleave.duration = Math.max(60, 300 * v.gone);
        unleave.start();
    }
    function poke(): void {
        const level = v.host.level, muted = v.host.muted, kind = v.host.kind;
        v.stay();
        if (kind !== v.seenKind) {
            v.seenKind = kind;
            v.sound("phial-fill-" + v.pitch(level, 12), 0.8);
            v.spawn(4, 1, false);
        } else if (muted !== v.seenMuted) {
            v.sound(muted ? "phial-mute" : "phial-unmute", 0.9);
            v.ripple = 1;
        } else if (Math.abs(level - v.seenLevel) > 0.001 && !v.dragging) {
            const d = level - v.seenLevel;
            if (v.clock - v.fillAt > 0.09) {
                v.fillAt = v.clock;
                v.sound(level > 1.001 ? "phial-boil" : "phial-fill-" + v.pitch(level, 12), d > 0 ? 0.85 : 0.6);
            }
            v.spawn(Math.max(1, Math.min(6, Math.round(Math.abs(d) * 60))), Math.abs(d) > 0.08 ? 1.25 : 1, false);
            v.ripple = Math.min(1.4, v.ripple + 0.6);
        }
        v.seenLevel = level;
        v.seenMuted = muted;
        idle.restart();
    }

    NumberAnimation {
        id: enter
        target: v
        property: "form"
        from: 0
        to: 1
        duration: 350
        running: true
    }
    NumberAnimation {
        id: leave
        target: v
        property: "gone"
        to: 1
        duration: 500
        onFinished: v.done()
    }
    NumberAnimation {
        id: unleave
        target: v
        property: "gone"
        to: 0
    }
    onFormChanged: if (v.form > 0.55 && !v.poured) {
        v.poured = true;
        v.spawn(5, 1.1, false);
    }
    Timer {
        id: idle
        interval: 1500
        running: true
        onTriggered: if (!v.held) {
            v.leaving = true;
            unleave.stop();
            v.sound("phial-fade", 0.8);
            leave.start();
        }
    }
    onHeldChanged: {
        if (v.held)
            v.stay();
        idle.restart();
    }

    Connections {
        target: v.host
        function onPoked(): void {
            v.poke();
        }
    }

    FrameAnimation {
        running: v.visible
        onTriggered: v.step(frameTime)
    }

    ScreencopyView {
        id: cap
        x: -(v.host.screenObj.width - v.width) / 2
        y: -(v.host.screenObj.height - v.height)
        width: v.host.screenObj.width
        height: v.host.screenObj.height
        captureSource: v.host.screenObj
        live: false
        paintCursor: false
    }
    ShaderEffectSource {
        id: behind
        sourceItem: cap
        sourceRect: Qt.rect(-cap.x, -cap.y, v.width, v.height)
        hideSource: true
    }

    ShaderEffect {
        id: fluid
        anchors.fill: parent
        property size size: Qt.size(v.width, v.height)
        property vector4d vial: Qt.vector4d(v.homeX + v.ox, v.homeY + v.oy, v.rad, v.tall)
        property real capH: v.capH
        property real tilt: v.tilt
        property real lift: v.form < 1 ? 46 * v.u * (1 - v.back((v.form - 0.42) / 0.36)) : 30 * v.u * v.ease(v.gone * 1.4)
        property real capA: Math.max(0, Math.min(1, (v.form - 0.38) / 0.16)) * (1 - v.ease(v.gone * 1.3))
        property real form: v.form
        property real gone: v.gone
        property real level: v.lv
        property vector4d wave: Qt.vector4d(v.s1, v.s2, v.clock * 3, v.ripple * 1.2)
        property real still: v.stillness
        property real boil: v.boil
        property real time: v.clock
        property real hasBack: cap.hasContent ? 1 : 0
        property real unit: v.u
        property real dark: Theme.dark ? 1 : 0
        property color deep: v.deep
        property color bright: v.bright
        property vector4d b0
        property vector4d b1
        property vector4d b2
        property vector4d b3
        property vector4d b4
        property vector4d b5
        property vector4d b6
        property vector4d b7
        property vector4d b8
        property vector4d b9
        property vector4d b10
        property vector4d b11
        property vector4d r0
        property vector4d r1
        property vector4d r2
        property vector4d r3
        property variant back: behind
        fragmentShader: Qt.resolvedUrl("../../shaders/phial.frag.qsb")
    }

    Item {
        id: roundel
        readonly property real d: 50 * v.u
        width: roundel.d
        height: roundel.d
        x: v.homeX - 92 * v.u - roundel.d / 2
        y: v.homeY - 62 * v.u - roundel.d / 2
        opacity: v.ease((v.form - 0.2) / 0.5) * (1 - v.ease(v.gone * 1.6))
        scale: (0.7 + 0.3 * v.back((v.form - 0.2) / 0.6)) * (press.pressed ? 0.94 : 1)
        Piece {
            anchors.fill: parent
            name: "sanctum-medal"
            power: 0.6
            ambient: press.containsMouse ? 0.85 : 0.62
            glow: 0.3 + 0.5 * (1 - v.stillness)
            tint: v.stillness > 0.5 ? "#b8b8c4" : Qt.tint("white", Qt.alpha(v.bright, 0.35))
        }
        Gilt {
            anchors.fill: parent
            src: Theme.a("sanctum-medal-gilt.png")
            lx: 0.25
            ly: -0.5
        }
        Text {
            anchors.centerIn: parent
            text: v.mic ? (v.host.muted ? "\u{f036d}" : "\u{f036c}") : v.host.muted ? "\u{f075f}" : v.host.level > 0.66 ? "\u{f057e}" : v.host.level > 0.33 ? "\u{f0580}" : "\u{f057f}"
            font.family: Theme.glyphs
            font.pixelSize: 21 * v.u
            color: v.host.muted ? Theme.dim : (Theme.dark ? Theme.rare : Theme.sun)
        }
        MouseArea {
            id: press
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: v.host.toggleMute()
        }
    }

    Item {
        id: figure
        x: v.homeX + 46 * v.u
        y: v.homeY - 62 * v.u - digits.height / 2
        width: digits.width
        height: digits.height
        opacity: v.ease((v.form - 0.35) / 0.5) * (1 - v.ease(v.gone * 1.6))
        property real shownPct: Math.round(Math.max(0, v.dragging ? v.dragLevel : v.host.level) * 100)
        Behavior on shownPct {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Text {
            x: 1.5 * v.u
            y: 2 * v.u
            text: digits.text
            font: digits.font
            color: "#000000"
            opacity: 0.45
        }
        Text {
            id: digits
            text: Math.round(figure.shownPct)
            font.family: Theme.numerals
            font.pixelSize: 42 * v.u
            color: "white"
        }
        ShaderEffectSource {
            id: digitSrc
            sourceItem: digits
            hideSource: true
            visible: false
        }
        Gilt {
            anchors.fill: parent
            heightMap: digitSrc
            lx: 0.2
            ly: -0.6
            depth: 3.4
            sweep: (v.clock * 0.35) % 2.4 - 0.7
            metal: v.host.muted ? 0.3 : 1.0
            base: v.host.muted ? "#8d8a94" : "#c99a4e"
        }
        Text {
            anchors.top: parent.bottom
            anchors.topMargin: -4 * v.u
            x: 2 * v.u
            text: v.mic ? "VOICE" : "SOUND"
            font.family: Theme.caps
            font.pixelSize: 9.5 * v.u
            font.letterSpacing: Theme.capsTracking * v.u
            color: Theme.dark ? Theme.rare : Theme.sun
            opacity: 0.8
        }
    }

    Item {
        id: hit
        x: v.homeX - 130 * v.u
        y: v.homeY - v.tall - v.capH - 16 * v.u
        width: 280 * v.u
        height: v.tall + v.capH + 30 * v.u
        HoverHandler {
            onHoveredChanged: v.hovered = hovered
        }
        MouseArea {
            id: hitArea
            x: v.homeX - hit.x - v.rad - 14 * v.u
            y: 0
            width: 2 * v.rad + 28 * v.u
            height: parent.height
            cursorShape: v.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            onPressed: mouse => {
                v.dragging = true;
                v.pressX = mouse.x;
                v.pressY = mouse.y;
                v.pressLevel = v.host.level;
                v.moved = false;
                v.dragLevel = v.pressLevel;
                v.pourLevel = v.pressLevel;
                v.seenLevel = v.host.level;
                v.landing = false;
                v.sound("phial-lift", 0.8);
                idle.stop();
            }
            onPositionChanged: mouse => {
                if (!v.dragging)
                    return;
                const lvl = Math.max(0, Math.min(Math.max(1, v.pressLevel), v.pressLevel + (v.pressY - mouse.y) / v.span));
                v.moved = v.moved || Math.abs(mouse.y - v.pressY) > 2 * v.u;
                v.dragLevel = lvl;
                if (v.moved && Math.abs(lvl - v.host.level) > 0.004 && v.clock - v.setAt > 0.03) {
                    v.setAt = v.clock;
                    v.host.setLevel(lvl);
                }
                if (Math.abs(lvl - v.pourLevel) > 0.025 && v.clock - v.pourAt > 0.075) {
                    v.sound("phial-pour-" + v.pitch(lvl, 8), Math.min(1, 0.5 + Math.abs(lvl - v.pourLevel) * 6));
                    if (lvl > v.pourLevel)
                        v.spawn(1, 0.8, false);
                    v.pourLevel = lvl;
                    v.pourAt = v.clock;
                }
            }
            onReleased: {
                if (v.moved) {
                    v.host.setLevel(v.dragLevel);
                    v.seenLevel = v.dragLevel;
                }
                v.dragging = false;
                v.landing = true;
                idle.restart();
            }
            onWheel: wheel => {
                const d = wheel.angleDelta.y > 0 ? 0.02 : wheel.angleDelta.y < 0 ? -0.02 : 0;
                if (d !== 0 && !(d > 0 && v.host.level >= 1))
                    v.host.setLevel(Math.max(0, Math.min(Math.max(1, v.host.level), Math.round((v.host.level + d) * 50) / 50)));
            }
        }
    }

    Component.onCompleted: {
        v.sound("phial-rise", 0.9);
        v.seenLevel = v.host.level;
    }
}
