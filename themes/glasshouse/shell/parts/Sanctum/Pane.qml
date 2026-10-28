import QtQuick
import qs.core
import qs.kit

Item {
    id: n

    property string name
    property int border: 24
    property point light: Qt.point(0.3, 0.0)
    property real power: 0.45
    property real ambient: 0.55
    property real radius: 1.2
    property real grain: 0.12
    property real sweep: -1

    BorderImage {
        id: colBI
        anchors.fill: parent
        source: Theme.a(n.name + ".png")
        border { left: n.border; right: n.border; top: n.border; bottom: n.border }
    }
    ShaderEffectSource {
        id: colSrc
        sourceItem: colBI
        hideSource: true
    }
    BorderImage {
        id: leadBI
        anchors.fill: parent
        source: Theme.a(n.name + "-lead.png")
        border { left: n.border; right: n.border; top: n.border; bottom: n.border }
    }
    ShaderEffectSource {
        id: leadSrc
        sourceItem: leadBI
        hideSource: true
    }
    Glass {
        anchors.fill: parent
        glassMap: colSrc
        grainTex: grainImg
        light: n.light
        power: n.power
        ambient: n.ambient
        radius: n.radius
        grain: n.grain
    }
    Image {
        id: grainImg
        source: Theme.shared("sanctum-grain.png")
        visible: false
    }
    Lead {
        anchors.fill: parent
        heightMap: leadSrc
        lx: n.light.x
        ly: n.light.y - 1.2
        sweep: n.sweep
    }
}
