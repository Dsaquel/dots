import QtQuick
import Quickshell.Widgets
import qs.core
import qs.kit

Item {
    id: player

    required property var owner

    visible: !!player.owner.p
    width: parent.width
    height: 76
    Piece {
        id: art
        name: "sanctum-art"
        x: -8
        y: -8
        width: 92
        height: 92
        power: 0.55
        ambient: 0.66
        glow: player.owner.p && player.owner.p.isPlaying ? 0.4 : 0
    }
    ClippingRectangle {
        anchors.centerIn: art
        width: 52
        height: 52
        radius: 26
        color: Theme.metalLow
        Image {
            anchors.fill: parent
            source: player.owner.p ? player.owner.p.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(104, 104)
            asynchronous: true
        }
    }
    Column {
        x: 92
        y: 6
        width: buttons.x - x - 8
        spacing: 3
        Text {
            width: parent.width
            text: player.owner.p ? (player.owner.p.trackTitle || player.owner.p.identity) : ""
            elide: Text.ElideRight
            font.family: player.owner.face
            font.pixelSize: 16
            font.weight: Font.Medium
            color: player.owner.ink
        }
        Text {
            width: parent.width
            text: player.owner.p ? (player.owner.p.trackArtist || "") : ""
            elide: Text.ElideRight
            font.family: player.owner.face
            font.pixelSize: 13
            color: player.owner.dim
        }
    }
    Row {
        id: buttons
        x: parent.width - width
        y: 4
        spacing: 6
        Repeater {
            model: [
                { g: "\u{f04ae}", on: player.owner.p && player.owner.p.canGoPrevious },
                { g: player.owner.p && player.owner.p.isPlaying ? "\u{f03e4}" : "\u{f040a}", on: player.owner.p && player.owner.p.canTogglePlaying },
                { g: "\u{f04ad}", on: player.owner.p && player.owner.p.canGoNext }
            ]
            Item {
                id: btn
                required property var modelData
                required property int index
                readonly property bool sel: player.owner.isSel("player", btn.index)
                width: 34
                height: 34
                opacity: btn.modelData.on ? 1 : 0.4
                Piece {
                    anchors.fill: parent
                    name: "sanctum-btn"
                    power: 0.5
                    ambient: btn.sel ? 0.95 : 0.66
                    glow: 0
                    hasGlow: false
                }
                Rectangle {
                    visible: btn.sel
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.ivory
                }
                Text {
                    anchors.centerIn: parent
                    text: btn.modelData.g
                    font.family: Theme.glyphs
                    font.pixelSize: 16
                    color: player.owner.gold
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: player.owner.pick("player", btn.index)
                    onClicked: {
                        player.owner.pick("player", btn.index);
                        Rite.activate();
                    }
                }
            }
        }
    }
    Item {
        id: track
        x: 92
        y: 56
        width: parent.width - x - 88
        height: 8
        readonly property bool known: !!player.owner.p && player.owner.p.lengthSupported && player.owner.p.length > 0
        readonly property real frac: track.known ? Math.max(0, Math.min(1, player.owner.p.position / player.owner.p.length)) : 0
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 1.5
            color: Theme.dark ? Theme.metalSky : Theme.metalBase
            opacity: 0.5
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * track.frac
            height: 2
            color: player.owner.gold
        }
        Rectangle {
            visible: track.known
            x: parent.width * track.frac - 3
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            radius: 3
            color: Theme.ivory
        }
    }
    Text {
        visible: track.known
        anchors.right: parent.right
        anchors.verticalCenter: track.verticalCenter
        text: player.owner.clockOf(player.owner.p ? player.owner.p.position : 0) + " / " + player.owner.clockOf(player.owner.p ? player.owner.p.length : 0)
        font.family: player.owner.face
        font.pixelSize: 12
        font.features: { "tnum": 1 }
        color: player.owner.dim
    }
    Timer {
        interval: 1000
        repeat: true
        running: !!player.owner.p && player.owner.p.isPlaying && Rite.opened
        triggeredOnStart: true
        onTriggered: player.owner.p.positionChanged()
    }
}
