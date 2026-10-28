import QtQuick
import qs.core

ShaderEffect {
    id: fx

    property url src
    property real lx: 0.3
    property real ly: -0.2
    property variant heightMap: Image {
        source: fx.src
        smooth: true
        visible: false
    }
    property size texel: Qt.size(1 / Math.max(1, width), 1 / Math.max(1, height))
    property point light: Qt.point(lx, ly)
    property real lightZ: 0.9
    property real depth: Theme.dark ? 4.2 : 5
    property real shininess: Theme.dark ? 30 : 42
    property real metal: Theme.dark ? 0.7 : 1.0
    property real aspect: width / Math.max(1, height)
    property color base: Theme.metalBase
    property color hi: Theme.metalHi
    property color low: Theme.metalLow
    property color sky: Theme.metalSky
    property vector4d rect: Qt.vector4d(0, 0, width, height)
    property real glint: -100000
    property real glintWidth: 64
    property real glintGain: Theme.dark ? 1.25 : 0.95
    property color glintColor: Theme.dark ? "#eef0ff" : "#fff2cc"

    fragmentShader: Qt.resolvedUrl("../../shaders/sanctum-metal.frag.qsb")
}
