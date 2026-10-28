import QtQuick
import qs.core
import qs.kit
import qs.parts.Chat

Item {
    id: field

    property real k: 1
    property point light: Qt.point(0, 0)
    readonly property bool dark: Theme.dark

    readonly property real up: Slumber.raised ? Slumber.out3(Slumber.span(Slumber.raisedAt, 0, 0.55)) : (Slumber.loweredAt > 0 ? 1 - Slumber.out3(Slumber.span(Slumber.loweredAt, 0, 0.45)) : 0)
    readonly property real wrongT: Slumber.since(Slumber.wrongAt)
    readonly property bool cracked: wrongT < 2.3
    readonly property real shakeX: wrongT < 0.7 ? 13 * k * Math.exp(-wrongT * 7.5) * Math.sin(wrongT * 2 * Math.PI * 8.5) : 0
    readonly property real hurt: wrongT < 1.6 ? 1 - Slumber.span(Slumber.wrongAt, 0.12, 1.3) : 0
    readonly property real gold: Slumber.acceptAt > 0 ? Slumber.out3(Slumber.span(Slumber.acceptAt, 0.05, 0.3)) : 0
    readonly property real checkGlow: Slumber.checking ? 0.5 + 0.5 * Math.sin(Slumber.since(Slumber.checkAt) * 2 * Math.PI * 1.1 - Math.PI / 2) : 0

    function mixc(a: color, b: color, t: real): color {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    implicitWidth: 430 * k
    implicitHeight: 60 * k
    visible: up > 0.001
    opacity: up

    Item {
        id: shaken
        width: field.width
        height: field.height
        x: field.shakeX
        y: (1 - field.up) * 22 * field.k

        Item {
            id: glass
            anchors.fill: parent

            Pane {
                id: fieldPane
                anchors.fill: parent
                radius: 13 * field.k
                rim: 3.2 * field.k
                band: 5 * field.k
                inner: 1.6 * field.k
                jewel: 16 * field.k
                cornerGlow: 0.35 + 0.5 * field.gold
                corner: field.dark ? "#e3a04a" : "#f6efe6"
                bodyTop: field.mixc(field.dark ? "#1f2a60" : "#2d36b8", field.dark ? "#5a1f3e" : "#8c1f3c", field.hurt * 0.55)
                bodyBottom: field.mixc(field.dark ? "#0f1436" : "#1c2088", field.dark ? "#2a0d22" : "#4c0f26", field.hurt * 0.55)
                jewelA: field.dark ? "#2e4790" : "#7b3a80"
                glassAlpha: 0.93
                lightPos: Qt.vector2d(field.light.x, field.light.y)
                lightZ: 200 * field.k
                lightPower: 0.32 + 0.25 * field.checkGlow
                lightRadius: 340 * field.k
                goldMix: field.gold
                flash: field.gold * 0.8
                haloSize: 16 * field.k
                lift: 0.25 * field.checkGlow
                shadow: 0.55
                sweep: Slumber.raised && Slumber.since(Slumber.raisedAt) < 0.9 ? Slumber.span(Slumber.raisedAt, 0.1, 0.75) : -1
                grainSize: 200 * field.k
            }

            Item {
                id: row
                anchors.fill: parent
                anchors.leftMargin: 34 * field.k
                anchors.rightMargin: 34 * field.k
                readonly property int n: Slumber.chars.length
                readonly property real gap: Math.min(25 * field.k, (width - 6 * field.k) / Math.max(1, n))

                Repeater {
                    model: Slumber.chars

                    Item {
                        id: g
                        required property var modelData
                        required property int index
                        readonly property real born: Slumber.out3(Slumber.span(modelData.at, 0, 0.22))
                        readonly property bool fell: modelData.gone > 0 && Math.abs(modelData.gone - Slumber.wrongAt) < 1
                        readonly property real gone: modelData.gone > 0 ? Slumber.span(modelData.gone, fell ? 0.06 : 0, fell ? 0.42 : 0.16) : 0
                        readonly property real flare: 1.4 * (1 - Slumber.span(modelData.at, 0, 0.4)) + 1.6 * Math.max(0, 1 - Math.abs(Slumber.since(Slumber.acceptAt) - 0.03 * index - 0.12) / 0.12) * (Slumber.acceptAt > 0 ? 1 : 0)
                        readonly property real run: Slumber.checking ? Math.max(0, Math.cos(Slumber.since(Slumber.checkAt) * 6.0 - index * 0.55)) : 0
                        readonly property real size: 26 * field.k

                        x: row.width / 2 + (index - (row.n - 1) / 2) * row.gap - size / 2
                        y: (row.height - size) / 2 + (fell ? 26 * field.k * gone * gone : 0)
                        width: size
                        height: size
                        opacity: 1 - gone
                        scale: (0.35 + 0.65 * born) * (fell ? 1 : 1 - 0.6 * gone)
                        rotation: fell ? (index % 2 ? 1 : -1) * 40 * gone : 0

                        Image {
                            anchors.centerIn: parent
                            width: parent.width * 1.5
                            height: width
                            source: field.dark ? Theme.of("dark", "lock-drop-glow.png") : Theme.of("light", "lock-star-glow.png")
                            smooth: true
                            mipmap: true
                            opacity: Math.min(1, (field.dark ? 0.3 : 0.2) + 0.45 * g.flare + 0.45 * g.run + 0.55 * field.gold)
                        }
                        Image {
                            anchors.fill: parent
                            source: field.dark ? Theme.of("dark", "lock-drop.png") : Theme.of("light", "lock-star.png")
                            smooth: true
                            mipmap: true
                        }
                    }
                }
            }
        }

        ShaderEffectSource {
            id: glassTex
            width: 2
            height: 2
            opacity: 0.01
            sourceItem: glass
            hideSource: field.cracked
            live: true
        }

        ShaderEffect {
            anchors.fill: parent
            visible: field.cracked
            property variant src: glassTex
            property vector2d box: Qt.vector2d(width, height)
            property vector2d impact: Qt.vector2d(width / 2 + 9 * field.k, height * 0.46)
            property real spread: Slumber.out3(Slumber.span(Slumber.wrongAt, 0, 0.13))
            property real heat: 1 - Slumber.span(Slumber.wrongAt, 0.04, 0.5)
            property real scar: 1 - Slumber.inOut3(Slumber.span(Slumber.wrongAt, 1.2, 1.05))
            property real shift: 1.6 * field.k * (1 - Slumber.inOut3(Slumber.span(Slumber.wrongAt, 1.25, 1.0)))
            property real seed: (Slumber.tries * 0.37) % 1
            property color hot: field.dark ? "#fff1d8" : "#fff4fb"
            property color cool: field.dark ? "#c9d3f2" : "#ffe7f3"
            fragmentShader: Qt.resolvedUrl("../../shaders/lock-crack.frag.qsb")
        }
    }
}
