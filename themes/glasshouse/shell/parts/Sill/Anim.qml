import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: a

    property var leaves: ({})

    function leaf(name: string): var {
        return a.leaves[name] || { ms: 0, curve: [0.25, 0.1, 0.25, 1], slide: 0, vertical: false };
    }
    readonly property var wsIn: a.leaf("workspacesIn")
    readonly property var wsOut: a.leaf("workspacesOut")
    readonly property var specialIn: a.leaf("specialWorkspaceIn")
    readonly property var specialOut: a.leaf("specialWorkspaceOut")
    readonly property var windowsIn: a.leaf("windowsIn")

    function absorb(text: string): void {
        let data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            return;
        }
        const curves = {};
        for (const c of data[1] || [])
            curves[c.name] = [c.X0, c.Y0, c.X1, c.Y1];
        const out = {};
        for (const l of data[0] || []) {
            const m = (l.style || "").match(/(-?[0-9.]+)%/);
            out[l.name] = {
                ms: l.enabled ? Math.round(l.speed * 100) : 0,
                curve: curves[l.bezier] || curves["default"] || [0, 0.75, 0.15, 1],
                slide: m ? Number(m[1]) / 100 : 0,
                vertical: (l.style || "").indexOf("vert") >= 0
            };
        }
        a.leaves = out;
    }

    function ease(curve: var, x: real): real {
        const c = curve;
        const bx = s => 3 * (1 - s) * (1 - s) * s * c[0] + 3 * (1 - s) * s * s * c[2] + s * s * s;
        const by = s => 3 * (1 - s) * (1 - s) * s * c[1] + 3 * (1 - s) * s * s * c[3] + s * s * s;
        const t = Math.max(0, Math.min(1, x));
        let lo = 0;
        let hi = 1;
        let s = t;
        for (let i = 0; i < 18; i++) {
            const v = bx(s);
            if (Math.abs(v - t) < 1e-4)
                break;
            if (v < t)
                lo = s;
            else
                hi = s;
            s = (lo + hi) / 2;
        }
        return by(s);
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
