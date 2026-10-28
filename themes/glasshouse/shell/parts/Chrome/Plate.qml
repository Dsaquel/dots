import QtQuick
import qs.core

Item {
    id: p

    property string app
    property string title
    property real maxWidth: 400
    property point light: Qt.point(0, -300)
    readonly property real pad: 12
    readonly property real natural: (Theme.dark ? darkRow.implicitWidth : lightRow.implicitWidth) + 2 * p.pad

    width: Math.max(64, Math.min(p.natural, p.maxWidth))
    height: 22
    visible: p.app !== "" || p.title !== ""

    ShaderEffect {
        anchors.fill: parent
        property vector2d box: Qt.vector2d(width, height)
        property real radius: 7
        property real rim: Theme.dark ? 2.0 : 2.2
        property color glassTop: Theme.dark ? Qt.rgba(0.11, 0.13, 0.25, 1) : Qt.rgba(0.21, 0.24, 0.66, 1)
        property color glassBottom: Theme.dark ? Qt.rgba(0.06, 0.07, 0.15, 1) : Qt.rgba(0.12, 0.13, 0.42, 1)
        property real glassAlpha: Theme.dark ? 0.94 : 0.96
        property color base: Theme.dark ? "#4a4964" : "#cfa565"
        property color hi: Theme.dark ? "#dcd8f6" : "#fff4d6"
        property color low: Theme.dark ? "#07080f" : "#4a2f1c"
        property point lightPos: p.light
        property real lightZ: 260
        property real innerLine: Theme.dark ? 0 : 0.4
        property color innerColor: "#ffdc99"
        property real grain: 0.08
        property vector2d grainScale: Qt.vector2d(width / 256, height / 256)
        property variant grainTex: Image { source: Theme.shared("glass-noise.png"); visible: false }
        fragmentShader: Qt.resolvedUrl("../../shaders/pane.frag.qsb")
    }

    Row {
        id: darkRow
        visible: Theme.dark
        x: p.pad
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 0.5
        spacing: 0
        Text {
            id: darkApp
            text: p.app
            font.family: "Outfit"
            font.pixelSize: 12
            font.variableAxes: { "wght": 600 }
            color: "#d9d6f4"
            renderType: Text.NativeRendering
        }
        Text {
            visible: p.app !== "" && p.title !== ""
            text: "  ·  "
            font.family: "Outfit"
            font.pixelSize: 12
            color: "#8a92b8"
        }
        Text {
            text: p.title
            width: Math.min(implicitWidth, p.maxWidth - 2 * p.pad - darkApp.implicitWidth - 24)
            elide: Text.ElideMiddle
            font.family: "Outfit"
            font.pixelSize: 12
            font.variableAxes: { "wght": 420 }
            color: "#f1e8dc"
            renderType: Text.NativeRendering
        }
    }

    Row {
        id: lightRow
        visible: !Theme.dark
        x: p.pad - 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
        Text {
            text: "【"
            font.family: "Dela Gothic One"
            font.pixelSize: 12
            color: "#ff5fae"
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            id: lightApp
            text: p.app
            font.family: "Dela Gothic One"
            font.pixelSize: 12
            color: "#fff8ec"
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -0.5
        }
        Text {
            text: "】"
            font.family: "Dela Gothic One"
            font.pixelSize: 12
            color: "#ff5fae"
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: p.title !== ""
            text: p.title
            leftPadding: 2
            width: Math.min(implicitWidth, p.maxWidth - 2 * p.pad - lightApp.implicitWidth - 30)
            elide: Text.ElideMiddle
            font.family: "Manrope"
            font.pixelSize: 12
            font.variableAxes: { "wght": 560 }
            color: "#efe4ff"
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 0.5
        }
    }
}
