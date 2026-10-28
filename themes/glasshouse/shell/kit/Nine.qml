import QtQuick
import qs.core

Item {
    id: n

    property string name
    property int border: 24
    property point light: Qt.point(0.3, 0.0)
    property real power: 0.45
    property real ambient: 0.55
    property real radius: 1.2
    property real sweep: -1
    property color tint: "white"
    property string giltName: ""

    BorderImage {
        id: colBI
        anchors.fill: parent
        source: Theme.a(n.name + ".png")
        border { left: n.border; right: n.border; top: n.border; bottom: n.border }
    }
    ShaderEffectSource { id: colSrc; sourceItem: colBI; hideSource: true }
    BorderImage {
        id: leadBI
        anchors.fill: parent
        source: Theme.a(n.name + "-lead.png")
        border { left: n.border; right: n.border; top: n.border; bottom: n.border }
    }
    ShaderEffectSource { id: leadSrc; sourceItem: leadBI; hideSource: true }

    Glass {
        anchors.fill: parent
        glassMap: colSrc
        light: n.light
        power: n.power
        ambient: n.ambient
        radius: n.radius
        tint: n.tint
    }
    BorderImage {
        id: giltBI
        visible: n.giltName !== ""
        anchors.fill: parent
        source: n.giltName !== "" ? Theme.a(n.giltName + ".png") : ""
        border { left: 20; right: 20; top: 20; bottom: 20 }
    }
    ShaderEffectSource { id: giltSrc; sourceItem: giltBI; hideSource: true }
    Lead {
        anchors.fill: parent
        heightMap: leadSrc
        lx: n.light.x
        ly: n.light.y - 1.2
        sweep: n.sweep
    }
    Gilt {
        visible: n.giltName !== ""
        anchors.fill: parent
        heightMap: giltSrc
        lx: 0.2
        ly: -0.6
        sweep: n.sweep
        depth: 3
    }
}
