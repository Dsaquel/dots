import QtQuick
import qs.core

Item {
    id: b

    property string label
    property bool primary: false
    property bool lit: false
    property string testKey: ""
    readonly property bool hovered: mouse.containsMouse || (Test.on && b.testKey !== "" && Test.hover === b.testKey)

    signal clicked()

    implicitWidth: Math.round(text.implicitWidth + 30)
    implicitHeight: 24

    Pane {
        x: -5
        y: -3
        width: b.width + 10
        height: b.height + 11
        pane: Qt.vector4d(5, 3, b.width, b.height)
        chamfer: 7
        rim: 1.9
        shadow: 0.32
        bodyTop: b.primary ? "#f6efe0" : (b.lit ? (Theme.dark ? "#3b4c8f" : "#5a3d9e") : (Theme.dark ? "#222b57" : "#363cb4"))
        bodyBottom: b.primary ? "#ddd0b6" : (b.lit ? (Theme.dark ? "#2b3874" : "#46308a") : (Theme.dark ? "#161c40" : "#262a92"))
        glassAlpha: 0.97
        lightPos: Qt.vector2d(8, 2)
        lightRadius: 70
        lightPower: b.primary ? 0.12 : 0.3
        grain: b.primary ? 0.05 : 0.1
        lift: b.hovered ? 1 : 0
        goldMix: b.hovered ? 0.85 : 0
        spill: b.hovered ? 0.6 : 0
        haloSize: 8
        Behavior on lift { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on goldMix { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }
    Text {
        id: text
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 0.5
        text: b.label
        font.family: Theme.ui
        font.pixelSize: 12
        font.variableAxes: { "wght": 640 }
        color: b.primary ? Theme.inkOnLight : Theme.ink
        renderType: Text.NativeRendering
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
