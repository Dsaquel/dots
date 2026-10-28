import QtQuick
import qs.core

ShaderEffect {
    id: k

    property rect win
    property vector2d box: Qt.vector2d(width, height)
    property real radius: 8
    property real offset: 7
    property real hwOff: 1.15
    property real hwOn: 2.2
    property real pieceLen: 72
    property vector4d lightPos: Qt.vector4d(width / 2, -400, 520, 640)
    property color pool: "transparent"
    property color base: Theme.metalBase
    property color hi: Theme.metalHi
    property color low: Theme.metalLow
    property color sky: Theme.metalSky
    property color jewelA: Theme.dark ? "#3558b8" : "#e8759a"
    property color jewelB: Theme.dark ? "#6a4fc2" : "#7fb6ff"
    property color jewelC: Theme.dark ? "#e3a253" : "#f3c14f"
    property color pearl: Theme.dark ? "#cfd8ec" : "#f4efe6"
    property color hot: Theme.dark ? "#ffd9a0" : "#fff0c8"
    property real unlit: Theme.dark ? 0.46 : 0.62
    property real specGain: Theme.dark ? 0.7 : 1.0
    property real shininess: Theme.dark ? 26 : 38
    property vector4d lit: Qt.vector4d(0, 1e5, 0, 0)
    property vector4d laid: Qt.vector4d(0, 1e5, 0, 0)
    property vector4d gap: Qt.vector4d(0, 0, 0, 0)
    property vector4d seal: Qt.vector4d(0, 1e5, 0, 0)
    property vector4d call: Qt.vector4d(0, 0, 0, 0)
    property var occ: []
    property vector4d occ0: k.occ[0] || Qt.vector4d(0, 0, 0, 0)
    property vector4d occ1: k.occ[1] || Qt.vector4d(0, 0, 0, 0)
    property vector4d occ2: k.occ[2] || Qt.vector4d(0, 0, 0, 0)
    property vector4d occ3: k.occ[3] || Qt.vector4d(0, 0, 0, 0)
    property real occRadius: 8

    fragmentShader: Qt.resolvedUrl("../../shaders/skin.frag.qsb")
}
