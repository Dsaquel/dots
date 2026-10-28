import QtQuick
import QtMultimedia
import Quickshell

Scope {
    id: reel

    property var her: null
    readonly property var meta: reel.her ? reel.her.meta : null
    readonly property real fps: reel.meta ? reel.meta.fps : 72
    readonly property var segs: reel.meta && reel.meta.segments ? reel.meta.segments : []
    property var seg: null
    property bool armed: false
    property bool stepping: false
    readonly property alias position: player.position
    readonly property bool rolling: player.playbackState === MediaPlayer.PlayingState
    readonly property bool want: !!reel.her && reel.her.looping && reel.her.mode === "seated"
    readonly property bool loaded: [MediaPlayer.LoadedMedia, MediaPlayer.BufferedMedia, MediaPlayer.BufferingMedia, MediaPlayer.EndOfMedia].indexOf(player.mediaStatus) >= 0

    function ms(frame: int): int {
        return Math.floor(frame * 1000 / reel.fps) + 1;
    }
    function go(name: string): void {
        const s = reel.segs.find(x => x.name === name);
        if (!s)
            return;
        reel.seg = s;
        reel.armed = false;
        reel.stepping = false;
        player.position = reel.ms(s.start);
        player.play();
    }
    function next(): void {
        if (reel.seg)
            return;
        if (reel.want && reel.loaded && !!player.videoOutput)
            reel.go("loop");
        else
            reel.freeze();
    }
    function ended(): void {
        reel.seg = null;
        reel.her.lapped();
        reel.freeze();
        pause.interval = 2000 + Math.round(Math.random() * 2000);
        pause.restart();
    }
    function freeze(): void {
        if (!reel.stepping && reel.rolling)
            player.pause();
    }
    function step(): void {
        if (!reel.loaded || reel.seg || !player.videoOutput)
            return;
        reel.stepping = true;
        player.position = reel.ms(0);
        player.play();
    }
    function rewind(): void {
        reel.seg = null;
        reel.step();
    }
    function wake(): void {
        if (reel.seg)
            return;
        reel.step();
        reel.next();
    }

    onWantChanged: reel.next()
    onLoadedChanged: if (reel.loaded)
        Qt.callLater(reel.wake)

    MediaPlayer {
        id: player
        source: reel.her ? reel.her.videoUrl : ""
        videoOutput: reel.her && reel.her.reelTarget ? reel.her.reelTarget.output : null
        onVideoOutputChanged: Qt.callLater(reel.wake)
        onPositionChanged: {
            const s = reel.seg;
            if (!s)
                return;
            const end = reel.ms(s.start + s.count - 1) - 1;
            if (!reel.armed)
                reel.armed = player.position >= reel.ms(s.start) - 1 && player.position < end;
            else if (player.position >= end && player.position < reel.ms(s.start + s.count + reel.meta.tail))
                reel.ended();
        }
        onErrorOccurred: (error, errorString) => console.log("sill: reel", player.source, errorString)
    }

    Timer {
        id: pause
        onTriggered: reel.next()
    }

    Connections {
        target: player.videoOutput ? player.videoOutput.videoSink : null
        function onVideoFrameChanged(): void {
            if (!reel.stepping)
                return;
            reel.stepping = false;
            if (!reel.seg)
                player.pause();
        }
    }

    Component.onDestruction: {
        player.stop();
        player.source = "";
    }
}
