import QtQuick

Fx {
    id: fx

    property string look: "embers"
    readonly property bool dust: look === "dust"

    ShaderEffect {
        anchors.fill: parent
        property real t: fx.t
        property real seed: fx.seed
        property real count: fx.dust ? 14 : 9
        property vector2d area: Qt.vector2d(width, height)
        property vector2d drift: (fx.dust ? Qt.vector2d(4, 6) : Qt.vector2d(3, -8)).times(fx.u)
        property real wander: (fx.dust ? 14 : 24) * fx.u
        property real blink: fx.dust ? 3.2 : 6.5
        property real duty: fx.dust ? 0.55 : 0.85
        property real size: (fx.dust ? 1.1 : 1.5) * fx.u
        property real halo: (fx.dust ? 4.5 : 8) * fx.u
        property color colA: fx.dust ? "#fff4d6" : "#ff9858"
        property color colB: fx.dust ? "#ffd48a" : "#ffd0a0"
        property real mixB: fx.dust ? 0.4 : 0.25
        property vector4d beam: fx.dust ? Qt.vector4d(0.62, -0.78, 70 * fx.u, 0) : Qt.vector4d(0, 0, 1, 0)
        property real beamAmt: fx.dust ? 0.8 : 0
        property real edge: 50 * fx.u
        property real power: fx.dust ? 1.1 : 1.15
        fragmentShader: Qt.resolvedUrl("../../shaders/world-motes.frag.qsb")
    }
}
