import QtQuick
import qs.core

Item {
    id: shards

    required property string output
    property point impact: Qt.point(width / 2, height / 2)
    readonly property real tau: Slumber.handAt > 0 ? (Slumber.now - Slumber.handAt) / 1000 - Slumber.holdShards : -1
    readonly property bool broken: tau >= 0
    readonly property real k: Screens.fit(width, height)
    readonly property bool ready: body.ready && pieces.length > 0 && cut.count === pieces.length
    property var pieces: []

    function rnd(): real {
        shards.seed = (shards.seed * 16807) % 2147483647;
        return shards.seed / 2147483647;
    }
    property double seed: 1

    function clip(poly: var): var {
        const W = shards.width, H = shards.height;
        let out = poly;
        for (let e = 0; e < 4; e++) {
            const inp = out;
            out = [];
            if (!inp.length)
                break;
            const ins = p => e === 0 ? p[0] >= 0 : e === 1 ? p[0] <= W : e === 2 ? p[1] >= 0 : p[1] <= H;
            const cut = (a, b) => {
                if (e < 2) {
                    const x = e === 0 ? 0 : W;
                    const t = (x - a[0]) / (b[0] - a[0]);
                    return [x, a[1] + (b[1] - a[1]) * t];
                }
                const y = e === 2 ? 0 : H;
                const t = (y - a[1]) / (b[1] - a[1]);
                return [a[0] + (b[0] - a[0]) * t, y];
            };
            for (let i = 0; i < inp.length; i++) {
                const cur = inp[i], prev = inp[(i + inp.length - 1) % inp.length];
                if (ins(cur)) {
                    if (!ins(prev))
                        out.push(cut(prev, cur));
                    out.push(cur);
                } else if (ins(prev)) {
                    out.push(cut(prev, cur));
                }
            }
        }
        return out;
    }

    function area(poly: var): real {
        let a = 0;
        for (let i = 0; i < poly.length; i++) {
            const p = poly[i], q = poly[(i + 1) % poly.length];
            a += p[0] * q[1] - q[0] * p[1];
        }
        return a / 2;
    }

    function convex(poly: var): bool {
        let sign = 0;
        for (let i = 0; i < poly.length; i++) {
            const a = poly[i], b = poly[(i + 1) % poly.length], c = poly[(i + 2) % poly.length];
            const z = (b[0] - a[0]) * (c[1] - b[1]) - (b[1] - a[1]) * (c[0] - b[0]);
            if (Math.abs(z) < 1e-6)
                continue;
            if (sign === 0)
                sign = Math.sign(z);
            else if (Math.sign(z) !== sign)
                return false;
        }
        return true;
    }

    function build(): void {
        const W = shards.width, H = shards.height, k = shards.k;
        if (W < 2 || H < 2)
            return;
        const ix = shards.impact.x, iy = shards.impact.y;
        shards.seed = 97 + Math.round(ix * 3 + iy * 7) % 100000;
        const N = 15;
        const base = shards.rnd() * Math.PI * 2;
        const ang = [];
        for (let i = 0; i < N; i++)
            ang.push(base + (i + (shards.rnd() - 0.5) * 0.7) * 2 * Math.PI / N);
        ang.sort((x, y) => x - y);
        const rings = [30, 80, 150, 250, 380, 560, 800, 1120, 1560, 2200].map(r => r * k);
        const R = ang.map(() => rings.map((r, j) => r * (j === 0 ? 0.7 + 0.6 * shards.rnd() : 0.8 + 0.4 * shards.rnd())));
        const P = (i, j) => {
            const a = i >= N ? ang[i - N] + 2 * Math.PI : ang[i];
            const r = R[i % N][j];
            return [ix + Math.cos(a) * r, iy + Math.sin(a) * r];
        };
        const lerp = (u, v, t) => [u[0] + (v[0] - u[0]) * t, u[1] + (v[1] - u[1]) * t];
        const cells = [];
        for (let i = 0; i < N; i++) {
            cells.push([[ix, iy], P(i, 0), P(i + 1, 0)]);
            const cut = [0];
            for (let j = 1; j < rings.length - 1; j++)
                if (shards.rnd() > 0.32)
                    cut.push(j);
            cut.push(rings.length - 1);
            for (let c = 0; c + 1 < cut.length; c++) {
                const j0 = cut[c], j1 = cut[c + 1];
                const q = [P(i, j0), P(i + 1, j0), P(i + 1, j1), P(i, j1)];
                const roll = shards.rnd();
                if (!shards.convex(q) || (j0 >= 3 && roll < 0.42)) {
                    if (shards.rnd() < 0.5) {
                        cells.push([q[0], q[1], q[2]]);
                        cells.push([q[0], q[2], q[3]]);
                    } else {
                        cells.push([q[0], q[1], q[3]]);
                        cells.push([q[1], q[2], q[3]]);
                    }
                } else if (j0 >= 2 && roll < 0.7) {
                    const t0 = 0.35 + 0.3 * shards.rnd(), t1 = Math.max(0.2, Math.min(0.8, t0 + (shards.rnd() - 0.5) * 0.3));
                    const m0 = lerp(q[0], q[1], t0), m1 = lerp(q[3], q[2], t1);
                    cells.push([q[0], m0, m1, q[3]]);
                    cells.push([m0, q[1], q[2], m1]);
                } else {
                    cells.push(q);
                }
            }
        }
        const maxD = Math.max(Math.hypot(ix, iy), Math.hypot(W - ix, iy), Math.hypot(ix, H - iy), Math.hypot(W - ix, H - iy));
        const list = [];
        for (const cell of cells) {
            let poly = shards.clip(cell);
            if (poly.length < 3)
                continue;
            let a = shards.area(poly);
            if (Math.abs(a) < 4)
                continue;
            if (a < 0)
                poly = poly.reverse();
            if (poly.length > 8)
                poly = poly.slice(0, 8);
            const xs = poly.map(p => p[0]), ys = poly.map(p => p[1]);
            const bx = Math.max(0, Math.floor(Math.min(...xs)) - 1), by = Math.max(0, Math.floor(Math.min(...ys)) - 1);
            const bw = Math.min(W, Math.ceil(Math.max(...xs)) + 1) - bx, bh = Math.min(H, Math.ceil(Math.max(...ys)) + 1) - by;
            const cx = xs.reduce((s, v) => s + v, 0) / xs.length, cy = ys.reduce((s, v) => s + v, 0) / ys.length;
            const d = Math.hypot(cx - ix, cy - iy);
            const out = Math.atan2(cy - iy, cx - ix) + (shards.rnd() - 0.5) * 0.5;
            const loc = poly.map(p => [p[0] - bx, p[1] - by]);
            while (loc.length < 8)
                loc.push(loc[loc.length - 1]);
            const big = Math.sqrt(Math.abs(a)) / (180 * k);
            list.push({
                bx: bx, by: by, bw: Math.max(1, bw), bh: Math.max(1, bh), n: poly.length, v: loc,
                cx: cx - bx, cy: cy - by, near: d / maxD,
                start: 0.2 + 0.3 * (d / maxD) + 0.05 * shards.rnd(),
                dur: 0.85 + 0.35 * shards.rnd(),
                dx: Math.cos(out), dy: Math.sin(out),
                dist: (150 + 330 * shards.rnd()) * k * (1.1 - 0.4 * Math.min(1, big)),
                grav: (650 + 500 * shards.rnd()) * k,
                ax: shards.rnd() - 0.5, ay: shards.rnd() - 0.5, az: (shards.rnd() - 0.5) * 0.4,
                spin: (shards.rnd() < 0.5 ? -1 : 1) * (70 + 160 * shards.rnd()) / (0.7 + Math.min(1.5, big)),
                grow: 0.12 + 0.18 * shards.rnd(),
                glint: shards.rnd()
            });
        }
        shards.pieces = list;
    }

    onWidthChanged: Qt.callLater(shards.build)
    onHeightChanged: Qt.callLater(shards.build)
    Component.onCompleted: shards.build()

    LockBody {
        id: body
        z: 1
        anchors.fill: parent
        output: shards.output
        frozen: true
    }
    ShaderEffectSource {
        id: snapshot
        width: 2
        height: 2
        opacity: 0.01
        sourceItem: body
        hideSource: shards.broken
        live: true
    }

    Repeater {
        id: cut
        model: shards.pieces

        ShaderEffect {
            id: piece
            required property var modelData
            readonly property var m: modelData
            readonly property real lit: Slumber.clamp((shards.tau - 0.12 * m.near + 0.01) / 0.03, 0, 1)
            readonly property real u: Slumber.clamp((shards.tau - m.start) / m.dur, 0, 1)
            readonly property real fly: Math.max(0, shards.tau - m.start)
            readonly property real e: 1 - (1 - u) * (1 - u)

            x: m.bx
            y: m.by
            width: m.bw
            height: m.bh
            opacity: 1 - Slumber.clamp((u - 0.5) / 0.5, 0, 1)
            visible: opacity > 0.002

            property variant picture: snapshot
            property vector2d box: Qt.vector2d(width, height)
            property vector2d origin: Qt.vector2d(m.bx, m.by)
            property vector2d view: Qt.vector2d(shards.width, shards.height)
            property vector4d v01: Qt.vector4d(m.v[0][0], m.v[0][1], m.v[1][0], m.v[1][1])
            property vector4d v23: Qt.vector4d(m.v[2][0], m.v[2][1], m.v[3][0], m.v[3][1])
            property vector4d v45: Qt.vector4d(m.v[4][0], m.v[4][1], m.v[5][0], m.v[5][1])
            property vector4d v67: Qt.vector4d(m.v[6][0], m.v[6][1], m.v[7][0], m.v[7][1])
            property real count: m.n
            property real heat: lit * (1 - Slumber.clamp(u * 1.6, 0, 1)) * (1 - 0.62 * m.near)
            property real rim: u > 0 ? (1 - u) * 0.9 : 0
            property real glint: -0.3 + 1.6 * Slumber.clamp((u - m.glint * 0.3) / 0.6, 0, 1)
            property real flash: shards.tau > 0.1 && shards.tau < 0.24 ? (1 - Math.abs(shards.tau - 0.17) / 0.07) * (1 - m.near) * 0.6 : 0
            property real seam: Theme.dark ? 0.0 : 0.5
            property color hot: Theme.dark ? "#ffe9c8" : "#fff6e0"
            property color tint: Theme.dark ? "#9fb6ff" : "#ffd0ea"
            fragmentShader: Qt.resolvedUrl("../../shaders/lock-shard.frag.qsb")

            transform: [
                Rotation {
                    origin.x: piece.m.cx
                    origin.y: piece.m.cy
                    axis.x: piece.m.ax
                    axis.y: piece.m.ay
                    axis.z: piece.m.az
                    angle: piece.m.spin * piece.e
                },
                Scale {
                    origin.x: piece.m.cx
                    origin.y: piece.m.cy
                    xScale: 1 + piece.m.grow * piece.e
                    yScale: 1 + piece.m.grow * piece.e
                },
                Translate {
                    x: piece.m.dx * piece.m.dist * piece.e
                    y: piece.m.dy * piece.m.dist * piece.e + 0.5 * piece.m.grav * piece.fly * piece.fly
                }
            ]
        }
    }
}
