import QtQuick
import QtQuick3D
import QtQuick3D.Helpers

Model {
    id: burst

    required property var turn
    required property var sparks

    z: 1
    geometry: ProceduralMesh {
        Component.onCompleted: {
            const m = JSON.parse(burst.sparks.text());
            const P = [], U = [], U1 = [], C = [];
            for (const v of m.verts) {
                P.push(Qt.vector3d(0, 0, 0));
                U.push(Qt.vector2d(v[0], v[1]));
                U1.push(Qt.vector2d(v[2], v[3]));
                C.push(Qt.vector4d(v[4], v[5], v[6], v[7]));
            }
            positions = P; uv0s = U; uv1s = U1; colors = C; indexes = m.idx;
        }
    }
    materials: CustomMaterial {
        shadingMode: CustomMaterial.Unshaded
        sourceBlend: CustomMaterial.One
        destinationBlend: CustomMaterial.One
        depthDrawMode: Material.NeverDepthDraw
        cullMode: Material.NoCulling
        property real t: burst.turn.t
        property real burstT: burst.turn.burstT
        property real blastT: burst.turn.blastT
        property real relT: burst.turn.touchT
        property real chargeOff: burst.turn.touchT - 0.5
        property real motes: burst.turn.running ? 1 : 0
        property vector2d impact: Qt.vector2d(burst.turn.cx, burst.turn.cy)
        property real charge: (burst.turn.t > burst.turn.touchT ? 1 : 0) * (1.0 - burst.turn.win(burst.turn.burstT, burst.turn.burstT + 0.05))
        property color warm: burst.turn.warm
        property color hot: burst.turn.hot
        vertexShader: "shaders/spark.vert"
        fragmentShader: "shaders/spark.frag"
    }
}
