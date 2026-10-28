import QtQuick

Fx {
    id: fx

    relit: true

    ShaderEffect {
        anchors.fill: parent
        property variant farTex: fx.farTex
        property vector4d farMap: fx.farMap
        property real t: fx.t
        property real seed: fx.seed
        property vector2d area: Qt.vector2d(width / fx.u, height / fx.u)
        property real road: fx.uv(770.67, 0).x
        property real roadW: 0.22
        property real gain: 0.9
        property vector4d tint: Qt.vector4d(0.85, 0.95, 1.2, 1)
        fragmentShader: Qt.resolvedUrl("../../shaders/world-sea.frag.qsb")
    }
}
