import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.core
import qs.parts.World

PanelWindow {
    id: film

    required property var ledger
    required property bool capture
    readonly property string world: film.ledger.dark ? "dark" : "light"
    readonly property var out: Stage.of(film.ledger.main)
    readonly property rect fit: {
        const s = Math.min(film.width / 16, film.height / 9);
        return Qt.rect((film.width - 16 * s) / 2, (film.height - 9 * s) / 2, 16 * s, 9 * s);
    }
    readonly property rect far: film.out ? Qt.rect(film.out.farX, film.out.fy, film.out.fw, film.out.fh) : film.fit
    readonly property rect frame: Qt.rect(film.far.x + (film.fit.x - film.far.x) * film.k, film.far.y + (film.fit.y - film.far.y) * film.k, film.far.width + (film.fit.width - film.far.width) * film.k, film.far.height + (film.fit.height - film.far.height) * film.k)
    readonly property bool grab: ["check", "fade", "film", "hold"].indexOf(film.ledger.phase) >= 0
    readonly property bool drawn: [deep, plate].every(i => i.source.toString() === "" || i.status === Image.Ready || i.status === Image.Error)
    readonly property bool loaded: [MediaPlayer.LoadedMedia, MediaPlayer.BufferingMedia, MediaPlayer.BufferedMedia].indexOf(player.mediaStatus) >= 0
    readonly property bool clear: film.ledger.phase === "close" && !film.ledger.alive && !film.ledger.win
    readonly property bool home: film.clear && (!film.ledger.moved || Hypr.activeWs(film.ledger.main) === film.ledger.origin)
    readonly property point lamp: film.ledger.dark ? film.art(1328, 466) : film.art(820, 740)
    readonly property bool bare: lanthorn.back && lanthorn.t > 0.3
    readonly property bool armed: !film.ledger.dark || film.primed || film.broken !== "" || primeLate.done
    readonly property var device: Sfx.target ? devices.audioOutputs.find(d => String(d.id) === Sfx.target) || null : devices.defaultAudioOutput
    property bool started: false
    property bool voice: false
    property bool first: false
    property bool sent: false
    property bool going: false
    property bool priming: false
    property bool primed: false
    property bool handed: false
    property int swaps: 0
    property var list: []
    property string broken: ""
    property real shown: 0
    property real k: 0

    function fadeTo(v: real, ms: int): void {
        fade.stop();
        fade.to = v;
        fade.duration = ms;
        fade.start();
    }

    function art(x: real, y: real): point {
        return Qt.point(film.far.x + x / Stage.source.width * film.far.width, film.far.y + y / Stage.source.height * film.far.height);
    }

    function panes(): var {
        return Hypr.on(film.ledger.main).filter(w => w.cls !== film.ledger.cls).sort((a, b) => a.history - b.history).map(w => ({ x: w.lx, y: w.ly, w: w.w, h: w.h }));
    }

    function begin(): void {
        if (film.started || film.capture || film.ledger.phase !== "fade" || !(film.drawn && still.hasContent) && !late.done)
            return;
        film.started = true;
        if (!still.hasContent) {
            film.fadeTo(1, film.ledger.fadeMs);
            film.ledger.fading();
            return;
        }
        film.list = film.panes();
        film.shown = 1;
    }

    function cue(name: string): void {
        Sfx.file(Assets.root + "/ledger/sounds/lanthorn-" + name + "-" + film.world + ".wav", 1, 0);
    }

    function go(): void {
        if (film.going || film.swaps < 2 || !film.armed || film.ledger.phase !== "fade")
            return;
        film.going = true;
        film.ledger.mark("drain");
        film.ledger.cover();
        film.ledger.fading();
        film.cue("open");
        lanthorn.play(film.list);
    }

    function reveal(): void {
        if (film.ledger.phase !== "close" || lanthorn.back && lanthorn.running)
            return;
        film.shown = 1;
        film.ledger.mark("reveal");
        film.cue("close");
        lanthorn.play(film.panes());
    }

    function roll(): void {
        if (!film.loaded || player.playbackState === MediaPlayer.PlayingState)
            return;
        if (film.ledger.phase === "film") {
            film.handed = true;
            player.play();
            return;
        }
        if (film.priming || film.capture || ["check", "fade"].indexOf(film.ledger.phase) < 0)
            return;
        film.priming = true;
        // Qt 6.12's PipeWire audio backend ignores AudioOutput.device (and EasyEffects moves its streams): a target sink is only honoured through the PulseAudio backend
        film.voice = Sfx.enabled && (Sfx.target === "" || !!film.device && Quickshell.env("QT_AUDIO_BACKEND") === "pulseaudio");
        player.play();
    }

    screen: film.ledger.at
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "glasshouse-ledger"
    WlrLayershell.keyboardFocus: film.grab && !Test.on ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    mask: film.grab ? whole : none

    readonly property Region none: Region {}
    readonly property Region whole: Region {
        item: view
    }

    onDrawnChanged: film.begin()
    onLoadedChanged: Qt.callLater(film.roll)
    onArmedChanged: film.go()
    onClearChanged: if (film.clear)
        film.ledger.back()
    onHomeChanged: if (film.home)
        settle.restart()

    Timer {
        id: settle
        interval: 150
        onTriggered: film.drawn ? film.reveal() : film.fadeTo(0, film.ledger.closeMs)
    }
    Timer {
        interval: 900
        running: film.clear && !film.home
        onTriggered: film.reveal()
    }

    Connections {
        target: film.ledger
        function onPhaseChanged(): void {
            switch (film.ledger.phase) {
            case "fade":
                film.begin();
                film.roll();
                break;
            case "film":
                if (film.broken !== "")
                    film.ledger.fail("the film did not play: " + film.broken);
                film.roll();
                break;
            case "hold":
                if (!film.ledger.dark)
                    push.start();
                break;
            case "hand":
                film.fadeTo(0, film.ledger.handMs);
                break;
            case "close":
                if (player.playbackState === MediaPlayer.PlayingState)
                    player.pause();
                break;
            }
        }
    }

    Timer {
        id: primeLate
        property bool done: false
        interval: 1500
        running: film.started && !film.primed
        onTriggered: primeLate.done = true
    }
    Timer {
        id: late
        property bool done: false
        interval: 600
        running: film.ledger.phase === "fade" && !film.started
        onTriggered: {
            late.done = true;
            film.begin();
        }
    }

    NumberAnimation {
        id: fade
        target: film
        property: "shown"
        easing.type: Easing.InOutSine
        onFinished: {
            if (film.ledger.phase === "fade")
                film.ledger.faded();
            else if (film.ledger.phase === "hand")
                film.ledger.landed();
            else if (film.ledger.phase === "close" && film.shown <= 0)
                film.ledger.rest();
        }
    }
    NumberAnimation {
        id: drift
        target: film
        property: "k"
        from: 0
        to: 1
        duration: Math.max(1, player.duration)
        easing.type: Easing.InOutSine
    }
    NumberAnimation {
        id: push
        target: room
        property: "scale"
        to: 1.03
        duration: 2500
        easing.type: Easing.InOutSine
    }

    MediaDevices {
        id: devices
    }
    AudioOutput {
        id: sound
        volume: Settings.soundLevel
        muted: !Sfx.enabled || !film.handed
        device: film.device || devices.defaultAudioOutput
    }
    MediaPlayer {
        id: player
        source: film.ledger.dark && !film.capture ? "file://" + film.ledger.film : ""
        videoOutput: picture
        audioOutput: film.voice ? sound : null
        onMediaStatusChanged: if (player.mediaStatus === MediaPlayer.EndOfMedia)
            film.ledger.ended()
        onErrorOccurred: (error, errorString) => {
            film.broken = errorString;
            if (film.ledger.phase === "film")
                film.ledger.fail("the film did not play: " + errorString);
        }
    }
    Timer {
        interval: Math.max(0, player.duration) + 3000
        running: film.ledger.phase === "film"
        onTriggered: film.ledger.ended()
    }
    Connections {
        target: picture.videoSink
        function onVideoFrameChanged(): void {
            if (player.playbackState !== MediaPlayer.PlayingState)
                return;
            if (!film.handed) {
                if (!film.primed) {
                    player.pause();
                    film.primed = true;
                    film.ledger.mark("primed");
                }
                return;
            }
            if (film.first)
                return;
            film.first = true;
            film.ledger.mark("frame");
            drift.start();
            film.ledger.spawn();
        }
    }

    Item {
        id: view
        anchors.fill: parent
        opacity: film.shown
        layer.enabled: film.shown > 0 && film.shown < 1
        focus: true
        Keys.onEscapePressed: film.ledger.close()

        Rectangle {
            anchors.fill: parent
            visible: !film.capture && !film.bare
            color: "black"
        }
        VideoOutput {
            id: picture
            x: film.frame.x
            y: film.frame.y
            width: film.frame.width
            height: film.frame.height
            fillMode: VideoOutput.Stretch
            endOfStreamPolicy: VideoOutput.KeepLastFrame
            visible: (film.primed || film.first) && !film.bare
        }
        Item {
            id: room
            anchors.fill: parent
            visible: opacity > 0
            opacity: film.first && !lanthorn.back ? 0 : 1
            layer.enabled: opacity > 0 && opacity < 1
            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }
            Image {
                id: deep
                x: film.out ? film.out.deepX : film.far.x
                y: film.far.y
                width: film.far.width
                height: film.far.height
                source: Stage.deep("main", film.world)
                asynchronous: true
                smooth: true
                cache: false
            }
            Image {
                id: plate
                x: film.far.x
                y: film.far.y
                width: film.far.width
                height: film.far.height
                source: Stage.plate("main", film.world)
                asynchronous: true
                smooth: true
                cache: false
            }
            ShaderEffect {
                anchors.fill: parent
                visible: !film.ledger.dark && film.started && !lanthorn.back
                property size res: Qt.size(width, height)
                property point lamp: film.lamp
                property real bloom: 0.55
                property color warm: lanthorn.warm
                fragmentShader: Qt.resolvedUrl("../../shaders/lanthorn-glow.frag.qsb")
            }
        }
        ScreencopyView {
            id: still
            anchors.fill: parent
            visible: film.capture ? !film.bare : film.ledger.phase === "fade"
            captureSource: film.ledger.at
            live: false
            paintCursor: false
            onHasContentChanged: {
                if (!still.hasContent)
                    return;
                film.ledger.mark("captured");
                if (film.capture)
                    film.shown = 1;
                else
                    film.begin();
            }
        }
        ShaderEffectSource {
            id: stillSrc
            sourceItem: still
            hideSource: false
            visible: false
        }
        ShaderEffectSource {
            id: roomSrc
            sourceItem: room
            hideSource: lanthorn.back
            visible: false
        }
        Lanthorn {
            id: lanthorn
            anchors.fill: parent
            visible: film.started && !back && opacity > 0 && ["fade", "film", "hold"].indexOf(film.ledger.phase) >= 0 || back && (running || t > 0)
            still: stillSrc
            room: roomSrc
            lamp: film.lamp
            back: film.ledger.phase === "close"
            dark: film.ledger.dark
            onLanded: {
                film.ledger.mark("landed");
                film.cue("land");
                film.ledger.faded();
            }
            onDone: if (back) {
                film.shown = 0;
                film.ledger.rest();
            }
        }
        MouseArea {
            anchors.fill: parent
            enabled: film.grab
            hoverEnabled: true
            cursorShape: Qt.BlankCursor
        }
    }

    Connections {
        target: view.Window.window
        enabled: !film.capture && film.started && film.shown >= 1 && !film.going && film.ledger.phase === "fade"
        function onFrameSwapped(): void {
            film.swaps++;
            film.go();
            if (!film.going)
                view.Window.window.update();
        }
    }
    Connections {
        target: view.Window.window
        enabled: film.capture && film.shown >= 1 && !film.sent
        function onFrameSwapped(): void {
            film.sent = true;
            lift.start();
        }
    }
    Timer {
        id: lift
        interval: 34
        onTriggered: film.ledger.away()
    }

    Component.onCompleted: film.begin()
}
