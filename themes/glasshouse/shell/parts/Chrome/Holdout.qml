import QtQuick

ShaderEffect {
    property var occ: []
    property vector2d box: Qt.vector2d(width, height)
    property vector4d occ0: occ[0] || Qt.vector4d(0, 0, 0, 0)
    property vector4d occ1: occ[1] || Qt.vector4d(0, 0, 0, 0)
    property vector4d occ2: occ[2] || Qt.vector4d(0, 0, 0, 0)
    property vector4d occ3: occ[3] || Qt.vector4d(0, 0, 0, 0)
    property real occRadius: 8
    fragmentShader: Qt.resolvedUrl("../../shaders/holdout.frag.qsb")
}
