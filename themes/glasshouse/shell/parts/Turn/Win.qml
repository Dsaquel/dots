import QtQuick
import Quickshell.Wayland

Item {
    id: w

    required property var win
    property var look: ({})
    property bool solid: false
    property var bg: null
    required property size screen

    x: w.win.lx
    y: w.win.ly
    width: w.win.w
    height: w.win.h

    ScreencopyView {
        id: cap
        anchors.fill: parent
        captureSource: w.win.wayland || null
        live: true
    }

    ShaderEffectSource {
        id: frameTex
        width: 0
        height: 0
        sourceItem: cap
        hideSource: true
    }

    ShaderEffect {
        anchors.fill: parent
        opacity: w.look.alpha === undefined ? 1 : w.look.alpha
        property variant src: frameTex
        property variant bg: w.bg || frameTex
        property vector2d size: Qt.vector2d(w.width, w.height)
        property vector2d origin: Qt.vector2d(w.x, w.y)
        property vector2d screen: Qt.vector2d(w.screen.width, w.screen.height)
        property real radius: w.look.radius === undefined ? 8 : w.look.radius
        property real power: w.look.power === undefined ? 2 : w.look.power
        property real dim: w.look.dim || 0
        property real solid: w.solid ? 1 : 0
        property real blurOn: w.look.blur && w.bg ? 1 : 0
        fragmentShader: Qt.resolvedUrl("shaders/win.frag.qsb")
    }
}
