import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.core

Scope {
    id: part

    readonly property bool on: Settings.pointerDust
    readonly property real calm: 520
    readonly property real full: 2600
    readonly property real spacing: 4.5
    property real lx: 0
    property real ly: 0
    property real lt: 0
    property string lout: ""
    property real carry: 0
    property real speed: 0
    property bool armed: false
    property int heard: 0

    function arm(): void {
        part.armed = part.on;
        if (Test.on)
            console.log("pointer: would eval glasshouse_pointer(" + part.on + ")");
        else
            Quickshell.execDetached(["hyprctl", "eval", "glasshouse_pointer(" + part.on + ")"]);
    }
    function ruleOut(): void {
        Quickshell.execDetached(["hyprctl", "eval", 'hl.layer_rule({ name = "glasshouse-pointer", match = { namespace = "^(glasshouse-pointer)$" }, no_anim = true })']);
    }
    function under(x: real, y: real): var {
        return outputs.instances.find(o => x >= o.modelData.x && x < o.modelData.x + o.modelData.width && y >= o.modelData.y && y < o.modelData.y + o.modelData.height) || null;
    }
    function moved(x: real, y: real): void {
        part.heard++;
        const now = Date.now();
        const o = part.under(x, y);
        const name = o ? o.modelData.name : "";
        const dt = now - part.lt;
        if (o && name === part.lout && dt > 0 && dt < 120 && !o.fullscreen) {
            const dx = x - part.lx, dy = y - part.ly;
            const d = Math.hypot(dx, dy);
            part.speed = part.speed * 0.5 + d / Math.max(dt, 8) * 500;
            const k = Math.max(0, Math.min(1, (part.speed - part.calm) / (part.full - part.calm)));
            if (k > 0) {
                part.carry += d;
                while (part.carry >= part.spacing) {
                    part.carry -= part.spacing;
                    const f = 1 - part.carry / Math.max(d, 0.001);
                    o.shed(part.lx + dx * f - o.modelData.x, part.ly + dy * f - o.modelData.y, now, k);
                }
                tick.start();
            } else {
                part.carry = 0;
            }
        } else {
            part.carry = 0;
            part.speed = 0;
        }
        part.lx = x;
        part.ly = y;
        part.lt = now;
        part.lout = name;
    }

    onOnChanged: part.arm()

    Variants {
        id: outputs
        model: Screens.list
        Dust {}
    }

    Timer {
        id: tick
        interval: 33
        repeat: true
        onTriggered: {
            const now = Date.now();
            let live = false;
            for (const o of outputs.instances)
                live = o.step(now) || live;
            if (!live)
                tick.stop();
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "custom" && part.on && event.data.startsWith("ghpointer>>")) {
                const xy = event.data.slice(11).split(",");
                part.moved(Number(xy[0]), Number(xy[1]));
            } else if (event.name === "configreloaded") {
                part.ruleOut();
                if (part.on)
                    part.arm();
            }
        }
    }

    IpcHandler {
        target: "pointer"
        function toggle(): void {
            Settings.pointerDust = !Settings.pointerDust;
        }
        function on(): void {
            Settings.pointerDust = true;
        }
        function off(): void {
            Settings.pointerDust = false;
        }
        function status(): string {
            return JSON.stringify({ on: part.on, armed: part.armed, heard: part.heard, ticking: tick.running, awake: outputs.instances.filter(o => o.awake).map(o => o.modelData.name), motes: outputs.instances.reduce((n, o) => n + o.live.length, 0) });
        }
    }

    Component.onCompleted: {
        part.ruleOut();
        part.arm();
    }
}
