import QtQuick
import Quickshell
import qs.core
import qs.kit

Item {
    id: r

    property real open: 1
    property real sweep: -1
    property real glint: -100000
    property bool live: false
    property string side: "left"
    property vector4d rect: Qt.vector4d(0, 0, 0, 0)

    readonly property bool clock: r.side === "right"
    readonly property string petals: Assets.url("wings/skin/" + Theme.world + "/" + r.side + "-rose.png")
    readonly property bool skinned: r.petals !== ""

    readonly property int total: Rite.catalog.apps.length
    readonly property int count: Rite.results.length
    property real shown: r.count === 0 ? 0 : r.total > 0 ? Math.max(1, Math.round(10 * Math.min(1, r.count / r.total))) : 10
    Behavior on shown { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    readonly property real hand: (time.date.getHours() % 12 + time.date.getMinutes() / 60) * 30
    readonly property int hour: Math.min(9, Math.floor(r.hand / 36))
    property real breath: 0

    property real rise: 0
    property real before: 0
    onOpenChanged: {
        if (r.open < r.before) {
            wake.stop();
            r.rise = Math.min(r.rise, r.open);
        } else if (r.open >= 0.35 && r.rise < 1 && !wake.running) {
            wake.duration = 950 * Theme.menuOpenMs / 700 * (1 - r.rise);
            wake.start();
        }
        r.before = r.open;
    }
    Component.onCompleted: r.openChanged()
    NumberAnimation {
        id: wake
        target: r
        property: "rise"
        to: 1
        easing.type: Easing.Linear
    }

    property var hits: [-1e9, -1e9, -1e9, -1e9, -1e9, -1e9, -1e9, -1e9, -1e9, -1e9]
    property real swept: -1e9
    property int sweepFrom: 0
    property int cursor: -1
    property real now: 0
    property real busy: 0
    property int typedLength: Rite.query.length
    property int lastLength: Rite.query.length
    property int picked: Rite.selected
    property int lastPicked: Rite.selected
    property real ring: 18
    Behavior on ring { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 2.6 } }
    property real tock: 0

    width: 152
    height: 152

    function skin(name: string): string {
        return Assets.url("wings/skin/" + Theme.world + "/" + r.side + "-rose" + name + ".png");
    }
    function decay(dt: real): real {
        if (dt < 0 || dt > 1100)
            return 0;
        return dt < 70 ? dt / 70 : Math.exp(-(dt - 70) / 230);
    }
    function bump(x: real): real {
        return x <= 0 || x >= 1 ? 0 : Math.pow(Math.sin(Math.PI * x), 2);
    }
    function order(k: int): real {
        return r.clock ? k / 9 : Math.abs(((k * 36 - 90) % 360 + 540) % 360 - 180) / 180;
    }
    function quad(v: var, i: int): vector4d {
        return Qt.vector4d(v[i], v[i + 1], i + 2 < v.length ? v[i + 2] : 0, i + 3 < v.length ? v[i + 3] : 0);
    }
    function stir(now: real): void {
        r.now = now;
        r.busy = now + 1200;
    }
    function strike(k: int, now: real): void {
        const h = r.hits.slice();
        h[k] = now;
        r.hits = h;
    }

    onTypedLengthChanged: {
        if (r.clock)
            return;
        const n = r.typedLength;
        const now = Date.now();
        if (n === 0) {
            r.sweepFrom = Math.max(0, r.cursor);
            r.swept = now;
            r.cursor = -1;
        } else if (n > r.lastLength) {
            r.cursor = (r.cursor + n - r.lastLength) % 10;
            r.strike(r.cursor, now);
        } else {
            r.strike(Math.max(0, r.cursor), now - 140);
            r.cursor = Math.max(-1, r.cursor - (r.lastLength - n));
        }
        r.lastLength = n;
        r.stir(now);
    }
    onPickedChanged: {
        const d = r.picked - r.lastPicked;
        r.lastPicked = r.picked;
        if (d === 0 || r.clock)
            return;
        r.ring += (d > 0 ? 1 : -1) * Math.min(3, Math.abs(d)) * 36;
        tick.restart();
    }

    readonly property var levels: {
        const out = [];
        for (let k = 0; k < 10; k++) {
            const ign = Math.max(0, Math.min(1, (r.rise - 0.55 * r.order(k)) / 0.22));
            const on = r.clock ? (k <= r.hour ? 1 : 0) : Math.max(0, Math.min(1, r.shown - k));
            out.push(ign * on);
        }
        return out;
    }
    readonly property var flares: {
        const out = [];
        for (let k = 0; k < 10; k++) {
            const ign = Math.max(0, Math.min(1, (r.rise - 0.55 * r.order(k)) / 0.22));
            const lit = r.clock ? (k <= r.hour ? 1 : 0) : 1;
            let f = 0.9 * lit * r.bump((r.rise - 0.55 * r.order(k)) / 0.45);
            if (r.clock)
                f += k === r.hour ? ign * (0.2 + 0.12 * r.breath) : 0;
            else
                f += r.decay(r.now - r.hits[k]) + 0.7 * r.decay(r.now - r.swept - ((r.sweepFrom - k + 10) % 10) * 34);
            out.push(f);
        }
        return out;
    }

    SystemClock {
        id: time
        precision: SystemClock.Minutes
    }
    FrameAnimation {
        running: r.now < r.busy
        onTriggered: r.now = Date.now()
    }
    NumberAnimation {
        id: tick
        target: r
        property: "tock"
        from: 1
        to: 0
        duration: 1100
        easing.type: Easing.InQuad
    }
    SequentialAnimation on breath {
        running: r.clock && r.live
        loops: Animation.Infinite
        NumberAnimation { to: 1; duration: 2600; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 2600; easing.type: Easing.InOutSine }
    }

    Lead {
        visible: !r.skinned
        anchors.fill: parent
        src: Theme.a("sanctum-rose-lead.png")
        lx: r.clock ? 0.18 : 0.82
        ly: -0.45
        depth: 3.6
        sweep: r.sweep
    }
    ShaderEffect {
        anchors.fill: parent
        property variant petalMap: Image { source: r.petals || Theme.a("sanctum-rose-" + r.side + ".png"); visible: false; smooth: true; mipmap: true }
        property variant glowMap: Image { source: r.skinned ? r.skin("-glow") : Theme.a("sanctum-rose-" + r.side + "-glow.png"); visible: false; smooth: true; mipmap: true }
        property variant goldMap: Image { source: r.skinned ? r.skin("-gold") : Theme.a("sanctum-rose-lead.png"); visible: false; smooth: true; mipmap: true }
        property real gain: r.skinned ? 1 : 0.94
        property real gloss: r.skinned ? 0 : 0.12
        property real dim: 0.68
        property real pale: 0.74
        property real bloom: 1.6 * r.bump(r.rise)
        property real spin: r.ring * Math.PI / 180
        property real tick: r.tock
        property real sweep: r.skinned ? r.sweep : -1
        property real glint: r.glint
        property real glintWidth: 70
        property point zone: r.skinned ? Qt.point(0.414, 0.783) : Qt.point(0, 1.1)
        property vector4d rect: r.rect
        property vector4d levelsA: r.quad(r.levels, 0)
        property vector4d levelsB: r.quad(r.levels, 4)
        property vector4d levelsC: r.quad(r.levels, 8)
        property vector4d flaresA: r.quad(r.flares, 0)
        property vector4d flaresB: r.quad(r.flares, 4)
        property vector4d flaresC: r.quad(r.flares, 8)
        property color cool: "#f5edff"
        property color hot: "#fff2c8"
        fragmentShader: Qt.resolvedUrl("../../shaders/sanctum-rose.frag.qsb")
    }
}
