import QtQuick
import QtQuick3D

Repeater3D {
    id: rosace

    required property var turn
    required property Texture roseDarkTex
    required property Texture roseLightTex
    required property Texture glowDarkTex
    required property Texture glowLightTex
    required property Texture fillTex
    required property Texture fillCovTex

    model: [[0.0, 1.0], [0.035, 0.42], [0.07, 0.24], [0.105, 0.13]]
    Node {
        required property var modelData
        readonly property real lag: modelData[0]
        readonly property bool main: lag === 0
        readonly property bool lifted: main && rosace.turn.t >= rosace.turn.touchT
        position: Qt.vector3d(rosace.turn.cx - 960, 540 - rosace.turn.cy, rosace.turn.roseZAt(rosace.turn.t - lag) + (lifted ? rosace.turn.lift : 0))
        scale: Qt.vector3d(rosace.turn.cscale * (lifted ? rosace.turn.liftK : 1), rosace.turn.cscale * (lifted ? rosace.turn.liftK : 1), rosace.turn.cscale * (lifted ? rosace.turn.liftK : 1))
        eulerRotation.x: rosace.turn.roseTiltAt(rosace.turn.t - lag)
        visible: main || (rosace.turn.t - lag > rosace.turn.flyT + 0.02 && rosace.turn.t < rosace.turn.touchT)
        Model {
            source: "#Rectangle"
            scale: Qt.vector3d(10.24, 10.24, 1)
            depthBias: parent.lifted ? rosace.turn.lift : 0
            eulerRotation.z: rosace.turn.roseSpinAt(rosace.turn.tc - parent.lag)
            materials: CustomMaterial {
                shadingMode: CustomMaterial.Unshaded
                sourceBlend: CustomMaterial.One
                destinationBlend: CustomMaterial.OneMinusSrcAlpha
                depthDrawMode: Material.NeverDepthDraw
                cullMode: Material.NoCulling
                property real draw: rosace.turn.draw
                property real fillOp: 0.6
                property real level: rosace.turn.level * modelData[1]
                property real fade: rosace.turn.t >= rosace.turn.flyT && rosace.turn.t >= rosace.turn.starT - 0.02 ? rosace.turn.cfade : 0
                property color core: rosace.turn.hot
                property color halo: rosace.turn.dawn ? rosace.turn.gold : "#7aa2ff"
                property color hot: "#ffffff"
                property TextureInput art: TextureInput { texture: rosace.turn.arrive === "light" ? rosace.roseLightTex : rosace.roseDarkTex }
                property TextureInput fill: TextureInput { texture: rosace.fillTex }
                property TextureInput fillc: TextureInput { texture: rosace.fillCovTex }
                property TextureInput glow: TextureInput { texture: rosace.turn.arrive === "light" ? rosace.glowLightTex : rosace.glowDarkTex }
                property real glowRest: 0.14
                property real glowBeat: 1.3
                property real auraT: 0.7
                property real auraLit: 0.7
                property real leadT: 0.5
                property real leadC: 1.0
                property real lineCap: 1.35
                property real fillCap: 1.15
                property real fillWave: 0.3
                property real fillOwn: 0.7
                property real holdT: rosace.turn.holdT
                property real snapT: rosace.turn.snapT
                property real fillI: rosace.turn.fillI * modelData[1]
                property real t: rosace.turn.t
                property real touchT: rosace.turn.touchT
                property real knockT: rosace.turn.knockW
                property real knockDur: 0.2
                property vector4d beatsA: Qt.vector4d(rosace.turn.beats[0], rosace.turn.beats[1], rosace.turn.beats[2], rosace.turn.beats[3])
                property vector2d beatsB: Qt.vector2d(rosace.turn.beats[4], rosace.turn.beats[5])
                property vector4d durA: Qt.vector4d(rosace.turn.writeDur[0], rosace.turn.writeDur[1], rosace.turn.writeDur[2], rosace.turn.writeDur[3])
                property vector2d durB: Qt.vector2d(rosace.turn.writeDur[4], rosace.turn.writeDur[5])
                property real waveT: 0.07
                property real hlK: modelData[1] * (1 - 0.5 * rosace.turn.hush)
                property real hlGain: 0.8
                property real hlMode: 0
                property color hlCol: rosace.turn.hlCol
                property real signK: 1.25
                property real headK: 4.0
                vertexShader: "shaders/pen.vert"
                fragmentShader: "shaders/rose.frag"
            }
        }
        Model {
            source: "#Rectangle"
            z: 2
            scale: Qt.vector3d(9, 9, 1)
            visible: parent.main && rosace.turn.star > 0.002
            materials: CustomMaterial {
                shadingMode: CustomMaterial.Unshaded
                sourceBlend: CustomMaterial.One
                destinationBlend: CustomMaterial.One
                depthDrawMode: Material.NeverDepthDraw
                property color tint: rosace.turn.hot
                property real power: rosace.turn.star
                vertexShader: "shaders/pen.vert"
                fragmentShader: "shaders/star.frag"
            }
        }
    }
}
