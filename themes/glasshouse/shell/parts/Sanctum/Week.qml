import QtQuick
import qs.core
import qs.kit

Item {
    id: week

    required property var owner

    visible: !week.owner.p
    readonly property real size: Math.min(150, week.owner.at.play[1] - week.owner.at.play[0] - 20)
    width: parent.width
    height: week.size
    Item {
        id: wheel
        width: week.size
        height: week.size
        Glass {
            anchors.fill: parent
            src: Theme.a("sanctum-week.png")
            light: Qt.point(0.4, 0.2)
            power: 0.4
            ambient: 0.66
            radius: 0.8
        }
        Glass {
            anchors.fill: parent
            rotation: week.owner.day * 360 / 7
            src: Theme.a("sanctum-week-lit-glow.png")
            additive: 1
            ambient: 0
            power: Theme.dark ? 0.55 : 0.45
            radius: 2
            grain: 0
        }
        Glass {
            anchors.fill: parent
            rotation: week.owner.day * 360 / 7
            src: Theme.a("sanctum-week-lit.png")
            light: Qt.point(0.5, 0.1)
            power: 0.45
            ambient: 0.92
            radius: 0.8
        }
        Lead {
            anchors.fill: parent
            src: Theme.a("sanctum-week-lead.png")
            lx: 0.3
            ly: -0.6
        }
        Repeater {
            model: 7
            Text {
                required property int index
                readonly property real a: -Math.PI / 2 + index * 2 * Math.PI / 7
                x: wheel.width / 2 + Math.cos(a) * wheel.width * 0.3375 - width / 2
                y: wheel.height / 2 + Math.sin(a) * wheel.height * 0.3375 - height / 2
                text: week.owner.planets[index].glyph
                font.family: Theme.symbols
                font.pixelSize: Math.round(wheel.width * 0.12)
                color: index === week.owner.day ? Theme.inkOnLight : week.owner.inkSoft
                opacity: index === week.owner.day ? 1 : 0.62
            }
        }
        Text {
            anchors.centerIn: parent
            text: week.owner.planet.glyph
            font.family: Theme.symbols
            font.pixelSize: Math.round(wheel.width * 0.2)
            color: week.owner.gold
        }
    }
    Column {
        x: wheel.width + 20
        anchors.verticalCenter: wheel.verticalCenter
        spacing: 5
        Text {
            text: week.owner.planet.name
            font.family: Theme.caps
            font.pixelSize: 17
            font.letterSpacing: 4.5
            font.weight: Font.DemiBold
            color: week.owner.gold
        }
        Text {
            text: week.owner.planet.metal
            font.family: week.owner.face
            font.pixelSize: 15
            font.italic: true
            color: week.owner.ink
        }
        Text {
            text: week.owner.planet.line
            font.family: week.owner.face
            font.pixelSize: 13
            color: week.owner.dim
        }
    }
}
