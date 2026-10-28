import QtQuick
import qs.core

Item {
    id: t

    property string source

    width: 60
    height: 60

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 3
        color: Theme.dark ? "#0b0e22" : "#14165a"
    }
    Image {
        id: img
        anchors.fill: parent
        anchors.margins: 2.5
        source: t.source
        sourceSize: Qt.size(120, 120)
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        asynchronous: true
    }
    Pane {
        x: -4
        y: -3
        width: t.width + 8
        height: t.height + 10
        pane: Qt.vector4d(4, 3, t.width, t.height)
        radius: 4
        rim: 2.6
        hollow: 1
        shadow: 0.4
        lightPos: Qt.vector2d(0, 0)
        lightRadius: 60
    }
}
