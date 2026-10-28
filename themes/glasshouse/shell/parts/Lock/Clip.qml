import QtQuick
import QtMultimedia

Item {
    id: clip

    property string source: ""
    property real from: 0
    property real until: 5.7
    property bool go: false
    property bool first: false
    property bool done: false
    readonly property real position: player.position / 1000
    readonly property bool loaded: player.mediaStatus === MediaPlayer.LoadedMedia || player.mediaStatus === MediaPlayer.BufferedMedia || player.mediaStatus === MediaPlayer.EndOfMedia || player.mediaStatus === MediaPlayer.BufferingMedia

    signal shown()
    signal finished()

    function start(): void {
        if (clip.done || player.playbackState === MediaPlayer.PlayingState || !clip.loaded)
            return;
        prime.stop();
        clip.priming = false;
        if (clip.from > 0 && player.position < clip.from * 1000)
            player.position = Math.round(clip.from * 1000);
        player.play();
    }

    property bool priming: false
    function primeIt(): void {
        if (clip.go || clip.done || clip.priming || !clip.loaded)
            return;
        clip.priming = true;
        player.play();
        prime.restart();
    }
    Timer {
        id: prime
        interval: 140
        onTriggered: {
            player.pause();
            player.position = Math.round(clip.from * 1000);
            clip.priming = false;
            if (clip.go)
                clip.start();
        }
    }

    onGoChanged: if (clip.go)
        Qt.callLater(clip.start)
    onLoadedChanged: Qt.callLater(clip.go ? clip.start : clip.primeIt)

    MediaPlayer {
        id: player
        source: clip.source
        videoOutput: out
        onPositionChanged: {
            if (!clip.done && !clip.priming && player.playbackState === MediaPlayer.PlayingState && player.position >= clip.until * 1000) {
                player.pause();
                clip.done = true;
                clip.finished();
            }
        }
        onErrorOccurred: (error, errorString) => {
            console.log("lock: clip", clip.source, errorString);
            clip.done = true;
            clip.finished();
        }
    }

    VideoOutput {
        id: out
        anchors.fill: parent
        fillMode: VideoOutput.Stretch
        visible: clip.first
    }

    Connections {
        target: out.videoSink
        function onVideoFrameChanged(): void {
            if (!clip.first && !clip.priming && player.playbackState === MediaPlayer.PlayingState) {
                clip.first = true;
                clip.shown();
            }
        }
    }

    Component.onDestruction: {
        player.stop();
        player.source = "";
    }
}
