import QtQuick
import qs.core

ShaderEffect {
    id: g

    property url src
    property variant glassMap: img
    property variant grainTex: grainSrc
    property point light: Qt.point(0.5, 0.3)
    property real radius: 0.7
    property real power: 0.7
    property real ambient: 0.6
    property real aspect: width / Math.max(1, height)
    property real additive: 0
    property real grain: 0.12
    property size grainScale: Qt.size(width / 256, height / 256)
    property color tint: "white"

    Image { id: img; source: g.src; visible: false; smooth: true; mipmap: true }
    Image { id: grainImg; source: Theme.shared("glass-noise.png") }
    ShaderEffectSource { id: grainSrc; sourceItem: grainImg; hideSource: true; visible: false; wrapMode: ShaderEffectSource.Repeat }

    fragmentShader: Qt.resolvedUrl("../shaders/glass.frag.qsb")
}
