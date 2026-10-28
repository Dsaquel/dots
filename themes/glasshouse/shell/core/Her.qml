pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: h

    readonly property var faces: ({
            dark: { rest: "calm", done: "happy", needs: "surprised", error: "worried", message: "calm", sleepy: "sleepy", thinking: "thinking", greet: "happy" },
            light: { rest: "confident", done: "proud", needs: "surprised", error: "pout", message: "wink", sleepy: "sleepy", thinking: "confident", greet: "laugh" }
        })
    property string reaction: ""
    property int unread: 0
    property bool idle: false
    readonly property string resting: Settings.dnd || h.idle ? "sleepy" : (Agents.needing > 0 ? "needs" : (Agents.live.some(s => s.state === "working") ? "thinking" : "rest"))
    readonly property string mood: h.reaction || h.resting
    readonly property string faceName: (h.faces[World.name] || h.faces.dark)[h.mood] || "calm"
    readonly property string face: Assets.face(World.name, h.faceName)
    readonly property bool asleep: h.mood === "sleepy"

    function react(kind: string, ms: int): void {
        if (Settings.dnd)
            return;
        h.reaction = kind;
        settle.interval = ms > 0 ? ms : 6000;
        settle.restart();
    }

    Timer {
        id: settle
        onTriggered: h.reaction = ""
    }

    Connections {
        target: Settings
        function onDndChanged(): void {
            if (Settings.dnd) {
                settle.stop();
                h.reaction = "";
            }
        }
    }

    Connections {
        target: Agents
        function onChanged(session: var, previous: string): void {
            if (session.state === "done" && previous && previous !== "done")
                h.react("done", 8000);
            else if (session.state === "needs" && previous !== "needs")
                h.react("needs", 10000);
        }
    }
}
