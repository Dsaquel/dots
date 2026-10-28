import QtQuick

Fx {
    id: fx

    property var spots: []
    property real size: 15
    property int slots: 3

    function slot(i: int): vector4d {
        const n = fx.spots.length;
        if (!n || i >= fx.slots)
            return Qt.vector4d(0, 0, -1, 1);
        const cyc = 2.1 + i * 0.37;
        const tt = fx.t + i * 0.83;
        const c = Math.floor(tt / cyc);
        const h = Math.abs(Math.sin((c + 1) * 12.9898 + i * 4.1 + fx.seed * 7.7) * 43758.5453) % 1;
        const k = (tt - c * cyc) / 1.05;
        if (k > 1)
            return Qt.vector4d(0, 0, -1, 1);
        const p = fx.spots[Math.floor(h * n) % n];
        const q = fx.px(p[0], p[1]);
        return Qt.vector4d(q.x, q.y, Math.round(k * 30) / 30, fx.size * fx.u * (0.75 + 0.5 * ((h * 7.3) % 1)));
    }

    ShaderEffect {
        anchors.fill: parent
        property vector2d area: Qt.vector2d(width, height)
        property vector4d s0: fx.slot(0)
        property vector4d s1: fx.slot(1)
        property vector4d s2: fx.slot(2)
        property vector4d s3: fx.slot(3)
        property color inner: "#fffaf0"
        property color outer: "#ff5fae"
        property real power: 1.0
        fragmentShader: Qt.resolvedUrl("../../shaders/world-sparkle.frag.qsb")
    }
}
