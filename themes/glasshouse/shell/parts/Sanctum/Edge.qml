import QtQuick
import QtQuick.Shapes
import qs.core

Shape {
    id: e

    required property Item wing
    property real depth: 13
    readonly property bool isLeft: e.wing.side === "left"
    readonly property real a: (e.isLeft ? 1 : -1) * 84 * (1 - e.wing.open) * Math.PI / 180
    readonly property real mid: e.wing.y + e.wing.height / 2
    readonly property real dx: e.wing.outer - e.wing.hinge

    function at(dy: real, z: real): point {
        const s = Math.sin(e.a);
        const c = Math.cos(e.a);
        const k = 1 + (s * e.dx - c * z) / 1024;
        return Qt.point(e.wing.hinge + (c * e.dx + s * z) / k, e.mid + dy / k);
    }
    readonly property point ft: e.at(e.wing.edgeTop - e.mid, 0)
    readonly property point fb: e.at(e.wing.edgeBottom - e.mid, 0)
    readonly property point bb: e.at(e.wing.edgeBottom - e.mid, -e.depth)
    readonly property point bt: e.at(e.wing.edgeTop - e.mid, -e.depth)

    width: 1
    height: 1
    visible: Math.abs(e.a) > 0.004
    opacity: e.wing.opacity
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: -1
        fillGradient: LinearGradient {
            x1: e.ft.x
            y1: (e.ft.y + e.fb.y) / 2
            x2: e.bt.x
            y2: (e.bt.y + e.bb.y) / 2
            GradientStop { position: 0; color: "#ffe9b0" }
            GradientStop { position: 0.1; color: "#e2b670" }
            GradientStop { position: 0.32; color: "#fff1c4" }
            GradientStop { position: 0.55; color: "#b8893f" }
            GradientStop { position: 0.85; color: "#5e4120" }
            GradientStop { position: 1; color: "#22170c" }
        }
        startX: e.ft.x
        startY: e.ft.y
        PathLine { x: e.fb.x; y: e.fb.y }
        PathLine { x: e.bb.x; y: e.bb.y }
        PathLine { x: e.bt.x; y: e.bt.y }
        PathLine { x: e.ft.x; y: e.ft.y }
    }
}
