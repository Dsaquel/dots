import QtQuick
import qs.core

Item {
    id: time

    required property var host
    property date stamp
    readonly property var r: time.host.lay ? time.host.lay.time : ({ x: 0, y: 0, w: 0, h: 0 })
    readonly property var axes: Theme.dark ? ({}) : ({ "wght": 560, "opsz": 34 })
    x: r.x
    y: r.y
    width: r.w
    height: r.h
    readonly property real line: time.height > 98 ? 34 : 33
    Text {
        id: hh
        anchors.horizontalCenter: parent.horizontalCenter
        y: time.line - baselineOffset
        text: Qt.formatTime(time.stamp, "hh")
        font.family: Theme.numerals
        font.pixelSize: 34
        font.variableAxes: time.axes
        font.features: { "lnum": 1, "tnum": 1 }
        color: Theme.ink
        renderType: Text.CurveRendering
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 2 * time.line - baselineOffset
        text: Qt.formatTime(time.stamp, "mm")
        font: hh.font
        color: Theme.ink
        renderType: Text.CurveRendering
    }
    Rectangle {
        readonly property bool lit: time.host.activeKey === "time"
        anchors.horizontalCenter: parent.horizontalCenter
        y: 2 * time.line + 10
        width: lit ? time.width - 18 : Math.min(30, time.width - 24)
        height: 1
        color: time.host.gold
        opacity: lit ? 1 : 0.7
        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 2 * time.line + 23 - baselineOffset
        text: time.stamp.toLocaleDateString(time.host.en, "ddd d").toUpperCase()
        font.family: Theme.caps
        font.pixelSize: 10
        font.letterSpacing: Theme.capsTracking
        font.weight: Font.DemiBold
        color: time.host.gold
    }
    MouseArea {
        anchors.fill: parent
        enabled: time.host.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: time.host.hoverKey = "time"
        onExited: if (time.host.hoverKey === "time") time.host.hoverKey = ""
        onClicked: Bus.sanctum("")
    }
}
