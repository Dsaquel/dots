import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Scope {
    id: remote

    required property var her
    required property var reel

    IpcHandler {
        target: "sill"
        function status(): string {
            return JSON.stringify({
                on: remote.her.on,
                mode: remote.her.mode,
                window: remote.her.rec ? [remote.her.rec.address, remote.her.rec.cls, remote.her.rec.monitor] : null,
                seat: [remote.her.seatX, remote.her.seatY],
                at: [Math.round(remote.her.ax), Math.round(remote.her.ay)],
                flip: remote.her.flip,
                frame: remote.her.frame,
                frames: remote.her.frames,
                video: remote.her.video,
                segment: remote.reel && remote.reel.seg ? remote.reel.seg.name : "",
                position: remote.reel ? remote.reel.position : -1,
                rolling: remote.reel ? remote.reel.rolling : false,
                looping: remote.her.looping,
                playing: remote.her.playing,
                perch: remote.her.perchOn ? remote.her.perchBox : null,
                flight: remote.her.flightOn ? remote.her.flightScreens : [],
                ticking: remote.her.ticking,
                occ: remote.her.occ.length,
                reach: remote.her.reach
            });
        }
        function on(): void {
            remote.her.on = true;
        }
        function off(): void {
            remote.her.on = false;
        }
        function toggle(): void {
            remote.her.on = !remote.her.on;
        }
        function trick(): void {
            if (remote.her.mode === "seated" && remote.her.frames > 1) {
                remote.her.frame = 0;
                remote.her.looping = true;
            }
        }
        function size(px: int): void {
            remote.her.size = px;
            remote.her.away();
            Qt.callLater(remote.her.think);
        }
        function grab(x: int, y: int): void {
            if (Test.on)
                remote.her.grab(x, y);
        }
        function drag(x: int, y: int): void {
            if (Test.on)
                remote.her.drag(x, y);
        }
        function drop(): void {
            if (Test.on)
                remote.her.drop();
        }
        function scratch(address: string): void {
            if (!Test.on)
                return;
            const a = address.replace(/^0x/, "");
            const w = Hypr.find(a !== "" ? a : Object.keys(remote.her.testScratch)[0] || "");
            if (a !== "") {
                const s = {};
                s[a] = true;
                remote.her.testScratch = s;
                remote.her.testHidden = ({});
                if (w)
                    remote.her.events[w.monitor] = { kind: "special-in", at: Date.now() };
            } else {
                const h = {};
                for (const k in remote.her.testScratch)
                    h[k] = true;
                remote.her.testHidden = h;
                if (w)
                    remote.her.events[w.monitor] = { kind: "special-out", at: Date.now() };
            }
            remote.her.think();
        }
    }
}
