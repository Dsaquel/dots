import QtQuick
import qs.core

Item {
    id: her

    required property var host
    visible: her.host.main
    readonly property var rd: her.host.main ? her.host.lay.roundel : ({ cx: 0, cy: 0, r: 6 })
    readonly property string sleepyFace: Assets.has("heroine/faces/" + Theme.world + "-sleepy.png") ? Assets.face(Theme.world, "sleepy") : ""
    readonly property string face: (Settings.dnd || Her.asleep) && her.sleepyFace ? her.sleepyFace : Her.face
    property bool flip: false
    x: rd.cx - (rd.r - 6)
    y: rd.cy - (rd.r - 6)
    width: 2 * (rd.r - 6)
    height: width
    opacity: Settings.dnd ? 0.58 : 1
    Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutCubic } }
    onFaceChanged: {
        her.flip = !her.flip;
        (her.flip ? faceB : faceA).source = her.face;
    }
    Component.onCompleted: faceA.source = her.face
    Image {
        id: faceA
        anchors.fill: parent
        sourceSize: Qt.size(2 * her.width * her.host.unit, 2 * her.height * her.host.unit)
        smooth: true
        mipmap: true
        opacity: her.flip ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.InOutCubic } }
    }
    Image {
        id: faceB
        anchors.fill: parent
        sourceSize: Qt.size(2 * her.width * her.host.unit, 2 * her.height * her.host.unit)
        smooth: true
        mipmap: true
        opacity: her.flip ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.InOutCubic } }
    }
}
