import QtQuick
import qs.core
import qs.kit

Item {
    id: w

    property string side: "left"
    property real open: 1
    property real t: 1
    property real sweep: -1
    property real glint: -100000
    property bool cached: false
    property bool live: false
    property string glyph: ""
    property string motto: ""
    property Component rose: null
    default property alias content: body.data
    readonly property bool isLeft: w.side === "left"
    readonly property var spec: ({
            dark: {
                left: { plate: [80, 40, 540, 992], hinge: 583, outer: 104.5, edge: [200, 1013], hub: [342.8, 147.9], slot: [327, 200.2, 34, 33], glyph: 22 },
                right: { plate: [1300, 40, 540, 992], hinge: 1333, outer: 1813, edge: [200, 1013], hub: [1574.7, 147.8], slot: [1555.6, 200.4, 34, 33], glyph: 23 }
            },
            light: {
                left: { plate: [46, 10, 560, 1030], hinge: 578, outer: 61, edge: [290, 1023], hub: [338.6, 211], slot: [262.6, 135, 152, 152], glyph: 21, motto: [318.5, 1004.1] },
                right: { plate: [1316, 10, 560, 1030], hinge: 1342, outer: 1859, edge: [290, 1023], hub: [1584.5, 211], slot: [1508.5, 135, 152, 152], glyph: 23, motto: [1585.9, 1004.1] }
            }
        })[Theme.world][w.side]
    readonly property rect plate: Qt.rect(w.spec.plate[0], w.spec.plate[1], w.spec.plate[2], w.spec.plate[3])
    readonly property real hinge: w.spec.hinge
    readonly property real outer: w.spec.outer
    readonly property real edgeTop: w.spec.edge[0]
    readonly property real edgeBottom: w.spec.edge[1]
    readonly property point hub: Qt.point(w.spec.hub[0], w.spec.hub[1])
    readonly property real medal: Theme.dark ? 40 : 30.5
    readonly property rect roseSlot: Qt.rect(w.spec.slot[0], w.spec.slot[1], w.spec.slot[2], w.spec.slot[3])
    readonly property point light: Qt.point(w.isLeft ? 0.64 : 0.36, 0.19)
    readonly property real unit: Screens.unitOf(w)

    function a(name: string): url {
        return Theme.a("sanctum-wing-" + w.side + name + ".png");
    }
    readonly property bool skinned: Assets.url("wings/skin/" + Theme.world + "/" + w.side + ".png") !== ""
    function skin(name: string): string {
        return w.skinned ? Assets.url("wings/skin/" + Theme.world + "/" + w.side + name + ".png") : "";
    }

    x: w.plate.x
    y: w.plate.y
    width: w.plate.width
    height: w.plate.height
    opacity: Math.min(1, w.open * 2.2)
    transform: Rotation {
        origin.x: w.hinge - w.plate.x
        origin.y: w.height / 2
        axis {
            x: 0
            y: 1
            z: 0
        }
        angle: (w.isLeft ? 1 : -1) * 84 * (1 - w.open)
    }

    Item {
        id: panel
        anchors.fill: parent
        layer.enabled: w.cached
        layer.smooth: true
        layer.textureSize: Qt.size(width * w.unit, height * w.unit)

        Glass {
            visible: !w.skinned
            anchors.fill: parent
            src: w.a("-glow")
            additive: 1
            ambient: 0
            power: Theme.dark ? 0.26 : 0.34
            radius: 2
            light: w.light
            grain: 0
        }
        Glass {
            visible: !w.skinned
            anchors.fill: parent
            src: w.a("")
            light: w.light
            radius: 0.36
            power: Theme.dark ? 0.46 : 0.52
            ambient: Theme.dark ? 0.66 : 0.7
            grain: 0.12
        }
        Skin {
            visible: w.skinned
            anchors.fill: parent
            side: w.side
            light: w.light
            rect: Qt.vector4d(w.plate.x, w.plate.y, w.plate.width, w.plate.height)
            glint: w.glint
            sweep: w.sweep
        }
        Glass {
            visible: !w.skinned
            anchors.fill: parent
            src: w.a("-jewels-glow")
            additive: 1
            ambient: 0
            power: Theme.dark ? 0.42 : 0.36
            radius: 2
            grain: 0
        }
        ShaderEffect {
            anchors.fill: parent
            property variant lightMap: Image { source: w.skin("-lights") || w.a("-lights"); visible: false; smooth: true; mipmap: true }
            property variant glowMap: Image { source: w.skin("-lights-glow") || w.a("-lights-glow"); visible: false; smooth: true }
            property variant orderMap: Image { source: w.a("-lights-order"); visible: false; smooth: true }
            property variant grainTex: ShaderEffectSource {
                sourceItem: Image { source: Theme.shared("glass-noise.png") }
                hideSource: true
                visible: false
                wrapMode: ShaderEffectSource.Repeat
            }
            property real t: w.t
            property real start: 0.4
            property real spread: 0.46
            property real span: 0.12
            property real rest: Theme.dark ? 0.46 : 0.38
            property real lit: Theme.dark ? 1.02 : 0.96
            property real flare: Theme.dark ? 0.5 : 0.42
            property real glow: Theme.dark ? 0.7 : 0.55
            property real grain: 0.1
            property size grainScale: Qt.size(width / 256, height / 256)
            fragmentShader: Qt.resolvedUrl("../../shaders/sanctum-lights.frag.qsb")
        }
        Iron {
            visible: !w.skinned
            anchors.fill: parent
            src: w.a("-lead")
            lx: w.isLeft ? 0.74 : 0.26
            ly: -0.3
            depth: Theme.dark ? 6.4 : 7.0
            shininess: Theme.dark ? 38 : 44
            metal: Theme.dark ? 0.9 : 1.0
            base: Theme.dark ? "#a67c3f" : "#d3a24f"
            hi: Theme.dark ? "#f3f0ff" : "#fff6dc"
            low: Theme.dark ? "#0e0a0b" : "#4a2a12"
            sky: Theme.dark ? "#9aa2d2" : "#ffe2a2"
            rect: Qt.vector4d(w.plate.x, w.plate.y, w.plate.width, w.plate.height)
            glint: w.glint
        }
        Gilt {
            visible: !w.skinned
            anchors.fill: parent
            src: w.a("-gilt")
            lx: w.isLeft ? 0.72 : 0.28
            ly: -0.25
            depth: 6.6
            hi: Theme.dark ? "#fbf7ff" : "#fff4cf"
            sky: Theme.dark ? "#d9d4f2" : "#f7dfa4"
            sweep: w.sweep
        }
        MouseArea {
            anchors.fill: parent
        }
        Item {
            id: body
            x: -w.plate.x
            y: -w.plate.y
            width: Screens.design.width
            height: Screens.design.height
        }

        Text {
            visible: w.motto !== "" && !!w.spec.motto
            x: (w.spec.motto ? w.spec.motto[0] : 0) - width / 2 + font.letterSpacing / 2 - w.plate.x
            y: (w.spec.motto ? w.spec.motto[1] : 0) - baselineOffset - w.plate.y
            text: w.motto
            font.family: Theme.caps
            font.pixelSize: 18
            font.letterSpacing: 7.9
            font.weight: Font.Bold
            color: "#d9a95c"
            style: Text.Raised
            styleColor: "#1d1209"
        }
    }

    Loader {
        id: slot
        x: w.roseSlot.x + w.roseSlot.width / 2 - w.plate.x - width / 2
        y: w.roseSlot.y + w.roseSlot.height / 2 - w.plate.y - height / 2
        scale: w.roseSlot.width / Math.max(1, width)
        sourceComponent: w.rose
    }
    Binding {
        when: slot.status === Loader.Ready
        target: slot.item
        property: "open"
        value: w.open
    }
    Binding {
        when: slot.status === Loader.Ready
        target: slot.item
        property: "sweep"
        value: w.sweep
    }
    Binding {
        when: slot.status === Loader.Ready
        target: slot.item
        property: "glint"
        value: w.glint
    }
    Binding {
        when: slot.status === Loader.Ready
        target: slot.item
        property: "live"
        value: w.live
    }
    Binding {
        when: slot.status === Loader.Ready
        target: slot.item
        property: "side"
        value: w.side
    }
    Binding {
        when: slot.status === Loader.Ready
        target: slot.item
        property: "rect"
        value: Qt.vector4d(w.roseSlot.x, w.roseSlot.y, w.roseSlot.width, w.roseSlot.height)
    }

    Piece {
        id: medal
        visible: !w.skinned
        name: "sanctum-medal"
        width: 2 * (w.medal + 6)
        height: width
        x: w.hub.x - w.plate.x - width / 2
        y: w.hub.y - w.plate.y - height / 2
        power: 0.6
        ambient: 0.62
        glow: 0.38
        sweep: w.sweep
    }
    Gilt {
        visible: !w.skinned
        anchors.fill: medal
        src: Theme.a("sanctum-medal-gilt.png")
        lx: 0.25
        ly: -0.5
        sweep: w.sweep
    }
    Text {
        x: w.hub.x - w.plate.x - width / 2
        y: w.hub.y - w.plate.y - height / 2
        text: w.glyph
        font.family: Theme.glyphs
        font.pixelSize: w.spec.glyph
        color: Theme.dark ? Theme.rare : Theme.sun
    }
}
