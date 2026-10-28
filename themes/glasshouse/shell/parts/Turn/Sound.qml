import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Scope {
    id: sound

    property var turn: null
    readonly property var sheet: JSON.parse(cuesFile.text())
    readonly property real latency: sound.sheet.latency * 1000
    readonly property real frameMs: 1000 / sound.sheet.fps
    readonly property string wait: 'n=${EPOCHREALTIME/./}; w=$(($1 - n - 25000)); if ((w > 0)); then printf -v f %06d $((w % 1000000)); sleep $((w / 1000000)).$f; fi; while ((${EPOCHREALTIME/./} < $1)); do :; done; shift; exec "$@"'
    property string dir: "dawn"
    property bool active: false
    property bool clipOn: false
    property var launched: ({})
    property var landings: []
    property real tickAt: 0
    property real tickMs: 1000 / 60
    property real contactLag: -1
    property var log: []

    function from(stem: string): real {
        const s = sound.sheet.stems[stem];
        return s.from !== undefined ? s.from : Math.min(...sound.sheet.cues[sound.dir][stem].map(c => c[1]));
    }

    function note(kind: string, a: var, b: var): void {
        if (Test.on)
            sound.log.push([kind, Date.now(), a, b]);
    }

    function pwPlay(args: var): var {
        return ["pw-play"].concat(Sfx.target ? ["-P", "{ node.dont-fallback = true }", "--target", Sfx.target] : []).concat(["--latency", "256"]).concat(args);
    }

    function silence(frames: int): void {
        if (Sfx.enabled)
            Quickshell.execDetached(sound.pwPlay(["--raw", "--format", "s16", "--rate", "48000", "--channels", "1", "-n", String(frames), "/dev/zero"]));
    }

    function launch(stem: string, at: real): void {
        if (sound.launched[stem])
            return;
        sound.launched[stem] = true;
        sound.note("launch", stem, at);
        if (!Sfx.enabled)
            return;
        const file = Quickshell.shellPath("sounds/turn/" + sound.dir + "/" + stem + ".wav");
        Quickshell.execDetached(["bash", "-c", sound.wait, "bash", String(Math.round((at - sound.latency) * 1000))].concat(sound.pwPlay(["--volume", Settings.soundLevel.toFixed(3), file])));
    }

    function start(zero: real): void {
        sound.launch("stop", zero + sound.from("stop") * 1000);
        sound.launch("break", zero + sound.from("break") * 1000);
    }

    function due(stem: string, at: real): void {
        if (at - Date.now() < sound.latency + 15 + 1.5 * sound.frameMs)
            sound.launch(stem, at);
    }

    function origin(): real {
        return Math.min(...sound.landings.slice(-8));
    }

    function contactAt(): real {
        const landing = sound.origin() + sound.sheet.contactFrame[sound.dir] * sound.frameMs;
        const tick = sound.tickAt + Math.ceil((landing - sound.tickAt) / sound.tickMs) * sound.tickMs;
        return tick - landing < 4 ? tick + sound.tickMs / 2 : tick;
    }

    FrameAnimation {
        running: !!sound.turn && !sound.turn.warming && (sound.active || sound.turn.phase === "prep")
        onTriggered: {
            if (smoothFrameTime > 0)
                sound.tickMs = smoothFrameTime * 1000;
            sound.tickAt = Date.now();
        }
    }

    Connections {
        target: sound.turn

        function onPhaseChanged(): void {
            if (sound.turn.phase === "prep" && !sound.turn.warming)
                sound.silence(24000);
        }
        function onBegin(dir: string): void {
            sound.dir = dir;
            sound.launched = {};
            sound.landings = [];
            sound.active = true;
            sound.clipOn = false;
            sound.note("begin", dir, sound.turn.t);
            if (sound.turn.t >= 0)
                sound.launch("stop", Date.now());
            if (Date.now() - sound.tickAt < 1.2 * sound.tickMs)
                sound.start(sound.tickAt - sound.turn.t * 1000);
        }
        function onTChanged(): void {
            if (!sound.active)
                return;
            sound.note("tick", sound.turn.t, 0);
            sound.start(Date.now() - sound.turn.t * 1000);
        }
        function onClipStarted(): void {
            sound.clipOn = sound.active;
            sound.note("clip", sound.turn.t, 0);
        }
        function onClipFrameChanged(): void {
            const k = sound.turn.clipFrame;
            if (!sound.clipOn || k < 0)
                return;
            sound.landings = sound.landings.concat([Date.now() - k * sound.frameMs]);
            sound.note("frame", k, sound.origin());
            if (sound.landings.length < 3)
                return;
            sound.due("charge", sound.origin() + (sound.contactLag >= 0 ? sound.contactLag : 0.78 * sound.tickMs) + sound.from("charge") * 1000);
            sound.due("clap", sound.contactAt());
        }
        function onContact(at: real): void {
            if (!sound.active)
                return;
            const lag = Date.now() - sound.origin() - sound.sheet.contactFrame[sound.dir] * sound.frameMs;
            if (lag >= 0 && lag < 3 * sound.tickMs)
                sound.contactLag = sound.contactLag < 0 ? lag : (sound.contactLag + lag) / 2;
            sound.note("contact", at, sound.contactLag);
            sound.launched.charge = true;
            sound.launch("clap", Date.now());
        }
        function onRebuild(): void {
            if (!sound.active)
                return;
            sound.note("rebuild", sound.turn.t, 0);
            sound.launch("rebuild", Date.now() + (sound.from("rebuild") - sound.turn.t) * 1000);
        }
        function onEnded(ok: bool): void {
            sound.active = false;
            sound.clipOn = false;
            sound.note("ended", ok, sound.turn.t);
        }
    }

    FileView {
        id: cuesFile
        path: Quickshell.shellPath("parts/Turn/cues.json")
        blockLoading: true
    }

    IpcHandler {
        target: "sound"
        enabled: Test.on
        function log(): string {
            return JSON.stringify(sound.log);
        }
        function clear(): void {
            sound.log = [];
        }
        function play(stem: string, dir: string): void {
            sound.dir = dir;
            sound.launched = {};
            sound.launch(stem, Date.now() + 300);
        }
    }

    Component.onCompleted: sound.silence(1)
}
