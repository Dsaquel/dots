import QtQuick
import Quickshell
import qs.core
import qs.kit

Item {
    id: sh

    required property var host
    required property string name
    required property real u
    readonly property alias ruby: ruby
    readonly property bool mine: sh.host.screenName === sh.name
    readonly property bool ready: still.status === Image.Ready && sh.host.phase !== "wait"
    readonly property var r: sh.mine && sh.host.rect ? sh.host.rect : null
    readonly property var live: sh.host.phase === "drag" && sh.mine ? sh.drag : sh.r

    property var drag: null
    property real ax: 0
    property real ay: 0
    property real mx: -1000
    property real my: -1000
    property bool pressed: false
    property real clock: 0
    property real spin: 0
    property var emits: []
    property real emitAt: 0
    property real grainAt: 0
    property real gx: 0
    property real gy: 0
    property real hoverTick: 0
    property string hoverKey: ""
    property real fly: 0

    function under(x: real, y: real): var {
        const ws = Hypr.on(sh.name).filter(w => x >= w.lx && y >= w.ly && x < w.lx + w.w && y < w.ly + w.h);
        ws.sort((a, b) => (b.floating - a.floating) || (a.history - b.history));
        return ws.length ? { x: ws[0].lx, y: ws[0].ly, w: ws[0].w, h: ws[0].h, key: ws[0].address } : null;
    }
    function inPane(x: real, y: real): bool {
        return !!sh.r && x >= sh.r.x && y >= sh.r.y && x < sh.r.x + sh.r.w && y < sh.r.y + sh.r.h;
    }
    function hoverOver(x: real, y: real): void {
        const w = (sh.host.phase === "freeze" || sh.host.phase === "cut") && !sh.inPane(x, y) ? sh.under(x, y) : null;
        const key = w ? w.key : "";
        if (key === sh.hoverKey)
            return;
        sh.hoverKey = key;
        sh.host.hover = w ? Object.assign({ screen: sh.name }, w) : (sh.host.hover && sh.host.hover.screen === sh.name ? null : sh.host.hover);
        if (w && sh.clock - sh.hoverTick > 0.06) {
            sh.hoverTick = sh.clock;
            Sfx.play("cutter-hover", 0.6);
        }
    }

    Image {
        id: still
        anchors.fill: parent
        source: sh.host.frame(sh.name) ? "file://" + sh.host.frame(sh.name) : ""
        cache: false
        asynchronous: true
        smooth: true
        visible: false
    }

    ShaderEffect {
        id: glass
        anchors.fill: parent
        visible: sh.ready
        property size size: Qt.size(sh.width, sh.height)
        property real frost: sh.host.frost
        property real melt: sh.host.melt
        property vector4d rect: sh.live ? Qt.vector4d(sh.live.x, sh.live.y, sh.live.w, sh.live.h) : Qt.vector4d(0, 0, 0, 0)
        property real cut: sh.mine && sh.host.phase !== "drag" ? sh.host.cut : 0
        property real lift: 3 * sh.u * sh.host.cut
        property real dim: sh.mine && sh.r && sh.host.phase !== "drag" ? sh.host.cut : (sh.host.rect && !sh.mine ? 1 : 0)
        property real taken: sh.host.taken
        property vector4d hover: sh.host.hover && sh.host.hover.screen === sh.name ? Qt.vector4d(sh.host.hover.x, sh.host.hover.y, sh.host.hover.w, sh.host.hover.h) : Qt.vector4d(0, 0, 0, 0)
        property real hoverA: sh.host.hover && sh.host.hover.screen === sh.name ? 1 : 0
        property real score: sh.host.phase === "drag" && sh.mine ? 1 : Math.max(0, 1 - sh.host.cut * 2) * (sh.mine ? 1 : 0)
        property real record: sh.host.filming ? 1 : 0
        property real gild: sh.host.gild
        property real time: sh.clock
        property real unit: sh.u
        property real dark: Theme.dark ? 1 : 0
        property color light: Theme.lamp
        property variant frame: still
        fragmentShader: Qt.resolvedUrl("../../shaders/cutter-sheet.frag.qsb")
    }

    ShaderEffect {
        id: sparks
        anchors.fill: parent
        visible: sh.ready && sh.mine && (sh.host.phase === "drag" || sh.emits.some(e => sh.clock - e.t < 0.6))
        property size size: Qt.size(sh.width, sh.height)
        property point wheel: Qt.point(sh.mx, sh.my)
        property real spin: sh.spin
        property real wheelA: sh.host.phase === "drag" ? 1 : 0
        property real unit: sh.u
        property color hot: Theme.lamp
        property vector4d e0: sh.emit(0)
        property vector4d e1: sh.emit(1)
        property vector4d e2: sh.emit(2)
        property vector4d e3: sh.emit(3)
        property vector4d e4: sh.emit(4)
        property vector4d e5: sh.emit(5)
        property vector4d e6: sh.emit(6)
        property vector4d e7: sh.emit(7)
        fragmentShader: Qt.resolvedUrl("../../shaders/cutter-sparks.frag.qsb")
    }
    function emit(i: int): vector4d {
        const e = sh.emits[i];
        return e ? Qt.vector4d(e.x, e.y, sh.clock - e.t, e.s) : Qt.vector4d(0, 0, -1, 0);
    }

    FrameAnimation {
        running: sh.ready
        onTriggered: {
            sh.clock += frameTime;
            if (sh.host.phase === "drag" && sh.mine)
                sh.spin += frameTime * 14;
        }
    }

    Rectangle {
        id: plaque
        readonly property real k: sh.host.scaleOf(sh.name)
        visible: sh.ready && !!sh.live && sh.mine && (sh.host.phase === "drag" || sh.host.phase === "cut" || sh.host.phase === "pick") && sh.live.w > 8
        x: sh.live ? Math.min(sh.width - width - 8 * sh.u, sh.live.x + sh.live.w - width) : 0
        y: sh.live ? (sh.live.y + sh.live.h + height + 14 * sh.u < sh.height ? sh.live.y + sh.live.h + 10 * sh.u : sh.live.y + sh.live.h - height - 10 * sh.u) : 0
        width: dims.implicitWidth + 20 * sh.u
        height: 24 * sh.u
        radius: height / 2
        color: Qt.alpha(Theme.ground, 0.88)
        border.width: Math.max(1, 1.4 * sh.u)
        border.color: Theme.dark ? Theme.rare : Theme.sun
        Text {
            id: dims
            anchors.centerIn: parent
            text: sh.live ? Math.round(sh.live.w * plaque.k) + " × " + Math.round(sh.live.h * plaque.k) : ""
            font.family: Theme.numerals
            font.pixelSize: 14 * sh.u
            color: Theme.dark ? Theme.rare : Theme.cream
        }
    }

    Item {
        id: column
        readonly property real d: 44 * sh.u
        readonly property real gap: 10 * sh.u
        readonly property bool leftward: !!sh.r && sh.r.x + sh.r.w + 3 * column.d > sh.width
        readonly property real full: sh.host.tools.length * (column.d + column.gap)
        visible: sh.ready && sh.mine && !!sh.r && sh.host.phase === "cut"
        x: !sh.r ? 0 : column.leftward ? Math.max(8 * sh.u, sh.r.x - column.d - 22 * sh.u) : sh.r.x + sh.r.w + 22 * sh.u
        y: !sh.r ? 0 : Math.max(10 * sh.u, Math.min(sh.height - column.full - 10 * sh.u, sh.r.y + Math.min(24 * sh.u, sh.r.h * 0.1)))
        width: column.d
        height: column.full
        Repeater {
            model: sh.host.tools
            Jewel {
                required property var modelData
                tool: modelData
                u: sh.u
                shown: sh.host.cut
                leftward: column.leftward
                x: (column.leftward ? -1 : 1) * Math.sin(index / Math.max(1, sh.host.tools.length - 1) * Math.PI) * 14 * sh.u
                y: index * (column.d + column.gap)
                onChosen: key => sh.host.act(key)
            }
        }
    }

    ShaderEffect {
        id: loupe
        readonly property real d: 150 * sh.u
        visible: sh.ready && sh.host.phase === "pick" && sh.mx > -100
        width: loupe.d
        height: loupe.d
        x: sh.mx - loupe.d / 2
        y: sh.my - loupe.d / 2
        property point at: Qt.point(sh.mx, sh.my)
        property size screen: Qt.size(sh.width, sh.height)
        property size pixels: Qt.size(still.implicitWidth || sh.width, still.implicitHeight || sh.height)
        property real zoom: 9
        property real dark: Theme.dark ? 1 : 0
        property variant frame: still
        fragmentShader: Qt.resolvedUrl("../../shaders/cutter-loupe.frag.qsb")
    }

    Image {
        id: flyer
        readonly property real k: sh.host.scaleOf(sh.name)
        visible: sh.mine && sh.host.phase === "fly" && !!sh.r
        source: flyer.visible ? still.source : ""
        sourceClipRect: sh.r ? Qt.rect(Math.round(sh.r.x * flyer.k), Math.round(sh.r.y * flyer.k), Math.round(sh.r.w * flyer.k), Math.round(sh.r.h * flyer.k)) : Qt.rect(0, 0, 1, 1)
        cache: false
        smooth: true
        readonly property real e: sh.fly * sh.fly
        width: sh.r ? sh.r.w : 0
        height: sh.r ? sh.r.h : 0
        x: sh.r ? sh.r.x + (sh.mx - sh.r.x - sh.r.w / 2) * flyer.e : 0
        y: sh.r ? sh.r.y + (sh.my - sh.r.y - sh.r.h / 2) * flyer.e : 0
        scale: 1 - 0.97 * flyer.e
        opacity: 1 - Math.max(0, (sh.fly - 0.75) / 0.25)
    }
    Glow {
        visible: flyer.visible && sh.fly > 0.5
        width: 120 * sh.u
        height: width
        x: sh.mx - width / 2
        y: sh.my - height / 2
        color: Theme.lamp
        intensity: Math.sin((sh.fly - 0.5) / 0.5 * Math.PI) * 1.6
    }
    NumberAnimation {
        id: flying
        target: sh
        property: "fly"
        from: 0
        to: 1
        duration: 380
        easing.type: Easing.InOutCubic
        onFinished: sh.host.finish(260)
    }
    Connections {
        target: sh.host
        function onPhaseChanged(): void {
            if (sh.host.phase === "fly" && sh.mine)
                flying.restart();
        }
    }

    Rectangle {
        id: toast
        visible: sh.mine && sh.host.toastTitle !== ""
        readonly property real cx: sh.r ? sh.r.x + sh.r.w / 2 : sh.width / 2
        readonly property real cy: sh.r ? sh.r.y + sh.r.h / 2 : sh.height / 2
        x: Math.max(10 * sh.u, Math.min(sh.width - width - 10 * sh.u, toast.cx - width / 2))
        y: Math.max(10 * sh.u, Math.min(sh.height - height - 10 * sh.u, toast.cy - height / 2))
        width: Math.min(sh.width * 0.6, Math.max(title.implicitWidth, body.implicitWidth) + 44 * sh.u + (sh.host.swatch ? 40 * sh.u : 0))
        height: 64 * sh.u
        radius: 8 * sh.u
        color: Qt.alpha(Theme.ground, 0.94)
        border.width: Math.max(1, 1.6 * sh.u)
        border.color: Theme.dark ? Theme.rare : Theme.sun
        opacity: sh.host.melt > 0 ? 1 - sh.host.melt : 1
        Rectangle {
            visible: sh.host.swatch !== ""
            x: 16 * sh.u
            anchors.verticalCenter: parent.verticalCenter
            width: 28 * sh.u
            height: width
            radius: width / 2
            color: sh.host.swatch || "transparent"
            border.width: Math.max(1, 1.5 * sh.u)
            border.color: Theme.dark ? Theme.rare : Theme.sun
        }
        Column {
            x: (sh.host.swatch ? 56 : 22) * sh.u
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4 * sh.u
            Text {
                id: title
                text: sh.host.toastTitle
                font.family: Theme.caps
                font.pixelSize: 12 * sh.u
                font.letterSpacing: Theme.capsTracking * sh.u
                color: Theme.dark ? Theme.rare : Theme.sun
            }
            Text {
                id: body
                width: Math.min(implicitWidth, sh.width * 0.6 - 60 * sh.u)
                text: sh.host.toastText
                elide: Text.ElideRight
                font.family: sh.host.swatch ? Theme.mono : Theme.ui
                font.pixelSize: 13 * sh.u
                color: Theme.ink
            }
        }
    }

    Item {
        id: ruby
        readonly property real d: 34 * sh.u
        visible: sh.mine && sh.host.phase === "record" && !!sh.r
        width: ruby.d + clockText.implicitWidth + 18 * sh.u
        height: ruby.d
        x: !sh.r ? 0 : sh.r.x + sh.r.w + 12 * sh.u + width < sh.width ? sh.r.x + sh.r.w + 12 * sh.u : Math.max(0, sh.r.x - width - 12 * sh.u)
        y: !sh.r ? 0 : Math.max(0, sh.r.y - ruby.d / 2)
        property real beat: 0
        SequentialAnimation on beat {
            running: ruby.visible
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: 1; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1; to: 0; duration: 600; easing.type: Easing.InOutSine }
        }
        Piece {
            width: ruby.d
            height: ruby.d
            name: "sanctum-medal"
            power: 0.6 + 0.4 * ruby.beat
            ambient: 0.7
            glow: 0.4 + 0.6 * ruby.beat
            tint: Qt.tint("white", Qt.alpha(Theme.dark ? "#b8233c" : "#e8457a", 0.85))
        }
        Gilt {
            width: ruby.d
            height: ruby.d
            src: Theme.a("sanctum-medal-gilt.png")
            lx: 0.25
            ly: -0.5
        }
        Rectangle {
            x: ruby.d / 2 - width / 2
            y: ruby.d / 2 - height / 2
            width: ruby.d * 0.26
            height: width
            radius: 2 * sh.u
            color: Theme.ivory
        }
        Text {
            id: clockText
            x: ruby.d + 10 * sh.u
            anchors.verticalCenter: parent.verticalCenter
            property real now: Date.now()
            Timer {
                running: ruby.visible
                interval: 250
                repeat: true
                onTriggered: clockText.now = Date.now()
            }
            readonly property int secs: Math.max(0, Math.floor((clockText.now - sh.host.recordAt) / 1000))
            text: Math.floor(clockText.secs / 60) + ":" + String(clockText.secs % 60).padStart(2, "0")
            font.family: Theme.numerals
            font.pixelSize: 17 * sh.u
            color: Theme.dark ? Theme.rare : Theme.cream
            style: Text.Outline
            styleColor: "#a0000000"
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: sh.host.stopRecord()
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: ["wait", "freeze", "drag", "cut", "pick"].indexOf(sh.host.phase) >= 0
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: sh.host.phase === "pick" ? Qt.BlankCursor : Qt.CrossCursor
        onPositionChanged: mouse => {
            sh.mx = mouse.x;
            sh.my = mouse.y;
            if (!sh.pressed) {
                sh.hoverOver(mouse.x, mouse.y);
                return;
            }
            const x = Math.min(sh.ax, mouse.x), y = Math.min(sh.ay, mouse.y);
            const w = Math.abs(mouse.x - sh.ax), h = Math.abs(mouse.y - sh.ay);
            if (sh.host.phase !== "drag" && (w > 4 * sh.u || h > 4 * sh.u)) {
                sh.host.hover = null;
                sh.hoverKey = "";
                sh.host.begin(sh.name);
            }
            if (sh.host.phase !== "drag")
                return;
            sh.drag = { x: x, y: y, w: w, h: h };
            const moved = Math.hypot(mouse.x - sh.gx, mouse.y - sh.gy);
            const dt = sh.clock - sh.grainAt;
            if (dt > 0.05 && moved > 2 * sh.u) {
                const speed = moved / Math.max(dt, 0.016) / sh.u;
                Sfx.play("cutter-score-" + Math.max(1, Math.min(6, 1 + Math.floor(speed / 260))), 0.7);
                sh.grainAt = sh.clock;
                sh.gx = mouse.x;
                sh.gy = mouse.y;
            }
            if (sh.clock - sh.emitAt > 0.045 && moved > 1) {
                sh.emitAt = sh.clock;
                sh.emits = [{ x: mouse.x, y: mouse.y, t: sh.clock, s: Math.min(1.5, moved / (20 * sh.u)) }].concat(sh.emits).slice(0, 8);
            }
        }
        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                sh.host.cancel();
                return;
            }
            if (sh.host.phase === "pick") {
                sh.host.pickAt(sh.name, mouse.x, mouse.y);
                return;
            }
            sh.pressed = true;
            sh.ax = mouse.x;
            sh.ay = mouse.y;
            sh.gx = mouse.x;
            sh.gy = mouse.y;
            sh.drag = null;
        }
        onReleased: mouse => {
            if (!sh.pressed)
                return;
            sh.pressed = false;
            if (sh.host.phase === "drag" && sh.drag && sh.drag.w > 4 * sh.u && sh.drag.h > 4 * sh.u) {
                sh.host.snap(sh.name, sh.drag);
            } else if (sh.host.phase === "drag" || !sh.inPane(mouse.x, mouse.y)) {
                const w = sh.under(mouse.x, mouse.y);
                w ? sh.host.snap(sh.name, w) : sh.host.whole(sh.name);
            }
            sh.drag = null;
        }
        onExited: if (!sh.pressed && sh.host.hover && sh.host.hover.screen === sh.name) {
            sh.host.hover = null;
            sh.hoverKey = "";
        }
    }

    Keys.onPressed: event => event.accepted = sh.host.key(event.key, !!(event.modifiers & Qt.ControlModifier))
}
