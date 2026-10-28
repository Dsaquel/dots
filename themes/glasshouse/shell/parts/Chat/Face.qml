import QtQuick
import qs.core
import qs.kit

Item {
    id: f

    property string face: Her.face
    property real light: 0.6

    width: 56
    height: 56

    Glass {
        anchors.fill: parent
        src: Theme.a("chat-ring.png")
        light: Qt.point(0.3, 0.2)
        power: f.light
        ambient: 0.62
        radius: 0.9
        grain: 0.1
    }
    Image {
        x: f.width * 0.11
        y: x
        width: f.width - 2 * x
        height: width
        sourceSize: Qt.size(112, 112)
        source: f.face
        smooth: true
        mipmap: true
    }
    Lead {
        anchors.fill: parent
        src: Theme.a("chat-ring-lead.png")
        lx: 0.1
        ly: -0.5
    }
}
