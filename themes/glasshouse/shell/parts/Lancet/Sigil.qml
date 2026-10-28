import QtQuick
import qs.core
import qs.kit

Item {
    id: sigil

    required property var host
    visible: sigil.host.main
    readonly property var rd: sigil.host.main ? sigil.host.lay.roundel : ({ cx: 0, cy: 0, r: 0 })
    readonly property real lit: Leaf.open ? 1 : sigil.host.activeKey === "page" ? 0.65 : 0
    x: rd.cx - width / 2
    y: sigil.host.main ? (rd.cy + rd.r + sigil.host.lay.sill.y) / 2 + 2 - height / 2 : 0
    width: 20
    height: 20
    Glow {
        anchors.centerIn: parent
        width: 58
        height: 58
        color: Theme.dark ? Theme.lamp : Theme.sun
        core: 0.2
        intensity: 0.1 + 0.42 * sigil.lit
        Behavior on intensity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    }
    Piece {
        anchors.fill: parent
        name: "chat-sigil"
        power: 0.7
        ambient: 0.62
        glow: 0.3 + 0.6 * sigil.lit
        light: Qt.point(0.35, 0.3)
    }
    MouseArea {
        anchors.fill: parent
        anchors.margins: -8
        enabled: sigil.host.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: sigil.host.hoverKey = "page"
        onExited: if (sigil.host.hoverKey === "page") sigil.host.hoverKey = ""
        onClicked: Leaf.toggle()
    }
}
