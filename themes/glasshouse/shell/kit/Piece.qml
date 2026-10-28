import QtQuick
import qs.core

Item {
    id: p

    property string name
    property point light: Qt.point(0.5, 0.25)
    property real power: 0.8
    property real ambient: 0.55
    property real radius: 0.8
    property real glow: 0.5
    property real sweep: -1
    property bool hasGlow: true
    property color tint: "white"

    Glass {
        visible: p.hasGlow && p.glow > 0.01
        anchors.fill: parent
        src: p.hasGlow ? Theme.a(p.name + "-glow.png") : ""
        additive: 1
        ambient: 0
        power: p.glow
        radius: 2.0
        light: p.light
        grain: 0
        tint: p.tint
    }
    Glass {
        anchors.fill: parent
        src: Theme.a(p.name + ".png")
        light: p.light
        power: p.power
        ambient: p.ambient
        radius: p.radius
        tint: p.tint
    }
    Lead {
        anchors.fill: parent
        src: Theme.a(p.name + "-lead.png")
        lx: p.light.x - 0.3
        ly: p.light.y - 0.9
        sweep: p.sweep
    }
}
