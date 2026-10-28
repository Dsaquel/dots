import QtQuick
import QtQuick3D

View3D {
    id: vault

    required property var host
    required property var turn
    required property Item printSource
    required property Item maskSource
    required property Item deskSource
    required property Item darkSource
    required property Item lightSource
    required property Item videoSource
    required property var mesh
    required property var sparks

    width: vault.host.view.width
    height: vault.host.view.height
    environment: Lens {
        turn: vault.turn
    }
    PerspectiveCamera {
        position: vault.turn.camPos
        fieldOfView: 30
        clipNear: 10
        clipFar: 40000
    }

    Texture {
        id: texPrint
        sourceItem: vault.printSource
    }
    Texture {
        id: texMask
        sourceItem: vault.maskSource
    }
    Texture {
        id: texDesk
        sourceItem: vault.deskSource
    }
    Texture {
        id: texWorldDark
        sourceItem: vault.darkSource
    }
    Texture {
        id: texWorldLight
        sourceItem: vault.lightSource
    }
    Texture {
        id: texVid
        sourceItem: vault.videoSource
    }
    Texture {
        id: texCracks
        source: Qt.resolvedUrl("../../assets/turn/cracks-anime.png")
    }
    Texture { id: texRoseDark; source: Qt.resolvedUrl("../../assets/turn/rose-dark.png") }
    Texture { id: texRoseLight; source: Qt.resolvedUrl("../../assets/turn/rose-light.png") }
    Texture { id: texGlowDark; source: Qt.resolvedUrl("../../assets/turn/rose-dark-glow.png") }
    Texture { id: texGlowLight; source: Qt.resolvedUrl("../../assets/turn/rose-light-glow.png") }
    Texture { id: texFillDark; source: Qt.resolvedUrl("../../assets/turn/rosefill-dark.png") }
    Texture { id: texFillLight; source: Qt.resolvedUrl("../../assets/turn/rosefill-light.png") }
    Texture { id: texCovDark; source: Qt.resolvedUrl("../../assets/turn/rosefill-dark-cov.png") }
    Texture { id: texCovLight; source: Qt.resolvedUrl("../../assets/turn/rosefill-light-cov.png") }
    readonly property var texRoomL: vault.turn.leave === "light" ? texWorldLight : texWorldDark
    readonly property var texRoomA: vault.turn.target === "light" ? texWorldLight : texWorldDark
    readonly property var texFill: vault.turn.arrive === "light" ? texFillLight : texFillDark
    readonly property var texFillCov: vault.turn.arrive === "light" ? texCovLight : texCovDark

    Model {
        source: "#Rectangle"
        z: -30000
        scale: Qt.vector3d(0.1, 0.1, 1)
        materials: CustomMaterial {
            shadingMode: CustomMaterial.Unshaded
            property TextureInput t0: TextureInput { texture: texRoseDark }
            property TextureInput t1: TextureInput { texture: texRoseLight }
            property TextureInput t2: TextureInput { texture: texGlowDark }
            property TextureInput t3: TextureInput { texture: texGlowLight }
            property TextureInput t4: TextureInput { texture: texFillDark }
            property TextureInput t5: TextureInput { texture: texFillLight }
            property TextureInput t6: TextureInput { texture: texCovDark }
            property TextureInput t7: TextureInput { texture: texCovLight }
            property TextureInput t8: TextureInput { texture: texWorldDark }
            property TextureInput t9: TextureInput { texture: texWorldLight }
            vertexShader: "shaders/pen.vert"
            fragmentShader: "shaders/keep.frag"
        }
    }

    Model {
        source: "#Rectangle"
        z: -20000
        scale: Qt.vector3d(19.2 * 10.9241, 10.8 * 10.9241, 1)
        materials: CustomMaterial {
            shadingMode: CustomMaterial.Unshaded
            property real bright: 1.0
            property real mixv: vault.turn.fired ? 1 : 0
            property real mixr: vault.turn.mixr
            property vector4d vframe: Qt.vector4d(vault.host.frame.x, vault.host.frame.y, vault.host.frame.width, vault.host.frame.height)
            property vector2d center: Qt.vector2d(vault.turn.cx, vault.turn.cy)
            property real stopR: vault.turn.stopR
            property real relR: vault.turn.relR
            property color ink: vault.turn.ink
            property color gold: vault.turn.gold
            property color hiCol: vault.turn.hiCol
            property real thrA: vault.turn.dawn ? 0.10 : 0.36
            property real thrB: vault.turn.dawn ? 0.46 : 0.74
            property real dim: vault.turn.dim
            property real cool: vault.turn.cool
            property vector3d coolTint: Qt.vector3d(0.42, 0.55, 1.0)
            property TextureInput room: TextureInput { texture: vault.texRoomL }
            property TextureInput roomA: TextureInput { texture: vault.texRoomA }
            property TextureInput vid: TextureInput { texture: texVid }
            vertexShader: "shaders/pen.vert"
            fragmentShader: "shaders/back.frag"
        }
    }

    Model {
        source: "#Rectangle"
        position: Qt.vector3d(vault.turn.cx - 960, 540 - vault.turn.cy, 5)
        scale: Qt.vector3d(14, 14, 1)
        visible: vault.turn.light > 0.001
        materials: CustomMaterial {
            shadingMode: CustomMaterial.Unshaded
            sourceBlend: CustomMaterial.One
            destinationBlend: CustomMaterial.One
            depthDrawMode: Material.NeverDepthDraw
            property color tint: vault.turn.hot
            property real power: vault.turn.light
            vertexShader: "shaders/pen.vert"
            fragmentShader: "shaders/glow.frag"
        }
    }

    Rosace {
        turn: vault.turn
        roseDarkTex: texRoseDark
        roseLightTex: texRoseLight
        glowDarkTex: texGlowDark
        glowLightTex: texGlowLight
        fillTex: vault.texFill
        fillCovTex: vault.texFillCov
    }

    Model {
        source: "#Rectangle"
        position: Qt.vector3d(vault.turn.cx - 960, 540 - vault.turn.cy, -80)
        scale: Qt.vector3d(38.4 * 1.04, 21.6 * 1.04, 1)
        visible: vault.turn.leak > 0.001
        materials: CustomMaterial {
            shadingMode: CustomMaterial.Unshaded
            sourceBlend: CustomMaterial.One
            destinationBlend: CustomMaterial.One
            depthDrawMode: Material.NeverDepthDraw
            property real power: vault.turn.leak
            property color tint: vault.turn.hot
            vertexShader: "shaders/pen.vert"
            fragmentShader: "shaders/leak.frag"
        }
    }

    Fracture {
        id: fracture
        turn: vault.turn
        mesh: vault.mesh
        printTex: texPrint
        maskTex: texMask
        cracksTex: texCracks
        deskTex: texDesk
        fillTex: vault.texFill
        fillCovTex: vault.texFillCov
        roomATex: vault.texRoomA
    }

    Model {
        geometry: fracture.geometry
        materials: CustomMaterial {
            shadingMode: CustomMaterial.Unshaded
            cullMode: Material.NoCulling
            property real t: vault.turn.t
            property real rb: vault.turn.rbOn
            property vector2d center: Qt.vector2d(vault.turn.cx, vault.turn.cy)
            property real landT: vault.turn.landT
            property real rbSpan: vault.turn.rbSpan
            property real rbK: vault.turn.rbK
            property real rbA0: vault.turn.rbA0
            property real mixv: vault.turn.fired ? 1 : 0
            property real mixr: vault.turn.mixr
            property vector4d vframe: Qt.vector4d(vault.host.frame.x, vault.host.frame.y, vault.host.frame.width, vault.host.frame.height)
            property real cool: vault.turn.cool
            property vector3d coolTint: Qt.vector3d(0.42, 0.55, 1.0)
            property real sweep: vault.turn.rbSweep
            property real glintK: vault.turn.rbGlint
            property color glintCol: vault.turn.dawn ? "#fff1d2" : "#e6efff"
            property real flashTau: 0.09
            property real flashI: vault.turn.dawn ? 1.0 : 0.8
            property real jointsL: vault.turn.rbJointsL
            property real jointsW: vault.turn.rbJointsW
            property real winP: vault.turn.rbWin
            property real jointsOn: vault.turn.rbJointsOn
            property color crackCol: vault.turn.hot
            property color haloCol: vault.turn.warm
            property color edgeCol: vault.turn.dawn ? "#fff1d6" : "#e8f0ff"
            property TextureInput desk: TextureInput { texture: texDesk }
            property TextureInput roomL: TextureInput { texture: vault.texRoomL }
            property TextureInput roomA: TextureInput { texture: vault.texRoomA }
            property TextureInput vid: TextureInput { texture: texVid }
            property TextureInput cracks: TextureInput { texture: texCracks }
            vertexShader: "shaders/pane.vert"
            fragmentShader: "shaders/pane.frag"
        }
    }

    Model {
        source: "#Rectangle"
        position: Qt.vector3d(vault.turn.cx - 960, 540 - vault.turn.cy, 3)
        scale: Qt.vector3d(38.4, 21.6, 1)
        visible: vault.turn.touchRing > 0.002
        materials: CustomMaterial {
            shadingMode: CustomMaterial.Unshaded
            sourceBlend: CustomMaterial.One
            destinationBlend: CustomMaterial.One
            depthDrawMode: Material.NeverDepthDraw
            property real radius: 470 + 1300 * vault.turn.outCubic(vault.turn.win(vault.turn.touchT, vault.turn.touchT + 0.45))
            property real thick: 5 + 8 * vault.turn.win(vault.turn.touchT, vault.turn.touchT + 0.45)
            property real power: vault.turn.touchRing
            property color tint: vault.turn.hiCol
            vertexShader: "shaders/pen.vert"
            fragmentShader: "shaders/ring.frag"
        }
    }

    Repeater3D {
        model: vault.turn.beats.length
        Model {
            required property int index
            readonly property real b: vault.turn.beats[index]
            source: "#Rectangle"
            position: Qt.vector3d(vault.turn.cx - 960, 540 - vault.turn.cy, 3)
            scale: Qt.vector3d(38.4, 21.6, 1)
            visible: vault.turn.t >= b && vault.turn.t < b + 0.45 && vault.turn.t < vault.turn.burstT
            materials: CustomMaterial {
                shadingMode: CustomMaterial.Unshaded
                sourceBlend: CustomMaterial.One
                destinationBlend: CustomMaterial.One
                depthDrawMode: Material.NeverDepthDraw
                property real radius: 506 * vault.turn.cscale + 300 * vault.turn.outCubic(vault.turn.win(b, b + 0.4))
                property real thick: 2.5 + 6 * vault.turn.win(b, b + 0.4)
                property real power: (0.5 + 0.08 * index) * vault.turn.decay(b, 0.12) * vault.turn.ringK
                property color tint: vault.turn.hlCol
                vertexShader: "shaders/pen.vert"
                fragmentShader: "shaders/ring.frag"
            }
        }
    }

    Model {
        source: "#Rectangle"
        position: Qt.vector3d(vault.turn.cx - 960, 540 - vault.turn.cy, 3)
        scale: Qt.vector3d(38.4, 21.6, 1)
        visible: vault.turn.landRing > 0.002
        materials: CustomMaterial {
            shadingMode: CustomMaterial.Unshaded
            sourceBlend: CustomMaterial.One
            destinationBlend: CustomMaterial.One
            depthDrawMode: Material.NeverDepthDraw
            property real radius: 90 + 1500 * vault.turn.outCubic(vault.turn.win(vault.turn.landT, vault.turn.landT + 0.55))
            property real thick: 3 + 7 * vault.turn.win(vault.turn.landT, vault.turn.landT + 0.55)
            property real power: vault.turn.landRing
            property color tint: vault.turn.hiCol
            vertexShader: "shaders/pen.vert"
            fragmentShader: "shaders/ring.frag"
        }
    }

    Landing {
        turn: vault.turn
    }

    Model {
        source: "#Rectangle"
        z: 4
        scale: Qt.vector3d(19.2 * (2015.3 - 4) / 2015.3, 10.8 * (2015.3 - 4) / 2015.3, 1)
        visible: vault.turn.lattice > 0.001
        materials: CustomMaterial {
            shadingMode: CustomMaterial.Unshaded
            sourceBlend: CustomMaterial.One
            destinationBlend: CustomMaterial.One
            depthDrawMode: Material.NeverDepthDraw
            property real power: vault.turn.lattice
            property real dissolve: vault.turn.win(vault.turn.burstT + 0.2, vault.turn.blastT + 0.2)
            property color tint: vault.turn.dawn ? "#ffc15a" : "#9dbcff"
            property TextureInput cracks: TextureInput { texture: texCracks }
            vertexShader: "shaders/pen.vert"
            fragmentShader: "shaders/lattice.frag"
        }
    }

    Burst {
        turn: vault.turn
        sparks: vault.sparks
    }
}
