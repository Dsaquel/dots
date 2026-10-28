import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core
import qs.parts.World

Scope {
    id: pane

    required property ShellScreen screen
    required property var turn
    readonly property string name: pane.screen.name
    readonly property string role: Screens.role(pane.name) || "main"
    readonly property bool main: pane.role === "main"
    readonly property real sw: pane.screen.width
    readonly property real sh: pane.screen.height
    readonly property real u: pane.sh / Screens.design.height
    // the scene's render targets and layers exist at full size only while it works (prep, run, the warm-up); at
    // rest they shrink (the compiled pipelines and the art stay resident). The view keeps 128 px: its six glow
    // levels halve it each time, and a level of 0 px is a 1D texture that crashes the process
    readonly property bool busy: turn.phase !== "rest" || turn.warming
    readonly property size full: Qt.size(pane.sw, pane.sh)
    readonly property size tex: pane.busy ? pane.full : Qt.size(8, 8)
    readonly property size view: pane.busy ? pane.full : Qt.size(128, 128)
    property int nudge: 0
    onBusyChanged: {
        if (pane.busy)
            return;
        Qt.callLater(() => pane.nudge = 1 - pane.nudge);
        shrink.restart();
    }
    Timer {
        id: shrink
        interval: 400
        onTriggered: {
            const w = scene.Window.window;
            if (w && !pane.busy)
                w.releaseResources();
        }
    }

    property rect frame: Qt.rect(-24, -14, 1968, 1107)
    property bool live: false
    property bool masked: false
    property var looks: ({})
    property bool looked: false
    property var blurSpec: ({ on: false, size: 7, passes: 2, noise: 0.012, contrast: 1, brightness: 1, vibrancy: 0, vibDark: 0 })
    readonly property var sink: vo.videoSink

    readonly property real clipPos: player.position / 1000
    readonly property bool clipPlaying: player.playbackState === MediaPlayer.PlayingState
    readonly property string clipName: pane.main ? "room-" + turn.dir + "-clap-v5" : "diner-" + turn.dir
    property string loaded: ""
    readonly property var trim: pane.main ? ({ at: turn.clipT, from: 0, until: turn.clipT + 5.96 }) : (turn.dawn ? { at: 4.85, from: 0, until: 9.93 } : { at: 4.47, from: 0, until: 9.93 })
    property bool clipStarted: false

    readonly property bool prepared: pane.looked && !!printHost.view && printHost.view.hasContent && deskHost.ready
    readonly property bool clipReady: pane.loaded === pane.clipName || Assets.clip(pane.clipName) === ""
    readonly property bool lean: Quickshell.env("GLASSHOUSE_TURN_LEAN") === "1"
    onClipNameChanged: if (turn.phase === "rest" && Assets.ready && !pane.lean) nextLoad.restart()
    Timer {
        id: nextLoad
        interval: 1500
        onTriggered: if (turn.phase === "rest") pane.loadClip()
    }
    readonly property bool shown: win.width >= pane.sw - 1 && win.height >= pane.sh - 1
    property bool reveal: false
    onShownChanged: {
        if (!pane.shown)
            pane.reveal = false;
        else
            Qt.callLater(() => pane.reveal = pane.shown);
    }

    function grabDesk(path: string): void {
        deskHost.grabToImage(r => r.saveToFile(path));
    }

    function status(): var {
        return { name: pane.name, role: pane.role, prepared: pane.prepared, shown: pane.shown && pane.reveal, clip: pane.loaded, media: player.mediaStatus, playing: pane.clipPlaying, pos: Math.round(player.position), print: !!printHost.view && printHost.view.hasContent, desk: deskHost.ready, looked: pane.looked, frame: [pane.frame.x, pane.frame.y, pane.frame.width, pane.frame.height] };
    }

    function prepare(): void {
        const o = Stage.of(pane.name);
        if (o)
            pane.frame = Qt.rect(o.farX / pane.u, o.fy / pane.u, o.fw / pane.u, o.fh / pane.u);
        pane.clipStarted = false;
        pane.masked = false;
        pane.looked = false;
        pane.live = true;
        pane.queryLooks();
    }

    function snapMask(): void {
        deskHost.solid = true;
        maskSrc.scheduleUpdate();
        deskSrc.scheduleUpdate();
        for (const b of [blur0, blur1, blur2, blur3, blur4])
            b.scheduleUpdate();
        pane.masked = true;
        Qt.callLater(() => deskHost.solid = false);
    }

    function release(): void {
        pane.live = false;
        pane.masked = false;
        shrink.restart();
        if (pane.lean) {
            pane.unloadClip();
            return;
        }
        if (pane.clipPlaying)
            player.pause();
        nextLoad.restart();
    }

    function unloadClip(): void {
        warmClip.stop();
        player.stop();
        player.source = "";
        pane.loaded = "";
    }

    function loadClip(): void {
        const url = Assets.clip(pane.clipName);
        if (!url)
            return;
        if (pane.loaded === pane.clipName && player.source.toString() === url) {
            if (player.position !== 0)
                player.position = 0;
            return;
        }
        pane.loaded = "";
        player.source = url;
    }

    function playClip(): void {
        if (pane.main) {
            player.play();
            pane.clipStarted = true;
        }
    }

    function guardClip(): void {
        if (!pane.main && !pane.clipStarted && turn.t >= pane.trim.at) {
            pane.clipStarted = true;
            player.play();
        }
        if (pane.clipPlaying && (turn.t >= pane.trim.until || (player.duration > 0 && player.position >= player.duration - 90)))
            player.pause();
    }

    function queryLooks(): void {
        const wins = Hypr.on(pane.name);
        const props = ["rounding", "rounding_power", "no_dim", "no_blur", "opacity", "opacity_inactive"];
        const opts = ["decoration:dim_inactive", "decoration:dim_strength", "decoration:blur:enabled", "decoration:active_opacity", "decoration:inactive_opacity", "decoration:blur:size", "decoration:blur:passes", "decoration:blur:noise", "decoration:blur:contrast", "decoration:blur:brightness", "decoration:blur:vibrancy", "decoration:blur:vibrancy_darkness"];
        const cmds = [];
        for (const w of wins)
            for (const p of props)
                cmds.push("getprop address:0x" + w.address + " " + p);
        for (const o of opts)
            cmds.push("getoption " + o);
        looker.wins = wins.map(w => w.address);
        looker.command = ["hyprctl", "-j", "--batch", cmds.join("; ")];
        looker.running = true;
    }
    Looker {
        id: looker
        host: pane
    }

    MediaPlayer {
        id: player
        videoOutput: vo
        property bool warming: false
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia && pane.loaded === "") {
                player.warming = true;
                player.play();
                warmClip.restart();
            }
        }
    }
    Timer {
        id: warmClip
        interval: 120
        onTriggered: {
            player.pause();
            player.position = 0;
            player.warming = false;
            pane.loaded = pane.clipName;
        }
    }

    Component.onCompleted: turn.register(pane, true)
    Timer {
        id: unloadLater
        interval: 2500
        onTriggered: if (turn.phase === "rest") pane.unloadClip()
    }
    Timer {
        running: Assets.ready
        interval: Math.max(0, 8000 - (Date.now() - Quickshell.launchTime.getTime()))
        onTriggered: {
            if (turn.phase === "rest")
                pane.loadClip();
            if (pane.lean)
                unloadLater.restart();
        }
    }
    Component.onDestruction: turn.register(pane, false)

    PanelWindow {
        id: win

        screen: pane.screen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "glasshouse-turn"
        WlrLayershell.keyboardFocus: turn.open && !Test.on ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors {
            top: true
            left: true
        }
        implicitWidth: turn.open ? pane.sw : 1
        implicitHeight: turn.open ? pane.sh : 1
        color: "transparent"
        mask: turn.open ? grabAll : grabNone

        readonly property Region grabNone: Region {}
        readonly property Region grabAll: Region {
            item: scene
        }

        Item {
            id: scene

            x: turn.open ? 0 : 1 + pane.nudge
            visible: turn.open ? pane.reveal : !pane.shown
            opacity: turn.shown
            width: pane.sw
            height: pane.sh

            Vault {
                id: v3d
                host: pane
                turn: pane.turn
                printSource: printHost
                maskSource: maskSrc
                deskSource: deskSrc
                darkSource: srcDark
                lightSource: srcLight
                videoSource: vo
                mesh: meshFile
                sparks: sparkFile
            }

            Impact {
                host: pane
                turn: pane.turn
                view: v3d
            }
        }

        Item {
            width: 0
            height: 0
            clip: true

            WorldBody {
                id: bodyDark
                width: pane.tex.width
                height: pane.tex.height
                output: pane.name
                world: "dark"
                life: pane.live && turn.target === "dark"
                fadeMs: 0
            }
            WorldBody {
                id: bodyLight
                width: pane.tex.width
                height: pane.tex.height
                output: pane.name
                world: "light"
                life: pane.live && turn.target === "light"
                fadeMs: 0
            }
            ShaderEffectSource {
                id: srcDark
                width: 0
                height: 0
                textureSize: pane.tex
                sourceItem: bodyDark
                hideSource: true
            }
            ShaderEffectSource {
                id: srcLight
                width: 0
                height: 0
                textureSize: pane.tex
                sourceItem: bodyLight
                hideSource: true
            }
            component BlurPass: ShaderEffect {
                required property var src
                required property real stage
                required property size from
                property real radius: pane.blurSpec.size
                property real passes: pane.blurSpec.passes
                property real vibrancy: pane.blurSpec.vibrancy
                property real vibDark: pane.blurSpec.vibDark
                property real contrast: pane.blurSpec.contrast
                property real noise: pane.blurSpec.noise
                property real brightness: pane.blurSpec.brightness
                property vector2d srcSize: Qt.vector2d(from.width, from.height)
                fragmentShader: Qt.resolvedUrl("shaders/blur.frag.qsb")
            }
            component BlurTex: ShaderEffectSource {
                width: 0
                height: 0
                hideSource: true
                live: turn.deskLive
            }
            readonly property size half: pane.busy ? Qt.size(Math.round(pane.sw / 2), Math.round(pane.sh / 2)) : Qt.size(8, 8)
            readonly property size quarter: pane.busy ? Qt.size(Math.round(pane.sw / 4), Math.round(pane.sh / 4)) : Qt.size(8, 8)
            BlurPass { id: blurE0; width: pane.tex.width; height: pane.tex.height; src: turn.target === "light" ? srcLight : srcDark; stage: 0; from: pane.tex }
            BlurTex { id: blur0; sourceItem: blurE0; textureSize: pane.tex }
            BlurPass { id: blurE1; width: parent.half.width; height: parent.half.height; src: blur0; stage: 1; from: pane.tex }
            BlurTex { id: blur1; sourceItem: blurE1; textureSize: parent.half }
            BlurPass { id: blurE2; width: parent.quarter.width; height: parent.quarter.height; src: blur1; stage: 1; from: parent.half }
            BlurTex { id: blur2; sourceItem: blurE2; textureSize: parent.quarter }
            BlurPass { id: blurE3; width: parent.half.width; height: parent.half.height; src: blur2; stage: 2; from: parent.quarter }
            BlurTex { id: blur3; sourceItem: blurE3; textureSize: parent.half }
            BlurPass { id: blurE4; width: pane.tex.width; height: pane.tex.height; src: blur3; stage: 3; from: parent.half }
            BlurTex { id: blur4; sourceItem: blurE4; textureSize: pane.tex }

            ShaderEffectSource {
                id: deskSrc
                width: 0
                height: 0
                textureSize: pane.tex
                sourceItem: deskHost
                hideSource: true
                live: turn.deskLive || turn.warming
            }
            ShaderEffectSource {
                id: maskSrc
                width: 0
                height: 0
                textureSize: pane.tex
                sourceItem: deskHost
                hideSource: true
                live: false
            }
            VideoOutput {
                id: vo
                width: 1280
                height: 720
                fillMode: VideoOutput.Stretch
            }
            Item {
                id: printHost
                width: pane.tex.width
                height: pane.tex.height
                readonly property var view: printLoader.item
                Loader {
                    id: printLoader
                    anchors.fill: parent
                    active: pane.live
                    sourceComponent: ScreencopyView {
                        captureSource: pane.screen
                        live: false
                        paintCursor: false
                    }
                }
            }
            Item {
                id: deskHost
                width: pane.tex.width
                height: pane.tex.height
                property bool solid: false
                readonly property bool ready: !!deskLoader.item && deskLoader.item.frames !== undefined
                Loader {
                    id: deskLoader
                    anchors.fill: parent
                    active: pane.live
                    sourceComponent: Desk {
                        output: pane.name
                        solid: deskHost.solid
                        looks: pane.looks
                        bg: pane.blurSpec.on ? blur4 : null
                    }
                }
            }
        }
    }

    FileView {
        id: meshFile
        path: Quickshell.shellPath("assets/turn/mesh-anime.json")
        blockLoading: true
    }
    FileView {
        id: sparkFile
        path: Quickshell.shellPath("assets/turn/sparks-anime.json")
        blockLoading: true
    }
}
