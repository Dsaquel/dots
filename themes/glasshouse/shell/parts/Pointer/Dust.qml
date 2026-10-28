import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

Scope {
    id: dust

    required property ShellScreen modelData
    readonly property bool fullscreen: Hypr.on(dust.modelData.name).some(w => w.fullscreen)
    readonly property int pool: 110
    property bool awake: false
    property int head: 0
    property var live: []
    property var pending: []
    property real lastLive: 0

    function shed(x: real, y: real, now: real, k: real): void {
        dust.pending.push([x, y, now, k]);
        dust.awake = true;
    }
    function step(now: real): bool {
        if (!dust.awake || !ld.item)
            return false;
        for (const [x, y, t, k] of dust.pending) {
            const i = dust.head;
            dust.head = (dust.head + 1) % dust.pool;
            const m = ld.item.motes.itemAt(i);
            m.bx = x + (Math.random() - 0.5) * 6;
            m.by = y + (Math.random() - 0.5) * 6;
            m.size = 0.5 + 0.5 * Math.random() * Math.random() + (Math.random() < 0.08 ? 0.35 : 0);
            m.t = t;
            m.life = 300 + Math.random() * 240;
            m.k = k * (0.55 + 0.45 * Math.random());
            m.drift = (Theme.dark ? 1 : -1) * (5 + Math.random() * 7);
            if (dust.live.indexOf(i) < 0)
                dust.live.push(i);
        }
        dust.pending = [];
        const keep = [];
        for (const i of dust.live) {
            const m = ld.item.motes.itemAt(i);
            m.age = now;
            if (now < m.t + m.life)
                keep.push(i);
        }
        dust.live = keep;
        if (keep.length > 0)
            dust.lastLive = now;
        else if (now - dust.lastLive > 2500)
            dust.awake = false;
        return dust.awake;
    }

    LazyLoader {
        id: ld
        active: dust.awake
        PanelWindow {
            property alias motes: rep
            screen: dust.modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "glasshouse-pointer"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            mask: Region {}

            Repeater {
                id: rep
                model: dust.pool
                Image {
                    required property int index
                    property real bx: 0
                    property real by: 0
                    property real t: -1e9
                    property real life: 1
                    property real k: 0
                    property real drift: 0
                    property real size: 1
                    property real age: 0
                    readonly property real u: Math.min(1, Math.max(0, (age - t) / life))
                    source: Theme.a(index % 5 === 0 ? "pointer-mote-b.png" : "pointer-mote.png")
                    width: Theme.dark ? 12 : 16
                    height: width
                    smooth: true
                    mipmap: true
                    visible: u < 1
                    opacity: k * Math.pow(1 - u, 1.6)
                    scale: size * (1 - 0.5 * u)
                    x: bx - width / 2
                    y: by - height / 2 + drift * u
                }
            }
        }
    }
}
