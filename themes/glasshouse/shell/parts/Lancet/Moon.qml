import QtQuick
import qs.core

ShaderEffect {
    property real phase: Gauges.moonPhase
    property color lit: "#dfe6f6"
    property color dark: "#1b2350"
    fragmentShader: Qt.resolvedUrl("../../shaders/moon.frag.qsb")
}
