import QtQuick

QtObject {
    id: clap

    required property var turn

    readonly property real contact: clap.turn.contactFrame / 24
    readonly property int holdN: 6
    property real lo: -1e15
    property real hi: 1e15
    property int arrivals: 0
    property int offset: 1000000
    readonly property int landed: offset < 100000 ? arrivals + offset : -1
    property var sink: clap.turn.mainPane ? clap.turn.mainPane.sink : null
    property int n: -1
    property int renders: 0
    property int perStep: 1
    property real ct: -10

    signal onset()

    function reset(): void { lo = -1e15; hi = 1e15; arrivals = 0; offset = 1000000; n = -1; renders = 0; ct = -10; }
    function start(): real { return lo < hi ? (lo + hi) / 2 : hi; }
    function cwin(a: real, b: real): real { return Math.max(0, Math.min(1, (ct - a) / (b - a))); }
    function sstep(a: real, b: real): real { const u = cwin(a, b); return u * u * (3 - 2 * u); }

    function tick(frame: real): void {
        if (n >= 0) {
            renders++;
            n = Math.floor(renders / perStep);
        }
        if (!clap.turn.clipPlaying || hi > 1e14) {
            if (n >= 0) ct = n / 60;
            return;
        }
        const clock = (Date.now() - start()) / 1000;
        if (n < 0) {
            const ready = sink ? landed >= clap.turn.contactFrame : clock >= contact + 0.004;
            if (ready && clock < contact + 0.4) {
                n = 0;
                renders = 0;
                perStep = Math.max(1, Math.round(1 / (60 * frame)));
                clap.turn.contactT = clap.turn.t;
                onset();
                clap.turn.contact(clap.turn.t);
            }
        }
        ct = n < 0 ? Math.min(clock - contact, -1 / 120) : Math.max(clock - contact, n / 60);
    }

    readonly property bool on: ct > -0.5 && ct < 1.4
    readonly property bool held: n >= 0 && n < holdN
    readonly property real rel: Math.max(0, ct - holdN / 60)
    readonly property bool released: n >= holdN
    readonly property real amp: n < 0 ? 0 : 44 * Math.exp(-ct / 0.3) * (1 - sstep(1.0, 1.35))
    readonly property real zoomV: n < 0 ? 1 + 0.01 * sstep(-0.45, 0) : (held ? 1.036 + 0.004 * n / holdN : 1 + 0.04 * (1 + rel / 0.09) * Math.exp(-rel / 0.09))
    readonly property real ringU: Math.max(0, ct - 0.06)
}
