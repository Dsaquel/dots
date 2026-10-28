import QtQuick

ShaderEffect {
    property color color: "#f2b35e"
    property real core: 0.12
    property real intensity: 1.0
    fragmentShader: Qt.resolvedUrl("../shaders/glow.frag.qsb")
}
