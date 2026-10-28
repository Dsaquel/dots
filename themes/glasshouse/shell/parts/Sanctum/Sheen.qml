import QtQuick

ShaderEffect {
    id: s

    property url heightSrc
    property url colorSrc
    property size texel: Qt.size(1 / Math.max(1, width * 2), 1 / Math.max(1, height * 2))
    property point light: Qt.point(0.8, -0.1)
    property real depth: 3.5
    property real shininess: 34
    property real aspect: width / Math.max(1, height)
    property vector4d rect: Qt.vector4d(0, 0, 0, 0)
    property real glint: -100000
    property real glintWidth: 70
    property real sweep: -1
    property real gain: 0.8
    property real rest: 0.08
    property variant heightMap: Image {
        source: s.heightSrc
        visible: false
        smooth: true
        mipmap: true
    }
    property variant colorMap: Image {
        source: s.colorSrc
        visible: false
        smooth: true
        mipmap: true
    }

    fragmentShader: Qt.resolvedUrl("../../shaders/sanctum-sheen.frag.qsb")
}
