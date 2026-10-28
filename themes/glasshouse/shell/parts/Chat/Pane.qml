import QtQuick
import qs.core

ShaderEffect {
    id: fx

    readonly property bool dark: Theme.dark
    property vector2d box: Qt.vector2d(width, height)
    property vector4d pane: Qt.vector4d(0, 0, width, height)
    property real radius: 14
    property real chamfer: 0
    property real hollow: 0
    property vector2d tailA: Qt.vector2d(0, 0)
    property vector2d tailB: Qt.vector2d(0, 0)
    property vector2d tailC: Qt.vector2d(0, 0)
    property vector2d tailW: Qt.vector2d(11, 1.2)
    property real tailOn: 0
    property real rim: 3.4
    property real band: 0
    property real inner: 1.8
    property real header: 0
    property color headTop: dark ? "#363b8e" : "#5a40ae"
    property color headBottom: dark ? "#262a6a" : "#432f8f"
    property color bodyTop: dark ? "#20275a" : "#3036ad"
    property color bodyBottom: dark ? "#111538" : "#20248a"
    property color jewelA: dark ? "#33467f" : "#6e3866"
    property color corner: dark ? "#e09a3e" : "#f4ece4"
    property real jewel: 0
    property real cornerGlow: 0
    property real glassAlpha: 0.95
    property color base: dark ? Theme.metalBase : "#c99a4e"
    property color hi: dark ? Theme.metalHi : "#fff4cf"
    property color low: dark ? Theme.metalLow : "#3b2410"
    property color sky: dark ? Theme.metalSky : "#f7dfa4"
    property real shine: dark ? 22 : 38
    property real metalness: dark ? 0.7 : 1.0
    property color gold: dark ? Theme.rare : Theme.sun
    property real goldMix: 0
    property vector2d lightPos: Qt.vector2d(0, height)
    property real lightZ: 220
    property color lightColor: dark ? Theme.lamp : Theme.sun
    property real lightPower: 0.32
    property real lightRadius: 240
    property real sweep: -1
    property color sweepColor: dark ? "#ffd9a0" : "#fff2c8"
    property real flash: 0
    property real haloSize: 14
    property real shadow: 0.5
    property real spill: 0
    property real shade: 1
    property real lift: 0
    property real grain: dark ? 0.22 : 0.16
    property real grainSize: 300
    property variant grainTex: Image {
        source: Theme.shared("chat-glass.png")
        visible: false
    }

    fragmentShader: Qt.resolvedUrl("../../shaders/chat-pane.frag.qsb")
}
