import QtQuick
import Quickshell
import qs.core
import qs.kit

Item {
    id: c

    property real rise: 1
    property real herRise: 1
    property real bloom: 1
    property real sweep: -1
    property real glint: -100000
    property bool turning: false
    readonly property real cx: 380
    readonly property real pad: 170
    readonly property point sun: Qt.point(380, 236)
    readonly property color gold: Theme.dark ? Theme.rare : Theme.sun
    readonly property color light: Theme.dark ? "#cfd8ec" : "#ffd48a"
    readonly property var her: Theme.dark ? {
        size: Rite.herSize, head: 0.49, top: 64,
        a: Qt.vector4d(0.49, 0.12, 0.2, 0.15), b: Qt.vector4d(0.2, 0.29, 0.15, 0.24),
        potion: Qt.point(0.215, 0.25), potionTint: "#9d8cff"
    } : {
        size: Rite.herSize, head: 0.4, top: 70,
        a: Qt.vector4d(0.4, 0.13, 0.22, 0.16), b: Qt.vector4d(0.8, 0.25, 0.17, 0.27),
        potion: Qt.point(0.755, 0.17), potionTint: "#ffc35a"
    }

    readonly property bool skinned: Assets.url("wings/skin/" + Theme.world + "/centre-frame.png") !== ""
    function skin(name: string): string {
        return c.skinned ? Assets.url("wings/skin/" + Theme.world + "/centre-" + name + ".png") : "";
    }

    readonly property real unit: Screens.unitOf(c)
    width: 760
    height: 1080
    opacity: Math.min(1, c.rise * 1.6)
    transform: Translate {
        y: (1 - c.rise) * 36
    }

    MouseArea {
        x: 90
        y: 150
        width: 580
        height: 910
    }

    Image {
        id: windowMask
        source: Theme.a("sanctum-window.png")
        visible: false
    }

    Item {
        id: back
        x: -c.pad
        width: c.width + 2 * c.pad
        height: c.height
        layer.enabled: c.turning
        layer.textureSize: Qt.size(width * c.unit, height * c.unit)
        Item {
        x: c.pad
        width: c.width
        height: c.height
        Glow {
            x: c.sun.x - 430
            y: c.sun.y - 400
            width: 860
            height: 860
            color: c.light
            core: 0.16
            intensity: (Theme.dark ? 0.42 : 0.5) * c.bloom
        }
        Glass {
            visible: !c.skinned
            anchors.fill: parent
            src: Theme.a("sanctum-sun.png")
            light: Qt.point(c.sun.x / c.width, c.sun.y / c.height)
            aspect: c.width / c.height
            radius: 0.36
            power: (Theme.dark ? 1.05 : 1.15) * Math.max(0.35, c.bloom)
            ambient: Theme.dark ? 0.42 : 0.5
            grain: 0.16
        }
        Iron {
            visible: !c.skinned
            anchors.fill: parent
            src: Theme.a("sanctum-sun-lead.png")
            lx: 0.5
            ly: 0.05
            depth: 3.2
        }
        Glass {
            visible: c.skinned
            anchors.fill: parent
            src: c.skin("window")
            light: Qt.point(c.sun.x / c.width, c.sun.y / c.height)
            aspect: c.width / c.height
            radius: 0.36
            power: (Theme.dark ? 1.2 : 0.55) * Math.max(0.35, c.bloom)
            ambient: Theme.dark ? 0.78 : 1.0
            grain: 0.06
        }
        Glass {
            anchors.fill: parent
            src: Theme.a("sanctum-arch-glass-glow.png")
            additive: 1
            ambient: 0
            power: 0.55 * c.bloom
            radius: 2
            grain: 0
        }
        Glass {
            visible: !c.skinned
            anchors.fill: parent
            src: Theme.a("sanctum-arch-glass.png")
            light: Qt.point(0.5, 0.55)
            radius: 0.6
            power: 0.65
            ambient: 0.62
        }
        }
    }

    ShaderEffect {
        id: circleFx
        readonly property real size: 420
        x: c.cx - size / 2
        y: 416 - size / 2
        width: size
        height: size
        visible: opacity > 0.01
        opacity: Math.max(0, Math.min(1, (c.bloom - 0.3) * 1.6))
        property vector4d winRect: Qt.vector4d(x / c.width, y / c.height, width / c.width, height / c.height)
        property vector4d tint: Theme.dark ? Qt.vector4d(0.62, 0.72, 0.98, 1) : Qt.vector4d(1.0, 0.82, 0.48, 1)
        property vector4d glowTint: Theme.dark ? Qt.vector4d(0.42, 0.5, 0.95, 1) : Qt.vector4d(1.0, 0.62, 0.3, 1)
        property real outerAngle: 0
        property real innerAngle: 0
        property real intensity: Theme.dark ? 0.85 : 0.9
        property variant outer: Image { source: Theme.shared("sanctum-circle-outer.png"); visible: false; mipmap: true; smooth: true }
        property variant outerGlow: Image { source: Theme.shared("sanctum-circle-outer-glow.png"); visible: false; smooth: true }
        property variant inner: Image { source: Theme.shared("sanctum-circle-inner.png"); visible: false; mipmap: true; smooth: true }
        property variant innerGlow: Image { source: Theme.shared("sanctum-circle-inner-glow.png"); visible: false; smooth: true }
        property variant win: windowMask
        fragmentShader: Qt.resolvedUrl("../../shaders/sanctum-circle.frag.qsb")
    }
    readonly property real epoch: Date.now()
    Timer {
        interval: 83
        repeat: true
        running: c.turning
        onTriggered: {
            const s = (Date.now() - c.epoch) / 1000;
            circleFx.outerAngle = s * 0.035;
            circleFx.innerAngle = -s * 0.052;
        }
    }

    Item {
        id: front
        x: -c.pad
        width: c.width + 2 * c.pad
        height: c.height
        layer.enabled: c.turning
        layer.textureSize: Qt.size(width * c.unit, height * c.unit)
        Item {
        x: c.pad
        width: c.width
        height: c.height

        Glow {
            visible: herFx.visible
            x: herFx.x + herFx.width * c.her.potion.x - 120
            y: herFx.y + herFx.height * c.her.potion.y - 120
            width: 240
            height: 240
            color: c.her.potionTint
            core: 0.12
            intensity: 0.55 * c.bloom
        }
        Iron {
            visible: !c.skinned
            anchors.fill: parent
            src: Theme.a("sanctum-arch-iron.png")
            lx: 0.35
            ly: -0.25
            depth: 4.5
            rect: Qt.vector4d(c.x, c.y, c.width, c.height)
            glint: c.glint
        }
        Glass {
            anchors.fill: parent
            src: c.skin("frame-glow") || Theme.a("sanctum-halo-glow.png")
            additive: 1
            ambient: 0
            power: 0.7 * c.bloom
            radius: 2
            grain: 0
        }
        Iron {
            visible: !c.skinned
            anchors.fill: parent
            src: Theme.a("sanctum-halo.png")
            lx: 0.5
            ly: -0.1
            depth: 4
            rect: Qt.vector4d(c.x, c.y, c.width, c.height)
            glint: c.glint
            base: Theme.dark ? "#a7aec6" : "#c99a4e"
            hi: Theme.dark ? "#ffffff" : "#fff4cf"
            low: Theme.dark ? "#1b1e31" : "#3b2410"
            sky: Theme.dark ? "#e0e7ff" : "#f7dfa4"
            metal: 1.0
            shininess: Theme.dark ? 48 : 42
        }
        Glass {
            visible: c.skinned
            anchors.fill: parent
            src: c.skin("frame")
            light: Qt.point(0.5, 0.2)
            radius: 0.6
            power: Theme.dark ? 0.16 : 0.12
            ambient: Theme.dark ? 1.0 : 0.98
            grain: 0
        }
        Sheen {
            visible: c.skinned
            anchors.fill: parent
            heightSrc: c.skin("frame-lead")
            colorSrc: c.skin("frame")
            light: Qt.point(0.5, -0.1)
            rect: Qt.vector4d(c.x, c.y, c.width, c.height)
            glint: c.glint
            sweep: c.sweep
            gain: Theme.dark ? 0.85 : 0.7
            rest: Theme.dark ? 0.1 : 0.08
        }

        ShaderEffect {
            id: herFx
            readonly property string url: Assets.url("heroine/cut/menu-" + World.name + ".png")
            visible: url !== ""
            width: c.her.size
            height: c.her.size
            x: c.cx - c.her.head * c.her.size
            y: c.her.top + (1 - c.herRise) * 46
            opacity: Math.min(1, c.herRise * 1.8)
            property vector4d winRect: Qt.vector4d(x / c.width, y / c.height, width / c.width, height / c.height)
            property vector4d breakA: c.her.a
            property vector4d breakB: c.her.b
            property vector4d rimColor: Theme.dark ? Qt.vector4d(0.62, 0.7, 1.0, 1) : Qt.vector4d(1.0, 0.8, 0.45, 1)
            property point lightAt: Qt.point((c.sun.x - x) / width, (c.sun.y - y) / height)
            property point texel: Qt.point(1 / Rite.herPx, 1 / Rite.herPx)
            property real rim: Theme.dark ? 0.9 : 1.0
            property real feather: 0.3
            property variant her: Image { source: herFx.url; visible: false; smooth: true; sourceSize: Qt.size(Rite.herPx, Rite.herPx) }
            property variant win: windowMask
            fragmentShader: Qt.resolvedUrl("../../shaders/sanctum-her.frag.qsb")
        }

        Piece {
            id: crest
            visible: !c.skinned
            name: "sanctum-crest"
            width: 92
            height: 92
            x: c.cx - 46
            y: -4
            power: 0.6
            ambient: 0.62
            glow: 0.45 * c.bloom
            sweep: c.sweep
        }
        Gilt {
            visible: !c.skinned
            anchors.fill: crest
            src: Theme.a("sanctum-crest-gilt.png")
            lx: 0.25
            ly: -0.5
            sweep: c.sweep
        }
        Text {
            anchors.centerIn: crest
            anchors.verticalCenterOffset: Theme.dark ? -1 : 0
            text: Theme.dark ? "月" : "陽"
            font.family: Theme.jp
            font.weight: Theme.dark ? Font.ExtraBold : Font.Normal
            font.pixelSize: Theme.dark ? 30 : 27
            color: Theme.dark ? "#eef1fb" : Theme.ink
            renderType: Text.CurveRendering
        }
        Text {
            visible: !Theme.dark
            anchors.right: crest.left
            anchors.rightMargin: -6
            anchors.verticalCenter: crest.verticalCenter
            text: "【"
            font.family: Theme.jp
            font.pixelSize: 40
            color: Theme.lamp
        }
        Text {
            visible: !Theme.dark
            anchors.left: crest.right
            anchors.leftMargin: -6
            anchors.verticalCenter: crest.verticalCenter
            text: "】"
            font.family: Theme.jp
            font.pixelSize: 40
            color: Theme.lamp
        }

        Predella {
            x: 226
            y: 992
            sweep: c.sweep
            glint: c.glint
            stageX: c.x + 226
        }
        }
    }
}
