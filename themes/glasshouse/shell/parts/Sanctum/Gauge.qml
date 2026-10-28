import QtQuick
import qs.core
import qs.kit
import qs.parts.Lancet

Item {
    id: g

    property bool sel: false
    readonly property real level: Math.max(0, Math.min(1, Gauges.volume))
    readonly property int lit: Math.round(g.level * 14)
    readonly property color dark: Theme.dark ? Qt.rgba(0.3, 0.32, 0.5, 1) : Qt.rgba(0.36, 0.38, 0.72, 1)

    width: 402
    height: 24

    Glass {
        id: strip
        x: 0
        y: 4
        width: 360
        height: 16
        src: Theme.a("sanctum-gauge.png")
        tint: g.dark
        ambient: 0.62
        power: 0
        grain: 0.12
    }
    Item {
        x: strip.x - 10
        y: strip.y - 10
        width: g.lit > 0 ? g.lit * 26 + 10 : 0
        height: strip.height + 20
        clip: true
        Glass {
            visible: !Gauges.muted
            width: strip.width + 20
            height: strip.height + 20
            src: Theme.a("sanctum-gauge-glow.png")
            additive: 1
            ambient: 0
            power: 0.55
            radius: 2
            grain: 0
        }
        Glass {
            x: 10
            y: 10
            width: strip.width
            height: strip.height
            src: Theme.a("sanctum-gauge.png")
            tint: Gauges.muted ? Theme.dim : "white"
            light: Qt.point(0.5, 0.0)
            ambient: Gauges.muted ? 0.5 : 0.92
            power: Gauges.muted ? 0 : 0.3
            radius: 0.9
            grain: 0.08
        }
    }
    Lead {
        x: strip.x
        y: strip.y
        width: strip.width
        height: strip.height
        src: Theme.a("sanctum-gauge-lead.png")
        lx: 0.3
        ly: -1.2
        depth: 2.4
    }
    Rectangle {
        visible: g.sel
        x: strip.x - 6
        y: strip.y - 5
        width: strip.width + 12
        height: strip.height + 10
        radius: 8
        color: "transparent"
        border.width: 2
        border.color: Theme.ivory
    }
    Text {
        id: value
        x: 372
        anchors.verticalCenter: strip.verticalCenter
        text: Gauges.muted ? "muted" : Math.round(Gauges.volume * 100)
        font.family: Gauges.muted ? Theme.ui : Theme.numerals
        font.italic: Gauges.muted
        font.pixelSize: Gauges.muted ? 13 : 17
        font.features: { "lnum": 1, "tnum": 1 }
        color: Gauges.muted ? Theme.dim : Theme.inkSoft
    }

    MouseArea {
        x: strip.x - 4
        width: strip.width + 8
        height: g.height
        hoverEnabled: true
        onEntered: Rite.pickVolume()
        onClicked: mouse => Rite.setVolume(Math.max(1, Math.min(14, Math.ceil((mouse.x - 4) / 26))) / 14)
        onWheel: wheel => Rite.nudgeVolume(wheel.angleDelta.y > 0 ? 1 : -1)
    }
    MouseArea {
        anchors.fill: value
        anchors.margins: -6
        hoverEnabled: true
        onEntered: Rite.pickVolume()
        onClicked: Rite.muteToggle()
    }
}
