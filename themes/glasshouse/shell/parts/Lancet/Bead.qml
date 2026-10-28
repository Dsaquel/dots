import QtQuick
import qs.core
import qs.kit

Item {
    id: bead

    required property var host
    property bool roundelHovered: false
    visible: bead.host.main
    readonly property var rd: bead.host.main ? bead.host.lay.roundel : ({ cx: 0, cy: 0, r: 0 })
    readonly property bool unread: Her.unread > 0
    readonly property real lit: bead.host.activeKey === "thread" ? 1 : 0
    x: rd.cx + (rd.r - 3) * 0.7071 - width / 2
    y: rd.cy - (rd.r - 3) * 0.7071 - height / 2
    width: 12
    height: 12
    Glow {
        anchors.centerIn: parent
        width: 36
        height: 36
        color: Theme.lamp
        core: 0.25
        intensity: (parent.unread ? 0.5 : 0) + 0.3 * parent.lit
        Behavior on intensity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    }
    Pearl {
        anchors.fill: parent
        base: parent.unread ? Theme.lamp : (Theme.dark ? "#4b4a68" : "#6d63a8")
        hi: parent.unread ? "#fff6e8" : (Theme.dark ? "#b9b6dc" : "#d8d0ff")
        low: Theme.dark ? (parent.unread ? "#3a2410" : "#07080f") : (parent.unread ? "#4a0a2a" : "#120f33")
        sky: parent.unread ? (Theme.dark ? "#ffe2b0" : "#ffb8dc") : (Theme.dark ? "#5d6690" : "#8f86d8")
    }
    MouseArea {
        anchors.fill: parent
        anchors.margins: -5
        enabled: bead.host.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: bead.host.hoverKey = "thread"
        onExited: if (bead.host.hoverKey === "thread") bead.host.hoverKey = bead.roundelHovered ? "her" : ""
        onClicked: Bus.thread()
    }
}
