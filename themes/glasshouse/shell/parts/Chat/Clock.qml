import QtQuick

QtObject {
    id: c

    readonly property real epoch: Date.now()
    property real t: 0
    property real until: 0
    property real fastUntil: 0

    function now(): real {
        return (Date.now() - c.epoch) / 1000;
    }
    function kick(seconds: real, fast: bool): real {
        const n = c.now();
        c.t = n;
        c.until = Math.max(c.until, n + seconds + 0.02);
        if (fast)
            c.fastUntil = Math.max(c.fastUntil, n + seconds + 0.02);
        return n;
    }
    function clamp(x: real): real {
        return Math.max(0, Math.min(1, x));
    }
    function out(x: real): real {
        return 1 - Math.pow(1 - c.clamp(x), 3);
    }
    function inc(x: real): real {
        return Math.pow(c.clamp(x), 3);
    }
    function inout(x: real): real {
        const k = c.clamp(x);
        return k < 0.5 ? 4 * k * k * k : 1 - Math.pow(2 - 2 * k, 3) / 2;
    }
    function glide(from: real, to: real, at: real, d: real): real {
        return from + (to - from) * c.inout((c.t - at) / d);
    }

    property Timer ticker: Timer {
        interval: c.t < c.fastUntil ? 16 : 33
        repeat: true
        running: c.t < c.until
        onTriggered: c.t = c.now()
    }
}
