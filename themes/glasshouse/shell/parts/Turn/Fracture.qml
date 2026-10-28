import QtQuick
import QtQuick3D
import QtQuick3D.Helpers

Model {
    id: fracture

    required property var turn
    required property var mesh
    required property Texture printTex
    required property Texture maskTex
    required property Texture cracksTex
    required property Texture deskTex
    required property Texture fillTex
    required property Texture fillCovTex
    required property Texture roomATex

    geometry: ProceduralMesh {
        Component.onCompleted: {
            const m = JSON.parse(fracture.mesh.text());
            const P = [], N = [], U = [], U1 = [], C = [], T = [];
            for (const v of m.verts) {
                P.push(Qt.vector3d(v[0], v[1], v[2]));
                N.push(Qt.vector3d(v[3], v[4], v[5]));
                U.push(Qt.vector2d(v[6], v[7]));
                U1.push(Qt.vector2d(v[8], v[9]));
                C.push(Qt.vector4d(v[10], v[11], v[12], v[13]));
                T.push(Qt.vector3d(v[14], v[15], v[16]));
            }
            positions = P; normals = N; tangents = T; uv0s = U; uv1s = U1; colors = C; indexes = m.idx;
        }
    }
    materials: CustomMaterial {
        shadingMode: CustomMaterial.Unshaded
        sourceBlend: CustomMaterial.One
        destinationBlend: CustomMaterial.OneMinusSrcAlpha
        depthDrawMode: fracture.turn.t >= fracture.turn.touchT ? Material.AlwaysDepthDraw : Material.NeverDepthDraw
        cullMode: Material.NoCulling
        property real t: fracture.turn.t
        property real burstT: fracture.turn.burstT
        property real blastT: fracture.turn.blastT
        property real spread: 0.16
        property real hangK: 1.0
        property real fallK: 1.0
        property vector2d impact: Qt.vector2d(fracture.turn.cx, fracture.turn.cy)
        property real front: fracture.turn.front
        property real beatE: fracture.turn.beatE
        property vector2d center: Qt.vector2d(fracture.turn.cx, fracture.turn.cy)
        property real reveal: fracture.turn.reveal
        property real winA: 1 - 0.5 * fracture.turn.win(0.5, 1.0)
        property real sideVis: fracture.turn.win(fracture.turn.burstT, fracture.turn.burstT + 0.18)
        property real solid: fracture.turn.win(fracture.turn.touchT - 0.02, fracture.turn.touchT + 0.03)
        property real refr: 0.06
        property real broken: fracture.turn.win(fracture.turn.burstT - 0.02, fracture.turn.burstT + 0.08)
        property real stained: 0.62 * fracture.turn.win(fracture.turn.touchT + 0.1, fracture.turn.touchT + 0.6)
        property real pal: fracture.turn.dawn ? 0 : 1
        property real leadI: 0.8 + 0.4 * fracture.turn.beatE
        property real web: fracture.turn.web
        property real webI: 0.85 + 0.5 * fracture.turn.snapK * (1 - fracture.turn.win(fracture.turn.snapT + 0.03, fracture.turn.hsB))
        property real snapK: fracture.turn.snapK
        property real sep: fracture.turn.sep
        property real bulge: fracture.turn.bulge
        property real rimK: fracture.turn.win(fracture.turn.snapT, fracture.turn.snapT + 0.05)
        property real glintK: fracture.turn.win(fracture.turn.burstT - 0.01, fracture.turn.burstT + 0.06)
        property real fracI: 0.5 + 0.45 * fracture.turn.beatE + 0.8 * fracture.turn.hush
        property real stopR: fracture.turn.stopR
        property real stopOn: fracture.turn.stopOn
        property real relR: fracture.turn.relR
        property real relOn: fracture.turn.relOn
        property color ink: fracture.turn.ink
        property color gold: fracture.turn.gold
        property color hiCol: fracture.turn.hiCol
        property real thrA: fracture.turn.dawn ? 0.10 : 0.36
        property real thrB: fracture.turn.dawn ? 0.46 : 0.74
        property real dim: fracture.turn.dim
        property real cool: fracture.turn.cool
        property vector3d coolTint: Qt.vector3d(0.42, 0.55, 1.0)
        property real sheen: -0.6 + 2.2 * fracture.turn.win(0.45, 1.2)
        property real sheenK: 0.2 * fracture.turn.win(0.4, 0.55) * (1 - fracture.turn.win(1.05, 1.2))
        property color crackCol: fracture.turn.hot
        property color haloCol: fracture.turn.warm
        property real crackH: 0.04 + 0.06 * fracture.turn.beatE + 0.12 * fracture.turn.hush
        property real crackFade: 1 - fracture.turn.win(fracture.turn.burstT - 0.01, fracture.turn.burstT + 0.05)
        property color edgeCol: fracture.turn.dawn ? "#fff1d6" : "#e8f0ff"
        property real edgeI: 1.3
        property color glintCol: fracture.turn.hot
        property real glint: fracture.turn.win(fracture.turn.burstT - 0.02, fracture.turn.burstT + 0.05)
        property real rim: 0.25 * fracture.turn.win(fracture.turn.burstT - 0.02, fracture.turn.burstT + 0.05) * (1 - fracture.turn.win(fracture.turn.burstT + 0.3, fracture.turn.blastT))
        property TextureInput glass: TextureInput { texture: fracture.printTex }
        property TextureInput glassA: TextureInput { texture: fracture.maskTex }
        property TextureInput cracks: TextureInput { texture: fracture.cracksTex }
        property vector2d roseC: Qt.vector2d(960 + (fracture.turn.cx - 960) * fracture.turn.camZ / (fracture.turn.camZ - 1 - fracture.turn.lift), 540 + (fracture.turn.cy - 540) * fracture.turn.camZ / (fracture.turn.camZ - 1 - fracture.turn.lift))
        property real roseA: -fracture.turn.roseSpinAt(fracture.turn.tc) * Math.PI / 180
        property real roseS: fracture.turn.roseS
        property real waveT: 0.07
        property vector4d beatsA: Qt.vector4d(fracture.turn.beats[0], fracture.turn.beats[1], fracture.turn.beats[2], fracture.turn.beats[3])
        property vector2d beatsB: Qt.vector2d(fracture.turn.beats[4], fracture.turn.beats[5])
        property real stainR: 0.75
        property real roseTr: 1.0
        property real leadTint: fracture.turn.t < fracture.turn.snapT ? 0.6 : 0
        property TextureInput rfill: TextureInput { texture: fracture.fillTex }
        property TextureInput rfillc: TextureInput { texture: fracture.fillCovTex }
        property real rb: fracture.turn.rbOn
        property real rbFrom: fracture.turn.rbFrom
        property real landT: fracture.turn.landT
        property real rbSpan: fracture.turn.rbSpan
        property real rbK: fracture.turn.rbK
        property real rbA0: fracture.turn.rbA0
        property real rbDur: fracture.turn.rbDur
        property real rbSnap: fracture.turn.rbSnap
        property real rbHover: fracture.turn.rbHover
        property real rbHold: fracture.turn.rbHold
        property real rimR: fracture.turn.dawn ? 0.6 : 0.45
        property real glintR: 1.0
        property real winR: fracture.turn.rbWin
        property TextureInput desk: TextureInput { texture: fracture.deskTex }
        property TextureInput roomA: TextureInput { texture: fracture.roomATex }
        vertexShader: "shaders/anime.vert"
        fragmentShader: "shaders/anime.frag"
    }
}
