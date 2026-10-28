pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: s

    readonly property bool enabled: Quickshell.env("GLASSHOUSE_SOUND") !== "0" && !Settings.muted
    readonly property string target: Quickshell.env("GLASSHOUSE_SFX_TARGET") || ""
    readonly property string player: Quickshell.env("GLASSHOUSE_SFX_PLAYER") || Quickshell.env("HOME") + "/.cache/glasshouse/ghsfx"
    property int fails: 0
    property real attemptAt: 0
    property real startedAt: 0
    property real noteAt: 0

    function play(name: string, gain: real, delay: real): void {
        if (name === "focus" && Date.now() - s.noteAt < 300)
            return;
        s.send(World.name + "/" + name, Quickshell.shellPath("sounds/" + World.name + "/" + name + ".wav"), gain, delay);
    }

    function file(path: string, gain: real, delay: real): void {
        s.send(path, path, gain, delay);
    }

    function send(key: string, file: string, gain: real, delay: real): void {
        if (!s.enabled)
            return;
        const g = (gain === undefined || isNaN(gain) ? 1 : gain) * Settings.soundLevel;
        const d = delay === undefined || isNaN(delay) ? 0 : Math.max(0, delay);
        if (resident.running) {
            resident.write(key + " " + g.toFixed(3) + " " + d.toFixed(0) + "\n");
            return;
        }
        if (d > 0)
            return;
        Quickshell.execDetached(s.target ? ["pw-play", "--target", s.target, "-P", "{ node.dont-fallback = true }", "--latency", "256", "--volume", g.toFixed(3), file] : ["pw-play", "--latency", "256", "--volume", g.toFixed(3), file]);
    }

    function hush(): void {
        if (resident.running)
            resident.write("hush\n");
    }

    function note(index: int): void {
        s.noteAt = Date.now();
        s.play("ws-" + (Math.max(0, Math.min(4, index)) + 1), 1);
    }

    function hold(): void {
        if (resident.running)
            resident.write("hold " + (away.isIdle ? 0 : 1) + "\n");
    }

    function start(): void {
        s.attemptAt = Date.now();
        resident.running = true;
    }

    Process {
        id: resident
        stdinEnabled: true
        command: ["setpriv", "--pdeathsig", "TERM", "--", s.player, "--linger", "3000"].concat(s.target ? ["--target", s.target] : []).concat([Quickshell.shellPath("sounds")])
        onStarted: {
            s.startedAt = Date.now();
            s.hold();
        }
        onExited: {
            const ran = s.startedAt >= s.attemptAt ? Date.now() - s.startedAt : 0;
            s.fails = ran > 10000 ? 1 : s.fails + 1;
            if (s.fails < 3)
                revive.restart();
        }
    }
    IdleMonitor {
        id: away
        timeout: 60
        respectInhibitors: false
        onIsIdleChanged: s.hold()
    }
    Timer {
        id: revive
        interval: 2000
        onTriggered: s.start()
    }

    Component.onCompleted: s.start()
}
