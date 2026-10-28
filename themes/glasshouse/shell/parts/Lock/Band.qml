import QtQuick
import Quickshell
import qs.core
import qs.kit
import qs.parts.Chat

Item {
    id: strip

    property real k: 1
    property real rise: 1
    property real sweep: -1
    property point light: Qt.point(0, 0)
    readonly property bool dark: Theme.dark
    readonly property var title: dark ? ["星", "降", "る", "夜"] : ["︻", "陽", "だ", "ま", "り", "︼"]
    readonly property real crest: 100 * k
    readonly property real glyph: (dark ? 50 : 44) * k
    readonly property real step: (dark ? 62 : 54) * k
    readonly property real titleH: title.length * step

    implicitWidth: 92 * k
    implicitHeight: crest * 0.62 + 30 * k + titleH + 58 * k + 44 * k

    opacity: rise
    transform: Translate {
        y: (1 - strip.rise) * 34 * strip.k
    }

    Pane {
        id: glassPane
        x: 0
        y: strip.crest * 0.42
        width: strip.width
        height: strip.height - y - 44 * strip.k
        radius: width / 2
        rim: 3.4 * strip.k
        band: 7 * strip.k
        inner: 1.8 * strip.k
        jewel: 0
        bodyTop: strip.dark ? "#1d2a62" : "#2a33b4"
        bodyBottom: strip.dark ? "#0e1334" : "#1b1f80"
        jewelA: strip.dark ? "#4a5fcf" : "#c8417e"
        lift: 0.35
        glassAlpha: 0.94
        lightPos: Qt.vector2d(strip.light.x - x, strip.light.y - y)
        lightZ: 260 * strip.k
        lightPower: 0.42
        lightRadius: 420 * strip.k
        shadow: 0.55
        sweep: strip.sweep
        grainSize: 220 * strip.k
    }

    Rectangle {
        anchors.horizontalCenter: glassPane.horizontalCenter
        y: glassPane.y + glassPane.height - 2 * strip.k
        width: 2 * strip.k
        height: 12 * strip.k
        color: strip.dark ? "#2a2940" : "#8c6a33"
    }
    Pane {
        anchors.horizontalCenter: glassPane.horizontalCenter
        y: glassPane.y + glassPane.height + 8 * strip.k
        width: 22 * strip.k
        height: 30 * strip.k
        chamfer: 10 * strip.k
        rim: 2.4 * strip.k
        band: 0
        bodyTop: strip.dark ? "#ffd59a" : "#ff6fb4"
        bodyBottom: strip.dark ? "#c9772e" : "#b8105e"
        glassAlpha: 1
        lightPos: Qt.vector2d(strip.light.x - x, strip.light.y - y)
        lightZ: 120 * strip.k
        lightPower: 0.5
        lightRadius: 200 * strip.k
        shadow: 0.5
        lift: 0.4
        sweep: strip.sweep
    }

    Column {
        id: words
        anchors.horizontalCenter: glassPane.horizontalCenter
        y: glassPane.y + strip.crest * 0.62 + 18 * strip.k
        spacing: 0

        Repeater {
            model: strip.title

            Item {
                required property string modelData
                required property int index
                readonly property bool bracket: modelData === "︻" || modelData === "︼"
                width: strip.width
                height: strip.step

                Glow {
                    anchors.centerIn: parent
                    width: strip.glyph * 1.9
                    height: strip.glyph * 1.9
                    color: strip.dark ? "#8ea2e8" : (parent.bracket ? "#e41480" : "#ffd48a")
                    core: 0.3
                    intensity: strip.dark ? 0.16 : 0.14
                }
                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: parent.bracket ? (parent.index === 0 ? 8 : -8) * strip.k : 0
                    text: parent.modelData
                    font.family: parent.bracket ? "Noto Sans CJK JP" : Theme.jp
                    font.weight: strip.dark ? Font.ExtraBold : Font.Normal
                    font.pixelSize: parent.bracket ? strip.glyph * 0.86 : strip.glyph
                    color: parent.bracket ? "#ff3d9e" : (strip.dark ? "#f4ecdf" : "#fff8ec")
                    renderType: Text.CurveRendering
                }
            }
        }
    }

    Item {
        id: roundel
        width: strip.crest
        height: strip.crest
        anchors.horizontalCenter: glassPane.horizontalCenter
        y: 0
        layer.enabled: true
        layer.smooth: true
        layer.mipmap: true
        layer.textureSize: Qt.size(2 * width, 2 * height)

        Piece {
            anchors.fill: parent
            name: "chrome-crest"
            power: 0.85
            ambient: 0.6
            glow: 0.55
            light: Qt.point(0.42, 0.3)
            sweep: strip.sweep
        }
        Gilt {
            visible: !strip.dark
            anchors.fill: parent
            src: Theme.a("chrome-crest-gilt.png")
            lx: 0.25
            ly: -0.5
            depth: 3
            sweep: strip.sweep
        }
        Glow {
            visible: strip.dark
            anchors.centerIn: parent
            width: parent.width * 0.9
            height: width
            color: "#9fb3ea"
            core: 0.2
            intensity: 0.32
        }
        ShaderEffect {
            visible: strip.dark
            anchors.centerIn: parent
            width: parent.width * 0.44
            height: width
            property real phase: strip.moonPhase
            property color lit: "#e6ecfa"
            property color dark: "#151b44"
            fragmentShader: Qt.resolvedUrl("../../shaders/moon.frag.qsb")
        }
        Image {
            visible: !strip.dark
            anchors.centerIn: parent
            width: parent.width * 0.62
            height: width
            source: strip.dark ? "" : Theme.a("lock-sun-glow.png")
            smooth: true
            mipmap: true
            opacity: 0.8
        }
        Image {
            visible: !strip.dark
            anchors.centerIn: parent
            width: parent.width * 0.5
            height: width
            source: strip.dark ? "" : Theme.a("lock-sun.png")
            smooth: true
            mipmap: true
        }
    }

    readonly property real moonPhase: {
        const date = hour.date;
        const rad = Math.PI / 180;
        const T = (date.getTime() / 86400000 + 2440587.5 - 2451545.0) / 36525;
        const n = x => ((x % 360) + 360) % 360;
        const D = n(297.8501921 + 445267.1114034 * T);
        const M = n(357.5291092 + 35999.0502909 * T);
        const Mp = n(134.9633964 + 477198.8675055 * T);
        const e = D + 6.289 * Math.sin(Mp * rad) - 2.100 * Math.sin(M * rad) + 1.274 * Math.sin((2 * D - Mp) * rad) + 0.658 * Math.sin(2 * D * rad) + 0.214 * Math.sin(2 * Mp * rad) + 0.110 * Math.sin(D * rad);
        return n(e) / 360;
    }
    SystemClock {
        id: hour
        precision: SystemClock.Hours
    }
}
