import QtQuick

Fx {
    id: fx

    relit: true

    ShaderEffect {
        anchors.fill: parent
        readonly property point c: fx.uv(1436, 809.33)
        property variant farTex: fx.farTex
        property variant nearTex: fx.nearTex
        property vector4d farMap: fx.farMap
        property vector4d nearMap: fx.nearMap
        property real hasNear: fx.hasNear
        property vector2d center: Qt.vector2d(c.x, c.y)
        property real aspect: width / Math.max(1, height)
        property real t: fx.t
        property real seed: fx.seed
        property real reach: 0.34
        property real gain: 0.5
        property real boost: 0.06
        property real flicker: 0.7
        property vector4d warm: Qt.vector4d(0.55, 0.85, 1.25, 1)
        property color hot: "#bfe6ff"
        property real bloom: 0.05
        property real pulse: 1
        fragmentShader: Qt.resolvedUrl("../../shaders/world-lantern.frag.qsb")
    }
}
