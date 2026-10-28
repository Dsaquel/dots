import QtQuick
import QtQuick3D
import QtQuick3D.Helpers

Model {
    id: landing

    required property var turn

    z: 1
    geometry: ProceduralMesh {
        Component.onCompleted: {
            const P = [], U = [], U1 = [], C = [], I = [];
            let sd = 29;
            const rnd = () => { sd = (sd * 16807) % 2147483647; return sd / 2147483647; };
            const quad = (x, y, g, t0, life) => {
                const b = P.length, s = rnd();
                for (const q of [[-1, -1], [1, -1], [1, 1], [-1, 1]]) {
                    P.push(Qt.vector3d(0, 0, 0)); U.push(Qt.vector2d(q[0], q[1])); U1.push(Qt.vector2d(x, y)); C.push(Qt.vector4d(s, g, t0, life));
                }
                I.push(b, b + 1, b + 2, b, b + 2, b + 3);
            };
            for (let i = 0; i < 44; i++) {
                const a = rnd() * 6.2832, r = rnd() * 36;
                quad(landing.turn.cx + r * Math.cos(a), landing.turn.cy + r * Math.sin(a), 0, rnd() * 0.03, 0.3 + rnd() * 0.35);
            }
            for (let i = 0; i < 56; i++) {
                const a = rnd() * 6.2832, r = [104, 150, 412, 446, 494][Math.floor(rnd() * 5)];
                quad(landing.turn.cx + r * Math.cos(a), landing.turn.cy + r * Math.sin(a), 1, 0.02 + rnd() * 0.1, 0.35 + rnd() * 0.25);
            }
            positions = P; uv0s = U; uv1s = U1; colors = C; indexes = I;
        }
    }
    materials: CustomMaterial {
        shadingMode: CustomMaterial.Unshaded
        sourceBlend: CustomMaterial.One
        destinationBlend: CustomMaterial.One
        depthDrawMode: Material.NeverDepthDraw
        cullMode: Material.NoCulling
        property real t: landing.turn.t
        property real landT: landing.turn.landT
        property color warm: landing.turn.warm
        property color hot: landing.turn.hot
        vertexShader: "shaders/landspark.vert"
        fragmentShader: "shaders/spark.frag"
    }
}
