import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

Item {
    id: bd

    required property var screen
    property real shown: 0
    readonly property bool ready: cap.hasContent
    readonly property size quarter: Qt.size(Math.ceil(bd.width / 4), Math.ceil(bd.height / 4))

    ScreencopyView {
        id: cap
        anchors.fill: parent
        captureSource: bd.screen
        live: false
        paintCursor: false
    }
    ShaderEffectSource {
        id: frame
        sourceItem: cap
        hideSource: true
        smooth: true
    }
    ShaderEffect {
        id: down
        width: bd.quarter.width
        height: bd.quarter.height
        property variant src: frame
        property point texel: Qt.point(1 / Math.max(1, bd.width), 1 / Math.max(1, bd.height))
        fragmentShader: Qt.resolvedUrl("../../shaders/sanctum-down.frag.qsb")
    }
    ShaderEffectSource {
        id: small
        sourceItem: down
        hideSource: true
        smooth: true
        format: ShaderEffectSource.RGBA16F
    }
    ShaderEffect {
        id: across
        width: bd.quarter.width
        height: bd.quarter.height
        property variant src: small
        property point dir: Qt.point(1 / bd.quarter.width, 0)
        property real sigma: 8
        fragmentShader: Qt.resolvedUrl("../../shaders/sanctum-blur.frag.qsb")
    }
    ShaderEffectSource {
        id: wide
        sourceItem: across
        hideSource: true
        smooth: true
        format: ShaderEffectSource.RGBA16F
    }
    ShaderEffect {
        id: downward
        width: bd.quarter.width
        height: bd.quarter.height
        property variant src: wide
        property point dir: Qt.point(0, 1 / bd.quarter.height)
        property real sigma: 8
        fragmentShader: Qt.resolvedUrl("../../shaders/sanctum-blur.frag.qsb")
    }
    ShaderEffectSource {
        id: blurred
        sourceItem: downward
        hideSource: true
        smooth: true
        format: ShaderEffectSource.RGBA16F
    }
    ShaderEffect {
        anchors.fill: parent
        opacity: bd.shown
        property variant source: blurred
    }
}
