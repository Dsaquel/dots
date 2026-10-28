import QtQuick

Fx {
    id: fx

    relit: true
    property var poly: []
    property real tilt: 0.19
    property real back: 0.32
    property real cellX: 150
    property real zScale: 9
    property real gain: 0.55

    function corner(i: int): point {
        const p = fx.poly.length ? fx.poly[Math.min(i, fx.poly.length - 1)] : [0, 0];
        return fx.uv(p[0], p[1]);
    }

    ShaderEffect {
        anchors.fill: parent
        property variant farTex: fx.farTex
        property variant nearTex: fx.nearTex
        property vector4d farMap: fx.farMap
        property vector4d nearMap: fx.nearMap
        property real hasNear: fx.hasNear
        property real t: fx.t
        property real aspect: width / Math.max(1, height)
        property real tilt: fx.tilt
        property real back: fx.back
        property real front: 1.0
        property vector2d area: Qt.vector2d(width, height)
        property real cellX: fx.cellX * fx.s
        property real zScale: fx.zScale
        property real speed: 0.42
        property real gain: fx.gain
        property vector4d tint: Qt.vector4d(1.0, 0.92, 0.78, 1)
        property vector4d fade: fx.poly.length ? Qt.vector4d(0.01, 0.01, 0.01, 0.01) : Qt.vector4d(0.1, 0.1, 0.05, 0.02)
        readonly property point c0: fx.corner(0)
        readonly property point c1: fx.corner(1)
        readonly property point c2: fx.corner(2)
        readonly property point c3: fx.corner(3)
        readonly property point c4: fx.corner(4)
        readonly property point c5: fx.corner(5)
        property vector4d pa: Qt.vector4d(c0.x, c0.y, c1.x, c1.y)
        property vector4d pb: Qt.vector4d(c2.x, c2.y, c3.x, c3.y)
        property vector4d pc: Qt.vector4d(c4.x, c4.y, c5.x, c5.y)
        property real sides: fx.poly.length
        property real soft: 0.012
        property variant floorTex: fx.maskTex
        property real hasFloor: fx.hasMask
        fragmentShader: Qt.resolvedUrl("../../shaders/world-caustics.frag.qsb")
    }
}
