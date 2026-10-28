import QtQuick

Fx {
    id: fx

    relit: true

    ShaderEffect {
        anchors.fill: parent
        readonly property point c: fx.uv(1328, 466)
        property variant farTex: fx.farTex
        property variant nearTex: fx.nearTex
        property vector4d farMap: fx.farMap
        property vector4d nearMap: fx.nearMap
        property real hasNear: fx.hasNear
        property vector2d center: Qt.vector2d(c.x, c.y)
        property real aspect: width / Math.max(1, height)
        property real t: fx.t
        property real seed: fx.seed
        property real reach: 0.36
        property real gain: 0.55
        property real boost: 0.05
        property real flicker: 0.42
        property vector4d warm: Qt.vector4d(1.0, 0.62, 0.7, 1)
        property color hot: "#ffb48e"
        property real bloom: 0.026
        property real pulse: 0
        fragmentShader: Qt.resolvedUrl("../../shaders/world-lantern.frag.qsb")
    }
}
