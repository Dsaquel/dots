import QtQuick
import qs.core
import qs.kit

Item {
    id: k

    required property string side
    property point light: Qt.point(0.5, 0.2)
    property vector4d rect: Qt.vector4d(0, 0, 0, 0)
    property real glint: -100000
    property real sweep: -1
    readonly property string plate: k.url(k.side + ".png")

    function url(name: string): string {
        return Assets.url("wings/skin/" + Theme.world + "/" + name);
    }

    Glass {
        anchors.fill: parent
        src: k.plate
        light: k.light
        radius: 0.55
        power: Theme.dark ? 0.16 : 0.12
        ambient: Theme.dark ? 1.04 : 0.98
        grain: 0
    }
    Sheen {
        anchors.fill: parent
        heightSrc: k.url(k.side + "-lead.png")
        colorSrc: k.plate
        light: Qt.point(k.side === "left" ? 0.85 : 0.15, -0.1)
        rect: k.rect
        glint: k.glint
        sweep: k.sweep
        gain: Theme.dark ? 0.85 : 0.7
        rest: Theme.dark ? 0.1 : 0.08
    }
}
