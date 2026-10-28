import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.core
import qs.kit
import qs.parts.World
import qs.parts.Chat

Item {
    id: body

    required property string output
    property bool frozen: false
    property bool bake: false
    readonly property string role: Screens.role(output)
    readonly property bool main: role === "main"
    readonly property bool side: role === "side"
    readonly property real k: Screens.fit(width, height)
    readonly property var out: Stage.of(output)
    readonly property real fx: out ? out.farX : -(width * (Stage.k - 1)) / 2
    readonly property real fy: out ? out.fy : 0
    readonly property real fw: out ? out.fw : Math.round(width * Stage.k)
    readonly property real fh: out ? out.fh : Math.round(width * Stage.k * 9 / 16)
    readonly property real s: fw / Stage.source.width
    readonly property string world: World.name
    readonly property bool dark: Theme.dark
    readonly property bool ready: room.ready
    readonly property double began: frozen ? 0 : Slumber.began

    function inn(delay: real, dur: real): real {
        return body.frozen || body.bake ? 1 : Slumber.out3(Slumber.span(Slumber.introAt, delay, dur));
    }
    function at(sx: real, sy: real): point {
        return Qt.point(body.fx + sx * body.s, body.fy + sy * body.s);
    }

    readonly property point lightAt: dark ? at(894.67, 768) : at(1306.67, 213.33)

    Rectangle {
        visible: !body.bake
        anchors.fill: parent
        color: Theme.ground
    }

    Item {
        id: room
        visible: !body.bake

        readonly property string startUrl: body.main ? Assets.room(body.world) : (body.side ? Assets.diner(body.world) : "")
        readonly property string asleepUrl: body.main ? Assets.asleep(body.world) : ""
        readonly property string clipUrl: body.main && !body.frozen ? Assets.clip("room-" + body.world + "-sleep") : ""
        readonly property bool plain: Assets.ready && startUrl === ""
        readonly property bool ready: plain || (start.ready && (asleepUrl === "" || asleep.status === Image.Ready))
        property double clipAt: -1
        readonly property real clipIn: clipAt < 0 ? 0 : Slumber.span(clipAt, 0, 0.18)
        readonly property real asleepIn: body.frozen ? (Slumber.asleep ? 1 : 0) : (Slumber.asleep ? Slumber.inOut3(Slumber.span(Slumber.asleepAt, 0, 0.45)) : 0)

        x: body.fx
        y: body.fy
        width: body.fw
        height: body.fh

        Pose {
            id: start
            x: -body.fx
            y: -body.fy
            width: body.width
            height: body.height
            output: body.output
            settle: body.frozen ? 0 : 1 - Slumber.out3(Slumber.span(Slumber.began, 0.05, 0.45))
            visible: room.startUrl !== "" && (room.asleepUrl === "" || (room.asleepIn < 1 && room.clipIn < 1))
        }

        Loader {
            id: clipLoader
            anchors.fill: parent
            active: room.clipUrl !== "" && Slumber.engaged && !body.frozen && room.asleepIn < 1 && Slumber.since(Slumber.began) > 0.55
            sourceComponent: Clip {
                source: room.clipUrl
                from: 0
                until: 5.72
                go: true
                opacity: room.clipIn
                onShown: {
                    room.clipAt = Date.now();
                    Slumber.intro();
                }
                onFinished: Slumber.fallAsleep()
            }
        }

        Image {
            id: asleep
            anchors.fill: parent
            source: room.asleepUrl
            sourceSize: Qt.size(body.fw, body.fh)
            asynchronous: false
            cache: true
            smooth: true
            opacity: room.asleepIn
            visible: opacity > 0
        }

        ShaderEffect {
            id: lantern
            readonly property point c: Qt.point(894.67 * body.s, 741.33 * body.s)
            visible: body.dark && body.main && asleep.visible && asleep.status === Image.Ready
            x: Math.round(c.x - width * 0.5)
            y: Math.round(c.y - height * 0.58)
            width: Math.round(560 * body.k)
            height: Math.round(470 * body.k)
            property variant still: asleep
            property vector4d map: Qt.vector4d(x / room.width, y / room.height, width / room.width, height / room.height)
            property vector2d flame: Qt.vector2d((894.67 * body.s - x) / width, (768 * body.s - y) / height)
            property real aspect: width / Math.max(1, height)
            property real t: body.frozen || !visible ? 3.1 : Slumber.life
            property real seed: 0.37
            property real reach: 0.5
            property real gain: 0.5
            property real flicker: 0.5
            property real level: body.frozen ? 1 : Slumber.span(Slumber.asleepAt, 0.2, 1.2) * (Slumber.deep ? 0.4 : 1)
            property vector4d warm: Qt.vector4d(1.0, 0.66, 0.42, 1)
            property color hot: "#ffc890"
            property real bloom: 0.035
            fragmentShader: Qt.resolvedUrl("../../shaders/lock-lantern.frag.qsb")
        }

        ShaderEffect {
            visible: body.dark && body.main && asleep.visible && !body.bake
            x: 693.33 * body.s
            y: 333.33 * body.s
            width: 440 * body.s
            height: 480 * body.s
            opacity: room.asleepIn * (body.frozen ? 1 : Slumber.span(Slumber.asleepAt, 0.6, 2.0))
            property real t: body.frozen || !visible ? 2.5 : Slumber.life
            property real seed: 7
            property real count: 7
            property vector2d area: Qt.vector2d(width, height)
            property vector2d drift: Qt.vector2d(2, -9).times(body.k)
            property real wander: 16 * body.k
            property real blink: 7
            property real duty: 0.8
            property real size: 1.3 * body.k
            property real halo: 7 * body.k
            property color colA: "#ff9a5c"
            property color colB: "#ffd2a0"
            property real mixB: 0.3
            property vector4d beam: Qt.vector4d(0, 0, 1, 0)
            property real beamAmt: 0
            property real edge: 40 * body.k
            property real power: 0.95
            fragmentShader: Qt.resolvedUrl("../../shaders/world-motes.frag.qsb")
        }

        Repeater {
            model: !body.dark && body.main && asleep.visible ? [[180, 120, 520, 800, 5], [1660, 80, 700, 980, 9]] : []
            ShaderEffect {
                required property var modelData
                x: modelData[0] * body.s
                y: modelData[1] * body.s
                width: modelData[2] * body.s
                height: modelData[3] * body.s
                opacity: room.asleepIn * (body.frozen ? 1 : Slumber.span(Slumber.asleepAt, 0.3, 1.5))
                property real t: body.frozen || !visible ? 4 : Slumber.life * 0.7
                property real seed: modelData[4]
                property real count: 12
                property vector2d area: Qt.vector2d(width, height)
                property vector2d drift: Qt.vector2d(3, 5).times(body.k)
                property real wander: 12 * body.k
                property real blink: 3.6
                property real duty: 0.55
                property real size: 1.1 * body.k
                property real halo: 4.5 * body.k
                property color colA: "#fff4d6"
                property color colB: "#ffd48a"
                property real mixB: 0.4
                property vector4d beam: Qt.vector4d(0.62, -0.78, 70 * body.k, 0)
                property real beamAmt: 0.8
                property real edge: 50 * body.k
                property real power: 1.0
                fragmentShader: Qt.resolvedUrl("../../shaders/world-motes.frag.qsb")
            }
        }
    }

    Glow {
        visible: !body.bake && (room.plain || body.role === "")
        x: (parent.width - width) / 2
        y: -height * 0.34
        width: parent.width * 1.4
        height: parent.height * 1.5
        color: body.dark ? "#6577bd" : "#ffd48a"
        core: 0.45
        intensity: body.dark ? 0.18 : 0.22
    }

    Rectangle {
        visible: body.dark && body.role !== ""
        anchors.fill: parent
        opacity: body.inn(0.2, 1.8)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 0.5; color: "#000f1226" }
            GradientStop { position: 1.0; color: body.side ? "#990f1226" : "#a60f1226" }
        }
    }
    Glow {
        visible: !body.dark && body.main && !body.bake
        x: time.x + time.width / 2 - width / 2
        y: time.y + time.height * 0.62 - height / 2
        width: 1120 * body.k
        height: 640 * body.k
        color: "#fff1d6"
        core: 0.5
        intensity: 0.4 * body.inn(0.1, 1.8)
    }
    Rectangle {
        visible: body.side
        anchors.fill: parent
        color: body.dark ? "#0b0d1e" : "#1b1d5e"
        opacity: (body.dark ? 0.5 : 0.36) * (body.frozen || body.bake ? 1 : Slumber.inOut3(Slumber.span(Slumber.introAt, 0.1, 1.8)))
    }
    Shape {
        visible: body.bake && !body.dark && body.main
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: column.edge - 215 * body.k
                centerY: body.height * 0.255 + 150 * body.k
                centerRadius: 520 * body.k
                focalX: centerX
                focalY: centerY
                GradientStop { position: 0.0; color: Qt.rgba(1, 0.97, 0.88, 0.62) }
                GradientStop { position: 0.55; color: Qt.rgba(1, 0.96, 0.86, 0.32) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 0.96, 0.86, 0.0) }
            }
            PathRectangle {
                x: 0
                y: 0
                width: body.width
                height: body.height
            }
        }
    }

    Item {
        id: frame
        visible: body.role !== ""
        anchors.fill: parent
        opacity: body.inn(0.15, 1.2)
        layer.enabled: true

        Pane {
            anchors.fill: parent
            anchors.margins: 20 * body.k
            hollow: 1
            radius: 16 * body.k
            rim: 3.0 * body.k
            band: 7 * body.k
            inner: 1.6 * body.k
            jewel: 24 * body.k
            cornerGlow: 0.55
            corner: body.dark ? "#e3a04a" : "#f6efe6"
            jewelA: body.dark ? "#2e4790" : "#7b3a80"
            lightPos: Qt.vector2d(body.lightAt.x - 20 * body.k, body.lightAt.y - 20 * body.k)
            lightZ: 600 * body.k
            lightPower: 0.45
            lightRadius: 1100 * body.k
            shadow: 0.4
        }
    }

    Band {
        id: band
        visible: body.role !== ""
        k: body.k
        x: body.width - 52 * body.k - width
        y: body.height * 0.135
        width: implicitWidth
        height: implicitHeight
        rise: body.inn(0.7, 0.9)
        sweep: !body.frozen && !body.bake && Slumber.since(Slumber.introAt) > 0.8 && Slumber.since(Slumber.introAt) < 2.1 ? Slumber.span(Slumber.introAt, 0.85, 1.1) : -1
        light: Qt.point(body.lightAt.x - x, body.lightAt.y - y)
    }

    Item {
        id: column
        visible: body.main && !body.bake
        readonly property real edge: band.x - 60 * body.k
        anchors.fill: parent

        Text {
            id: time
            x: column.edge - width
            y: body.height * 0.255
            text: Qt.formatTime(clock.date, "hh:mm")
            font.family: Theme.numerals
            font.pixelSize: 156 * body.k
            font.features: { "lnum": 1, "tnum": 1 }
            font.variableAxes: body.dark ? ({}) : ({ "wght": 560, "opsz": 96 })
            color: body.dark ? "#f4ecdf" : "#211b33"
            renderType: Text.CurveRendering
            opacity: body.inn(1.3, 1.0)
            transform: Translate {
                y: (1 - time.opacity) * 14 * body.k
            }
        }
        Text {
            id: date
            x: column.edge - width
            y: time.y + time.baselineOffset + 26 * body.k
            text: Qt.locale("en_GB").toString(clock.date, "dddd  d  MMMM").toUpperCase()
            font.family: Theme.caps
            font.pixelSize: 15 * body.k
            font.letterSpacing: 5.5 * body.k
            color: body.dark ? "#e2b670" : "#b0105f"
            renderType: Text.CurveRendering
            opacity: body.inn(1.55, 1.0)
        }

        Text {
            id: hint
            x: column.edge - width
            y: date.y + date.height + 40 * body.k
            text: "PRESS ANY KEY"
            font.family: Theme.caps
            font.pixelSize: 12 * body.k
            font.letterSpacing: 6.5 * body.k
            color: body.dark ? "#c9c3d8" : "#3a2f58"
            renderType: Text.CurveRendering
            readonly property real breath: body.frozen || Slumber.deep || !body.main || field.up > 0.99 ? 0.75 : 0.62 + 0.26 * Math.sin(Slumber.life * 2 * Math.PI / 3.6)
            opacity: body.inn(2.4, 0.8) * breath * (1 - field.up)
        }

        Field {
            id: field
            k: body.k
            x: column.edge - width
            y: date.y + date.height + 26 * body.k
            width: implicitWidth
            height: implicitHeight
            light: Qt.point(body.lightAt.x - x, body.lightAt.y - y)
            readonly property point centre: Qt.point(x + width / 2, y + height / 2)
            onCentreChanged: if (body.main && !body.frozen)
                Slumber.fieldAt = centre
            Component.onCompleted: if (body.main && !body.frozen)
                Slumber.fieldAt = centre
        }

        Text {
            id: notice
            x: column.edge - width
            y: field.y + field.height + 16 * body.k
            visible: Slumber.notice !== ""
            text: Slumber.notice.toUpperCase()
            font.family: Theme.caps
            font.pixelSize: 11 * body.k
            font.letterSpacing: 4 * body.k
            color: Theme.alert
            renderType: Text.CurveRendering
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function rectOf(it: Item): var {
        return [Math.round(it.x), Math.round(it.y), Math.round(it.width), Math.round(it.height)];
    }
    Timer {
        running: Test.on && body.main && !body.frozen && !body.bake
        interval: 1000
        onTriggered: Slumber.layout = { output: [body.width, body.height], time: body.rectOf(time), timeBaseline: Math.round(time.y + time.baselineOffset), date: body.rectOf(date), hint: body.rectOf(hint), field: body.rectOf(field), band: body.rectOf(band) }
    }
}
