import QtQuick
import qs.core
import qs.kit

Item {
    id: j

    required property var tool
    required property int index
    required property real u
    required property real shown
    property bool leftward: false
    signal chosen(string key)

    readonly property real d: 44 * j.u
    readonly property real rise: Math.max(0, Math.min(1, (j.shown - j.index * 0.09) / 0.5))
    readonly property real pop: 1 + 2.4 * Math.pow(j.rise - 1, 3) + 1.4 * Math.pow(j.rise - 1, 2)
    width: j.d
    height: j.d
    opacity: Math.min(1, j.rise * 2)
    scale: (0.4 + 0.6 * j.pop) * (area.pressed ? 0.92 : area.containsMouse ? 1.08 : 1)
    Behavior on scale {
        NumberAnimation { duration: 90 }
    }

    readonly property color hue: Theme.dark ? j.tool.dark : j.tool.light
    Piece {
        anchors.fill: parent
        name: "sanctum-medal"
        power: area.containsMouse ? 0.9 : 0.6
        ambient: area.containsMouse ? 0.9 : 0.66
        glow: area.containsMouse ? 0.9 : 0.4
        tint: Qt.tint("white", Qt.alpha(j.hue, 0.3))
    }
    Glow {
        anchors.centerIn: parent
        width: j.d * 0.78
        height: width
        color: j.hue
        core: 0.22
        intensity: area.containsMouse ? 1.25 : 0.75
    }
    Gilt {
        anchors.fill: parent
        src: Theme.a("sanctum-medal-gilt.png")
        lx: 0.25
        ly: -0.5
    }
    Text {
        anchors.centerIn: parent
        text: j.tool.glyph
        font.family: Theme.glyphs
        font.pixelSize: 19 * j.u
        color: j.tool.key === "record" ? (Theme.dark ? "#ff6b7d" : "#fff0f3") : Theme.dark ? Theme.rare : Theme.cream
        style: Text.Raised
        styleColor: "#40000000"
    }
    Rectangle {
        id: tag
        visible: area.containsMouse
        anchors.verticalCenter: parent.verticalCenter
        x: j.leftward ? -width - 10 * j.u : j.d + 10 * j.u
        width: label.implicitWidth + 22 * j.u
        height: 26 * j.u
        radius: 4 * j.u
        color: Qt.alpha(Theme.ground, 0.9)
        border.width: Math.max(1, 1.2 * j.u)
        border.color: Theme.dark ? Theme.rare : Theme.sun
        Text {
            id: label
            anchors.centerIn: parent
            text: j.tool.label + (j.tool.hint ? "   " + j.tool.hint : "")
            font.family: Theme.caps
            font.pixelSize: 10.5 * j.u
            font.letterSpacing: Theme.capsTracking * j.u
            color: Theme.ink
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: if (containsMouse)
            Sfx.play("cutter-jewel-" + (j.index + 1), 0.6)
        onClicked: j.chosen(j.tool.key)
    }
}
