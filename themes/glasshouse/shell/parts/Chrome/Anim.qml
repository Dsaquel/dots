import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: a

    property var leaves: ({})

    function leaf(name: string): var {
        return a.leaves[name] || { ms: 0, curve: [0.25, 0.1, 0.25, 1, 1, 1], slide: 0, vertical: false };
    }
    readonly property var move: a.leaf("windowsMove")
    readonly property var wsIn: a.leaf("workspacesIn")
    readonly property var wsOut: a.leaf("workspacesOut")
    readonly property var specialIn: a.leaf("specialWorkspaceIn")
    readonly property var specialOut: a.leaf("specialWorkspaceOut")
    readonly property var fadeIn: a.leaf("fadeIn")
    readonly property var fadeOut: a.leaf("fadeOut")

    function absorb(text: string): void {
        let data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            return;
        }
        const curves = {};
        for (const c of data[1] || [])
            curves[c.name] = [c.X0, c.Y0, c.X1, c.Y1, 1, 1];
        const out = {};
        for (const l of data[0] || []) {
            const m = (l.style || "").match(/(-?[\d.]+)%/);
            out[l.name] = {
                ms: l.enabled ? Math.round(l.speed * 100) : 0,
                curve: curves[l.bezier] || curves["default"] || [0, 0.75, 0.15, 1, 1, 1],
                slide: m ? Number(m[1]) / 100 : 0,
                vertical: (l.style || "").indexOf("vert") >= 0
            };
        }
        a.leaves = out;
    }

    Process {
        id: query
        running: true
        command: ["hyprctl", "animations", "-j"]
        stdout: StdioCollector {
            onStreamFinished: a.absorb(text)
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded")
                query.running = true;
        }
    }
}
