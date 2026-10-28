import QtQuick

Fx {
    id: fx

    relit: true
    cutout: true

    readonly property point from: fx.px(1755, 600)
    readonly property point to: fx.px(1500, 1330)
    readonly property real len: Math.hypot(to.x - from.x, to.y - from.y)

    ShaderEffect {
        anchors.fill: parent
        property variant farTex: fx.farTex
        property variant nearTex: fx.nearTex
        property vector4d farMap: fx.farMap
        property vector4d nearMap: fx.nearMap
        property real hasNear: fx.hasNear
        property real t: fx.t
        property real seed: fx.seed
        property vector2d area: Qt.vector2d(width, height)
        property vector2d origin: Qt.vector2d(fx.from.x, fx.from.y)
        property vector2d dir: Qt.vector2d((fx.to.x - fx.from.x) / fx.len, (fx.to.y - fx.from.y) / fx.len)
        property real len: fx.len
        property vector4d beams: Qt.vector4d(-40 * fx.s, 90 * fx.s, -165 * fx.s, 0)
        property vector4d widths: Qt.vector4d(58 * fx.s, 30 * fx.s, 36 * fx.s, 1)
        property vector4d pool: Qt.vector4d(fx.to.x - 20 * fx.s, fx.to.y + 10 * fx.s, 300 * fx.s, 62 * fx.s)
        property color moon: "#b4bfff"
        property real air: 0.14
        property real sheen: 0.2
        property real dust: 1.2
        property variant cutTex: fx.cutTex
        property real hasCut: fx.hasCut
        fragmentShader: Qt.resolvedUrl("../../shaders/world-moon.frag.qsb")
    }
}
