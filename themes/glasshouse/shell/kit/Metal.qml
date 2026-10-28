import QtQuick

ShaderEffect {
    id: fx

    property url src
    property real lx: 0.3
    property real ly: -0.2
    property variant heightMap: Image { source: fx.src; smooth: true; mipmap: true; visible: false }
    property size texel: Qt.size(1 / Math.max(1, width), 1 / Math.max(1, height))
    property point light: Qt.point(lx, ly)
    property real lightZ: 0.9
    property real depth: 5.0
    property real shininess: 38
    property real metal: 1.0
    property real sweep: -1
    property real aspect: width / Math.max(1, height)
    property color base: "#b98f4e"
    property color hi: "#fff1c9"
    property color low: "#2a1c18"
    property color sky: "#f3d9a0"

    fragmentShader: Qt.resolvedUrl("../shaders/emboss.frag.qsb")
}
