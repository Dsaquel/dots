import QtQuick

Fx {
    id: fx

    relit: true
    cutout: true
    property color tint: "#e6ebff"
    property real power: 0.9

    readonly property real period: 26
    readonly property real span: 1.15
    readonly property real phase: {
        const c = Math.floor(fx.t / fx.period);
        const h = Math.abs(Math.sin(c * 12.9898 + fx.seed * 78.233) * 43758.5453) % 1;
        const k = (fx.t - c * fx.period - 3 - h * (fx.period - 7)) / fx.span;
        return k >= 0 && k <= 1 ? Math.round(k * 48) / 48 : -1;
    }

    hurried: fx.phase >= 0

    ShaderEffect {
        anchors.fill: parent
        visible: fx.phase >= 0
        readonly property point b: fx.uv(507, 421)
        readonly property point e: fx.uv(652, 340)
        readonly property point st: fx.uv(664, 336)
        property variant nearTex: fx.nearTex
        property vector4d nearMap: fx.nearMap
        property real phase: Math.max(0, fx.phase)
        property vector2d base: Qt.vector2d(b.x, b.y)
        property vector2d tip: Qt.vector2d(e.x, e.y)
        property vector2d star: Qt.vector2d(st.x, st.y)
        property real aspect: width / Math.max(1, height)
        property color tint: fx.tint
        property real power: fx.power
        property variant cutTex: fx.cutTex
        property real hasCut: fx.hasCut
        readonly property point ca: fx.uv(620, 356)
        readonly property point cb: fx.uv(650, 341)
        property vector2d capA: Qt.vector2d(ca.x, ca.y)
        property vector2d capB: Qt.vector2d(cb.x, cb.y)
        property real rows: fx.area.height
        fragmentShader: Qt.resolvedUrl("../../shaders/world-glint.frag.qsb")
    }
}
