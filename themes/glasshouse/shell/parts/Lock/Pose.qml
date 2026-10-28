import QtQuick
import qs.core
import qs.parts.World

Item {
    id: pose

    required property string output
    property real settle: 1
    readonly property var out: Stage.of(output)
    readonly property var art: out ? Stage.layers(output, World.name) : ({})
    readonly property bool ready: plate.status === Image.Ready && (!art.deep || deep.status === Image.Ready)

    Image {
        id: deep
        x: pose.out ? pose.out.farX + (pose.out.deepX - pose.out.farX) * pose.settle : 0
        y: plate.y
        width: plate.width
        height: plate.height
        sourceSize: Qt.size(width, height)
        source: pose.art.deep || ""
        asynchronous: false
        cache: true
        smooth: true
    }
    Image {
        id: plate
        x: pose.out ? pose.out.farX : 0
        y: pose.out ? pose.out.fy : 0
        width: pose.out ? pose.out.fw : 0
        height: pose.out ? pose.out.fh : 0
        sourceSize: Qt.size(width, height)
        source: pose.art.plate || ""
        asynchronous: false
        cache: true
        smooth: true
    }
}
