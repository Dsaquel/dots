import QtQuick
import qs.core
import qs.kit

Repeater {
    id: lozenges

    required property var owner

    model: lozenges.owner.lozenges
    Item {
        id: lz
        required property var modelData
        required property int index
        readonly property bool sel: lozenges.owner.isSel("system", lz.index)
        x: lozenges.owner.at.loz[0] + lz.index * lozenges.owner.at.loz[2] - width / 2
        y: lozenges.owner.at.loz[1] - height / 2
        width: lozenges.owner.at.loz[3]
        height: lozenges.owner.at.loz[3]
        Glass {
            visible: lz.modelData.on
            anchors.fill: parent
            anchors.margins: -15
            src: Theme.a("sanctum-loz-on-glow.png")
            additive: 1
            ambient: 0
            power: Theme.dark ? 0.5 : 0.42
            radius: 2
            grain: 0
        }
        Glass {
            anchors.fill: parent
            src: Theme.a(lz.modelData.on ? "sanctum-loz-on.png" : "sanctum-loz.png")
            light: Qt.point(0.5, 0.2)
            power: 0.5
            ambient: lz.modelData.on ? (Theme.dark ? 0.95 : 0.8) : 0.62
            radius: 0.7
        }
        Lead {
            anchors.fill: parent
            src: Theme.a("sanctum-loz-lead.png")
            lx: 0.3
            ly: -0.6
            depth: 3
        }
        Text {
            anchors.centerIn: parent
            text: lz.modelData.glyph
            font.family: Theme.glyphs
            font.pixelSize: 20
            color: lz.modelData.on ? "#2a1640" : lozenges.owner.inkSoft
        }
        Rectangle {
            visible: lz.sel
            anchors.centerIn: parent
            width: parent.width * 0.77
            height: width
            rotation: 45
            color: "transparent"
            border.width: 2
            border.color: Theme.ivory
            radius: 2
            antialiasing: true
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: lozenges.owner.pick("system", lz.index)
            onClicked: {
                lozenges.owner.pick("system", lz.index);
                Rite.activate();
            }
        }
    }
}
