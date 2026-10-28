import Quickshell
import Quickshell.Io
import qs.core

Scope {
    id: remote

    required property var turn

    IpcHandler {
        target: "turn"
        function begin(): void {
            remote.turn.start();
        }
        function status(): string {
            return JSON.stringify({ phase: remote.turn.phase, running: remote.turn.running, t: Math.round(remote.turn.t * 1000) / 1000, dir: remote.turn.dir, switch: remote.turn.switchState, ok: remote.turn.ok, contactT: remote.turn.contactT, clipFrame: remote.turn.clipFrame, heldFirst: remote.turn.heldFirst, heldLast: remote.turn.heldLast, warming: remote.turn.warming, panes: remote.turn.panes.map(p => p.status()) });
        }
        function hold(which: string): void {
            if (!Test.on)
                return;
            remote.turn.holdFirst = which === "first" || which === "both";
            remote.turn.holdLast = which === "last" || which === "both";
        }
        function release(): void {
            if (!Test.on)
                return;
            if (remote.turn.heldLast) {
                remote.turn.holdLast = false;
                remote.turn.handOver();
            } else if (remote.turn.heldFirst) {
                remote.turn.holdFirst = false;
            }
        }
        function slowmo(k: real): void {
            if (Test.on)
                remote.turn.slow = Math.max(0.1, k);
        }
        function warm(): void {
            if (Test.on)
                remote.turn.warmUp();
        }
        function frames(): string {
            return JSON.stringify(remote.turn.slowFrames);
        }
        function grabDesk(dir: string): void {
            if (!Test.on)
                return;
            for (const p of remote.turn.panes)
                p.grabDesk(dir + "/desk-" + p.name + ".png");
        }
    }
}
