import QtQuick
import QtQuick3D
import QtQuick3D.Helpers
import qs.core

ExtendedSceneEnvironment {
    id: lens

    required property var turn

    backgroundMode: SceneEnvironment.Color
    clearColor: "black"
    tonemapMode: SceneEnvironment.TonemapModeNone
    antialiasingMode: SceneEnvironment.MSAA
    antialiasingQuality: SceneEnvironment.High
    glowEnabled: true
    glowStrength: 1.0
    glowIntensity: 0.85
    glowBloom: 0.0
    glowHDRMinimumValue: 1.0
    glowHDRMaximumValue: 24
    glowHDRScale: 1.3
    glowQualityHigh: true
    glowUseBicubicUpscale: true
    glowLevel: ExtendedSceneEnvironment.GlowLevel.One | ExtendedSceneEnvironment.GlowLevel.Two | ExtendedSceneEnvironment.GlowLevel.Three | ExtendedSceneEnvironment.GlowLevel.Four | ExtendedSceneEnvironment.GlowLevel.Five | ExtendedSceneEnvironment.GlowLevel.Six
    glowBlendMode: ExtendedSceneEnvironment.GlowBlendMode.Additive
    effects: [
        Effect {
            property vector2d center: Qt.vector2d(lens.turn.cx / Screens.design.width, lens.turn.cy / Screens.design.height)
            property real density: 0.55
            property real threshold: 0.75
            property real falloff: 0.955
            property real power: lens.turn.rays
            property color tint: lens.turn.hot
            property real impAmt: lens.turn.impAmt
            property real impInv: lens.turn.impInv
            property color impInk: lens.turn.ink
            property color impGold: lens.turn.gold
            passes: [ Pass { shaders: [ Shader { stage: Shader.Fragment; shader: "shaders/rays.frag" } ] } ]
        }
    ]
}
