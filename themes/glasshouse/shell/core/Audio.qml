pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: a

    readonly property var sink: Test.on ? a.node(Test.sink) : Pipewire.defaultAudioSink
    readonly property var source: Test.on ? a.node(Test.source) : Pipewire.defaultAudioSource
    readonly property bool sinkReady: !!a.sink && !!a.sink.audio && a.sink.ready
    readonly property bool sourceReady: !!a.source && a.source.ready && (!!a.source.audio || a.virtualSource.known)
    // Quickshell 0.3.1 leaves Audio/Source/Virtual nodes untracked (no audio object): such a source
    // (EasyEffects', the test mic) is read and set through pactl instead, re-read on its events
    readonly property bool sourceVirtual: !!a.source && a.source.ready && !a.source.audio
    property QtObject virtualSource: QtObject {
        property real volume: 0
        property bool muted: false
        property bool known: false
    }
    readonly property real volume: a.sinkReady ? a.sink.audio.volume : 0
    readonly property bool muted: a.sinkReady && a.sink.audio.muted
    readonly property real micVolume: !a.sourceReady ? 0 : a.sourceVirtual ? a.virtualSource.volume : a.source.audio.volume
    readonly property bool micMuted: a.sourceReady && (a.sourceVirtual ? a.virtualSource.muted : a.source.audio.muted)
    readonly property string sinkLabel: a.label(a.sink)
    readonly property string sourceLabel: a.label(a.source)
    property bool sinkPrimed: false
    property bool sourcePrimed: false
    property var primedSink: null
    property var primedSource: null
    property bool phial: false

    signal volumeTouched()
    signal micTouched()

    function label(n: var): string {
        if (!n)
            return "";
        const d = (n.description || "").split(",").filter(p => p.indexOf("=") < 0).join(",").trim();
        return d || n.nickname || n.name;
    }
    function node(name: string): var {
        if (!name)
            return null;
        return Pipewire.nodes.values.find(n => n.name === name && !n.isStream) || null;
    }
    function setVolume(v: real): void {
        if (a.sinkReady)
            a.sink.audio.volume = Math.max(0, Math.min(1.5, v));
    }
    function toggleMute(): void {
        if (a.sinkReady)
            a.sink.audio.muted = !a.sink.audio.muted;
    }
    function setMic(v: real): void {
        if (!a.sourceReady)
            return;
        const c = Math.max(0, Math.min(1, v));
        if (a.sourceVirtual)
            Quickshell.execDetached(["pactl", "set-source-volume", a.source.name, Math.round(c * 100) + "%"]);
        else
            a.source.audio.volume = c;
    }
    function toggleMic(): void {
        if (!a.sourceReady)
            return;
        if (a.sourceVirtual)
            Quickshell.execDetached(["pactl", "set-source-mute", a.source.name, "toggle"]);
        else
            a.source.audio.muted = !a.source.audio.muted;
    }
    function readVirtual(text: string): void {
        const v = text.match(/(\d+)%/);
        const m = text.match(/Mute:\s*(yes|no)/);
        if (v)
            a.virtualSource.volume = Number(v[1]) / 100;
        if (m)
            a.virtualSource.muted = m[1] === "yes";
        a.virtualSource.known = !!v;
    }

    onSinkChanged: {
        if (a.sink === a.primedSink)
            return;
        a.primedSink = a.sink;
        a.sinkPrimed = false;
        primeSink.restart();
    }
    onSourceChanged: {
        if (a.source === a.primedSource)
            return;
        a.primedSource = a.source;
        a.sourcePrimed = false;
        primeSource.restart();
    }
    onVolumeChanged: if (a.sinkPrimed) a.volumeTouched()
    onMutedChanged: if (a.sinkPrimed) a.volumeTouched()
    onMicVolumeChanged: if (a.sourcePrimed) a.micTouched()
    onMicMutedChanged: if (a.sourcePrimed) a.micTouched()

    Timer {
        id: primeSink
        interval: 800
        onTriggered: a.sinkPrimed = a.sinkReady
    }
    Timer {
        id: primeSource
        interval: 800
        onTriggered: a.sourcePrimed = a.sourceReady
    }
    PwObjectTracker {
        objects: [a.sink, a.source].filter(n => !!n)
    }
    onSourceVirtualChanged: if (a.sourceVirtual) virtualRead.restart()
    Process {
        running: a.sourceVirtual
        command: ["setpriv", "--pdeathsig", "TERM", "--", "pactl", "subscribe"]
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("on source #") >= 0)
                    virtualRead.restart();
            }
        }
    }
    Timer {
        id: virtualRead
        interval: 25
        onTriggered: virtualGet.running = true
    }
    Process {
        id: virtualGet
        command: ["sh", "-c", 'pactl get-source-volume "$1" | head -n 1; pactl get-source-mute "$1"', "sh", a.source ? a.source.name : ""]
        stdout: StdioCollector {
            onStreamFinished: a.readVirtual(text)
        }
    }
}
