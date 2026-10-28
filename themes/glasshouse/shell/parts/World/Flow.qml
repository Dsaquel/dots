import QtQuick

Fx {
    id: fx

    relit: true
    property var poly: []
    property color tint: "#b4bfff"
    property real lo: 0.1
    property real hi: 0.4
    property real gain: 2.8

    function corner(i: int): point {
        const p = fx.poly.length ? fx.poly[Math.min(i, fx.poly.length - 1)] : [0, 0];
        return fx.uv(p[0], p[1]);
    }

    ShaderEffect {
        anchors.fill: parent
        property variant farTex: fx.farTex
        property variant nearTex: fx.nearTex
        property variant floorTex: fx.maskTex
        property vector4d farMap: fx.farMap
        property vector4d nearMap: fx.nearMap
        property real hasNear: fx.hasNear
        property real hasFloor: fx.hasMask
        property real t: fx.t
        property real seed: fx.seed
        property vector2d area: Qt.vector2d(width, height)
        property real tilt: 0.19
        property real back: 0.32
        property real front: 1.0
        property real radius: 5 * fx.s
        property real lo: fx.lo
        property real hi: fx.hi
        property real amp: 3.4 * fx.s
        property real cell: 90 * fx.s
        property real speed: 0.5
        property real gain: fx.gain
        property color tint: fx.tint
        property vector4d fade: Qt.vector4d(0.01, 0.01, 0.05, 0.03)
        property real aspect: width / Math.max(1, height)
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
        property real soft: 0.02
        fragmentShader: Qt.resolvedUrl("../../shaders/world-flow.frag.qsb")
    }
}
