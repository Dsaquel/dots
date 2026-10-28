import QtQuick
import QtMultimedia
import qs.core

Item {
    id: fig

    required property var her
    required property string slot
    property point origin: Qt.point(0, 0)
    property bool framed: false
    readonly property alias output: film
    readonly property var meta: fig.her.meta
    readonly property bool video: fig.her.video
    readonly property bool ready: !!fig.meta && (fig.video ? fig.framed : atlas.status === Image.Ready)
    readonly property real s: fig.her.scaleBy
    readonly property real fw: fig.meta ? fig.meta.w * fig.s : 0
    readonly property real fh: fig.meta ? fig.meta.h * fig.s : 0
    readonly property real seatX: fig.meta ? (fig.her.flip ? fig.meta.w - fig.meta.seat[0] : fig.meta.seat[0]) * fig.s : 0
    readonly property real seatY: fig.meta ? fig.meta.seat[1] * fig.s : 0
    readonly property real pad: 26
    readonly property real hx: fig.her.ax + fig.her.slideX - fig.origin.x
    readonly property real hy: fig.her.ay + fig.her.slideY - fig.her.lift - fig.origin.y
    readonly property int gutter: fig.meta && fig.meta.gutter ? fig.meta.gutter : 0
    readonly property int cols: fig.meta && fig.meta.cols ? fig.meta.cols : 1
    readonly property int rows: fig.meta ? Math.ceil(fig.meta.count / fig.cols) : 1
    readonly property real cellW: fig.meta ? fig.meta.w + 2 * fig.gutter : 1
    readonly property real cellH: fig.meta ? fig.meta.h + 2 * fig.gutter : 1
    readonly property var hits: {
        const out = [];
        for (const r of (fig.meta && fig.meta.hit ? fig.meta.hit : []).slice(0, 12)) {
            const x = fig.her.flip ? fig.meta.w - r[0] - r[2] : r[0];
            out.push(Qt.rect(body.x + fig.pad + x * fig.s, body.y + fig.pad + r[1] * fig.s, r[2] * fig.s, r[3] * fig.s));
        }
        return out;
    }

    function local(r: var, ox: real, oy: real): vector4d {
        return r ? Qt.vector4d(r.x - fig.origin.x - ox, r.y - fig.origin.y - oy, r.w, r.h) : Qt.vector4d(0, 0, 0, 0);
    }

    Component.onCompleted: fig.her.reelIn(fig.slot, fig)
    Component.onDestruction: fig.her.reelOut(fig.slot, fig)

    VideoOutput {
        id: film
        width: fig.video && fig.meta.vw ? fig.meta.vw : 0
        height: fig.video && fig.meta.vh ? fig.meta.vh : 0
        fillMode: VideoOutput.Stretch
        endOfStreamPolicy: VideoOutput.KeepLastFrame
    }
    ShaderEffectSource {
        id: filmTex
        width: 0
        height: 0
        sourceItem: fig.video ? film : null
        hideSource: true
    }
    Connections {
        target: film.videoSink
        function onVideoFrameChanged(): void {
            fig.framed = true;
        }
    }

    Image {
        id: atlas
        visible: false
        source: fig.video ? "" : fig.her.atlasUrl
        asynchronous: true
        cache: true
        smooth: true
        mipmap: false
        sourceSize: fig.s === 1 || !fig.meta ? undefined : Qt.size(Math.round(fig.cols * fig.cellW * fig.s), Math.round(fig.rows * fig.cellH * fig.s))
    }

    ShaderEffect {
        id: glowFx
        readonly property real d: Math.max(120, fig.fw * 1.5)
        visible: fig.her.glow > 0.01
        width: d
        height: d * 0.62
        x: fig.hx - width / 2 + (fig.her.flip ? -1 : 1) * fig.fw * 0.06
        y: fig.hy - height * 0.42
        opacity: fig.her.glow * fig.her.alpha
        property color color: fig.her.light
        property real core: 0.16
        property real intensity: 0.55
        fragmentShader: Qt.resolvedUrl("../../shaders/glow.frag.qsb")
    }

    ShaderEffect {
        id: body
        visible: fig.ready && fig.her.alpha > 0.003
        readonly property bool still: fig.her.mode === "seated" && fig.her.lift === 0 && fig.her.slideX === 0 && fig.her.slideY === 0
        readonly property real bx: fig.hx - fig.seatX - fig.pad
        readonly property real by: fig.hy - fig.seatY - fig.pad
        x: still ? Math.round(bx) : bx
        y: still ? Math.round(by) : by
        width: fig.fw + 2 * fig.pad
        height: fig.fh + 2 * fig.pad
        opacity: fig.her.alpha
        transform: Rotation {
            origin.x: fig.pad + fig.seatX
            origin.y: fig.pad + fig.seatY
            angle: fig.her.tilt
        }
        property variant atlas: fig.video ? filmTex : atlas
        property vector2d box: Qt.vector2d(width, height)
        property vector4d sprite: Qt.vector4d(fig.pad, fig.pad, fig.fw, fig.fh)
        property real split: fig.video && fig.meta.vh ? fig.meta.alphaAt / fig.meta.vh : 0
        property vector4d cell: {
            if (fig.video && fig.meta.colour)
                return Qt.vector4d(0, 0, fig.meta.colour[0] / fig.meta.vw, fig.meta.colour[1] / fig.meta.vh);
            const i = Math.max(0, Math.min(fig.her.frame, (fig.meta ? fig.meta.count : 1) - 1));
            const aw = fig.cols * fig.cellW;
            const ah = fig.rows * fig.cellH;
            return Qt.vector4d(((i % fig.cols) * fig.cellW + fig.gutter) / aw, (Math.floor(i / fig.cols) * fig.cellH + fig.gutter) / ah, (fig.meta ? fig.meta.w : 1) / aw, (fig.meta ? fig.meta.h : 1) / ah);
        }
        property real mirror: fig.her.flip ? 1 : 0
        property real seat: fig.pad + fig.seatY
        property vector4d reveal: Qt.vector4d(fig.her.revealUp >= 1 ? 1e5 : (fig.seatY + 24) * fig.her.revealUp, fig.her.revealDown >= 1 ? 1e5 : (fig.fh - fig.seatY + 24) * fig.her.revealDown, fig.her.heat, 16)
        property vector4d hot: Qt.vector4d(fig.her.light.r, fig.her.light.g, fig.her.light.b, 1.1)
        property vector4d shade: Qt.vector4d(fig.her.flip ? -5 : 5, 9, 5, fig.her.shadow * (Theme.dark ? 0.55 : 0.34))
        property vector4d shadeColor: Theme.dark ? Qt.vector4d(0.01, 0.015, 0.05, 1) : Qt.vector4d(0.1, 0.07, 0.3, 1)
        property vector4d ground: fig.local(fig.her.ground, body.x, body.y)
        property vector4d occ0: fig.local(fig.her.occ[0], body.x, body.y)
        property vector4d occ1: fig.local(fig.her.occ[1], body.x, body.y)
        property vector4d occ2: fig.local(fig.her.occ[2], body.x, body.y)
        property vector4d occ3: fig.local(fig.her.occ[3], body.x, body.y)
        property real occRadius: 8
        fragmentShader: Qt.resolvedUrl("../../shaders/sill.frag.qsb")
    }

    Repeater {
        model: fig.her.pool
        Image {
            required property int index
            readonly property var m: fig.her.motes[index] || null
            readonly property real age: m ? fig.her.now - m.t : -1
            readonly property real u: m ? age / m.life : 1
            visible: !!m && u >= 0 && u < 1
            source: Theme.a(m && m.b ? "pointer-mote-b.png" : "pointer-mote.png")
            width: Theme.dark ? 12 : 16
            height: width
            smooth: true
            opacity: m ? m.k * Math.pow(1 - Math.max(0, Math.min(1, u)), 1.4) * Math.min(1, u * 6) : 0
            scale: m ? m.size * (1 - 0.4 * u) : 1
            x: m ? m.x + m.vx * age / 1000 - fig.origin.x - width / 2 : 0
            y: m ? m.y + m.vy * age / 1000 + 0.5 * m.g * (age / 1000) * (age / 1000) - fig.origin.y - height / 2 : 0
        }
    }
}
