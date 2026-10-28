import QtQuick
import qs.core
import qs.kit

Item {
    id: m

    property string icon: ""
    property string vial: ""
    property color vialLight: Theme.dark ? Theme.rare : Theme.sun
    property bool own: false
    property string letter: ""
    readonly property bool sign: m.own || (m.icon === "" && m.vial === "" && m.letter === "")

    width: 24
    height: 24

    Pane {
        x: -3
        y: -2
        width: m.width + 6
        height: m.height + 7
        pane: Qt.vector4d(3, 2, m.width, m.height)
        radius: m.width / 2
        rim: 2.3
        shadow: 0.35
        bodyTop: Theme.dark ? "#121733" : "#1a1d6a"
        bodyBottom: Theme.dark ? "#0a0d22" : "#12145a"
        lightPos: Qt.vector2d(4, 3)
        lightRadius: 30
        lightPower: 0.25
        grain: 0.08
    }
    Image {
        visible: m.icon !== "" && m.vial === "" && !m.own
        anchors.centerIn: parent
        width: 15
        height: 15
        sourceSize: Qt.size(30, 30)
        source: visible ? m.icon : ""
        smooth: true
        mipmap: true
    }
    Glow {
        visible: m.vial !== ""
        anchors.centerIn: parent
        width: m.width * 1.1
        height: width
        color: m.vialLight
        core: 0.25
        intensity: 0.7
    }
    Image {
        visible: m.vial !== ""
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 0.5
        height: 22
        width: 22
        fillMode: Image.PreserveAspectFit
        sourceSize: Qt.size(40, 40)
        source: m.vial
        smooth: true
        mipmap: true
    }
    Text {
        visible: !m.own && m.icon === "" && m.vial === "" && m.letter !== ""
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 0.5
        text: m.letter
        font.family: Theme.caps
        font.pixelSize: Math.round(m.height * 0.52)
        font.weight: Font.Bold
        color: Theme.dark ? Theme.rare : Theme.sun
        renderType: Text.NativeRendering
    }
    Piece {
        visible: m.sign
        anchors.centerIn: parent
        width: 14
        height: 14
        name: "chat-sigil"
        power: 0.75
        ambient: 0.8
        glow: 0.5
        light: Qt.point(0.35, 0.3)
    }
}
