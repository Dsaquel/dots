import QtQuick

QtObject {
    id: tw

    property var clock: null
    property real duration: 400
    property real rate: 60
    property real progress: 1
    property bool running: false
    property double startedAt: 0

    signal done()

    function start(): void {
        tw.startedAt = Date.now();
        tw.progress = 0;
        if (!tw.running) {
            tw.running = true;
            if (tw.clock)
                tw.clock.users++;
        }
    }
    function stop(): void {
        if (!tw.running)
            return;
        tw.running = false;
        if (tw.clock)
            tw.clock.users--;
    }
    function advance(now: double): void {
        if (!tw.running)
            return;
        const p = Math.min(1, (now - tw.startedAt) / Math.max(1, tw.duration));
        tw.progress = p;
        if (p >= 1) {
            tw.stop();
            tw.done();
        }
    }

    readonly property Connections link: Connections {
        target: tw.clock
        enabled: tw.running
        function onTick(now: double): void {
            tw.advance(now);
        }
    }
    readonly property Timer own: Timer {
        interval: Math.max(1, Math.floor(1000 / tw.rate * Math.ceil(tw.rate / 62)))
        repeat: true
        running: tw.running && !tw.clock
        onTriggered: tw.advance(Date.now())
    }

    Component.onDestruction: tw.stop()

    function outCubic(p: real): real {
        return 1 - Math.pow(1 - Math.max(0, Math.min(1, p)), 3);
    }
    function inOutCubic(p: real): real {
        const x = Math.max(0, Math.min(1, p));
        return x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2;
    }
    function inQuad(p: real): real {
        const x = Math.max(0, Math.min(1, p));
        return x * x;
    }
}
