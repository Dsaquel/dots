pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: a

    readonly property string dir: Quickshell.env("GLASSHOUSE_AGENTS") || Quickshell.env("HOME") + "/.cache/glasshouse/agents"
    property var sessions: []
    property var known: ({})
    property var pending: []
    property real now: Date.now()

    signal changed(var session, string previous)

    readonly property var live: a.sessions.filter(s => s.state !== "done" || a.now - s.updated < 600000)
    readonly property int needing: a.live.filter(s => s.state === "needs").length

    function absorb(text: string): void {
        const t = Date.now();
        const next = {};
        const list = [];
        for (const line of text.split("\n")) {
            if (!line.trim())
                continue;
            let s;
            try {
                s = JSON.parse(line);
            } catch (e) {
                continue;
            }
            if (!s.sid || t - s.updated > 86400000)
                continue;
            const old = a.known[s.sid];
            s.since = old && old.state === s.state ? old.since : s.updated;
            s.started = old ? old.started : s.updated;
            next[s.sid] = s;
            list.push(s);
            if (!old || old.state !== s.state || old.updated !== s.updated)
                a.changed(s, old ? old.state : "");
        }
        list.sort((x, y) => x.started - y.started || (x.sid < y.sid ? -1 : 1));
        a.known = next;
        a.sessions = list;
        a.now = t;
    }

    function load(): void {
        if (!reader.running)
            reader.running = true;
    }

    function set(sid: string, state: string, label: string, pid: string, detail: string): void {
        if (!/^[A-Za-z0-9_-]+$/.test(sid))
            return;
        a.pending = a.pending.concat([["sh", "-c", state === "end" ? 'rm -f "$1/$2.json"; date +%s%N > "$1/.stamp"' : 'mkdir -p "$1" && printf "%s\\n" "$3" > "$1/.$2.tmp" && mv "$1/.$2.tmp" "$1/$2.json" && date +%s%N > "$1/.stamp"', "sh", a.dir, sid, JSON.stringify({
                sid: sid,
                state: state,
                label: label || "claude",
                pid: Number(pid) || 0,
                detail: detail || "",
                updated: Date.now()
            })]]);
        a.drain();
    }

    function drain(): void {
        if (writer.running || !a.pending.length)
            return;
        writer.command = a.pending[0];
        a.pending = a.pending.slice(1);
        writer.running = true;
    }

    Process {
        id: reader
        command: ["sh", "-c", 'mkdir -p "$1"; find "$1" -maxdepth 1 -name "*.json" -mmin +1440 -delete; cat "$1"/*.json 2>/dev/null; true', "sh", a.dir]
        stdout: StdioCollector {
            onStreamFinished: a.absorb(text)
        }
    }

    Process {
        id: writer
        onExited: a.pending.length ? Qt.callLater(a.drain) : a.load()
    }

    FileView {
        path: a.dir + "/.stamp"
        watchChanges: true
        printErrors: false
        onFileChanged: a.load()
    }

    Timer {
        interval: 30000
        repeat: true
        running: a.sessions.length > 0
        onTriggered: a.now = Date.now()
    }

    IpcHandler {
        target: "agents"
        function set(sid: string, state: string, label: string, pid: string, detail: string): void {
            a.set(sid, state, label, pid, detail);
        }
        function dump(): string {
            return JSON.stringify(a.sessions);
        }
    }

    Component.onCompleted: a.load()
}
