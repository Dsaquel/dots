import QtQuick
import Quickshell
import qs.core
import qs.kit

Item {
    id: v

    required property var host
    property bool interactive: true
    readonly property string sprite: Theme.dark ? "night-star-vial" : "day-gold-ampoule"
    readonly property var meta: Anchor.bottle(v.sprite)
    readonly property real aspect: v.meta ? v.meta.w / v.meta.h : 0.36
    readonly property color tint: Theme.dark ? "#8d95ff" : "#ffe08a"
    readonly property color gold: "#ffc04a"
    readonly property color bright: Theme.dark ? "#e4ecff" : "#fff4d8"
    readonly property color needsWash: Theme.dark ? "#ffb84a" : "#ff9a1e"
    readonly property color doneWash: Theme.dark ? "#dfe8ff" : "#fffaf0"
    readonly property color brewColor: Theme.dark ? "#8d95ff" : "#5fd3e6"
    readonly property real brewWash: Theme.dark ? 0 : 0.55
    property var shown: []
    property var bySid: ({})
    readonly property var order: v.shown.filter(e => !e.leaving).map(e => e.sid)
    readonly property int count: v.order.length
    readonly property int extra: Math.max(0, Agents.live.length - 4)
    readonly property bool busy: v.shown.some(e => !e.leaving && (e.s.state === "working" || e.s.state === "needs"))

    function sync(): void {
        const live = Agents.live.slice(0, 4);
        const t = Date.now();
        const next = [];
        for (const e of v.shown) {
            const s = live.find(x => x.sid === e.sid);
            if (s)
                next.push({ sid: e.sid, s: s, leaving: false, gone: 0 });
            else if (!e.leaving)
                next.push({ sid: e.sid, s: e.s, leaving: true, gone: t });
            else if (t - e.gone < 600)
                next.push(e);
        }
        for (const s of live)
            if (!next.some(e => e.sid === s.sid))
                next.push({ sid: s.sid, s: s, leaving: false, gone: 0 });
        const map = {};
        for (const e of next)
            map[e.sid] = e;
        v.bySid = map;
        v.shown = next;
        if (next.some(e => e.leaving))
            reap.restart();
    }
    function slot(i: int, n: int): var {
        const h = n <= 1 ? 88 : n === 2 ? 84 : n === 3 ? 66 : 50;
        const w = Math.round(h * v.aspect);
        const bottom = v.height - 3;
        if (n === 4) {
            const row = i < 2 ? 0 : 1;
            const col = i % 2;
            const gap = 8;
            const x0 = Math.round((v.width - (2 * w + gap)) / 2);
            return { x: x0 + col * (w + gap), y: bottom - h - (1 - row) * (h + 7), w: w, h: h };
        }
        const gap = n === 3 ? Math.round(Math.min(2, (v.width - 3 * w) / 2)) : 8;
        const total = n * w + (n - 1) * gap;
        const x0 = Math.round((v.width - total) / 2);
        return { x: x0 + i * (w + gap), y: bottom - h, w: w, h: h };
    }
    function elapsed(ms: real): string {
        const m = Math.floor(ms / 60000);
        return m < 1 ? "now" : m < 60 ? m + " min" : Math.floor(m / 60) + " h " + (m % 60) + " min";
    }

    Connections {
        target: Agents
        function onLiveChanged(): void {
            v.sync();
        }
    }
    Timer {
        id: reap
        interval: 620
        onTriggered: v.sync()
    }
    Component.onCompleted: v.sync()

    Lead {
        visible: v.count === 4
        x: 10
        width: v.width - 20
        y: v.height - 3 - 50 - 6
        height: 5
        src: Theme.shared("came-h.png")
        depth: 2.2
        lx: 0.5
        ly: -0.15
    }

    Repeater {
        model: ScriptModel {
            values: v.shown.map(e => ({ sid: e.sid }))
            objectProp: "sid"
        }
        Item {
            id: vial
            required property var modelData
            readonly property var e: v.bySid[vial.modelData.sid] || null
            readonly property var s: vial.e ? vial.e.s : null
            readonly property bool leaving: !vial.e || vial.e.leaving
            readonly property string st: vial.s ? vial.s.state : "idle"
            readonly property int index: v.order.indexOf(vial.modelData.sid)
            readonly property var g: v.slot(Math.max(0, vial.index), Math.max(1, v.count))
            readonly property string key: "agent:" + vial.modelData.sid
            readonly property bool hovered: v.host.activeKey === vial.key
            readonly property real pulse: vial.st === "needs" ? 0.5 + 0.5 * Math.sin(v.host.t * 4.2) : 0
            readonly property real fresh: vial.st === "done" && vial.s ? Math.max(0, 1 - (Agents.now - vial.s.updated) / 600000) : 0
            property real born: 0

            x: vial.g.x
            y: vial.g.y
            width: vial.g.w
            height: vial.g.h
            opacity: vial.leaving ? 0 : vial.born
            scale: vial.leaving ? 0.86 : 0.86 + 0.14 * vial.born
            transformOrigin: Item.Bottom
            Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.InOutCubic } }
            Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.InOutCubic } }
            Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.InOutCubic } }
            Behavior on height { NumberAnimation { duration: 450; easing.type: Easing.InOutCubic } }
            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Component.onCompleted: vial.born = 1

            Glow {
                anchors.centerIn: parent
                width: parent.width * 2.2
                height: parent.height * 1.25
                color: vial.st === "needs" ? v.gold : vial.st === "done" ? v.bright : vial.st === "working" ? v.brewColor : v.tint
                core: 0.2
                intensity: (vial.st === "needs" ? 0.35 + 0.65 * vial.pulse : vial.st === "done" ? 0.3 + 0.4 * vial.fresh : vial.st === "working" ? 0.26 : 0.03) + (vial.hovered ? 0.18 : 0)
            }
            Potion {
                anchors.fill: parent
                sprite: v.sprite
                level: vial.st === "idle" ? 0.55 : 0.88
                swirl: vial.st === "working" ? 1 : 0
                bubbles: vial.st === "working" ? 0.7 : 0
                time: vial.st === "working" ? v.host.t * 0.6 : 0
                cloud: vial.st === "idle" ? 0.85 : 0
                wash: vial.st === "needs" ? 0.62 + 0.3 * vial.pulse : vial.st === "done" ? 0.4 + 0.35 * vial.fresh : vial.st === "working" ? v.brewWash : 0
                washColor: vial.st === "needs" ? v.needsWash : vial.st === "done" ? v.doneWash : v.brewColor
                boost: vial.st === "done" ? 0.3 + 0.5 * vial.fresh : vial.st === "needs" ? 0.1 + 0.3 * vial.pulse : vial.st === "working" ? 0.1 : 0
            }
            MouseArea {
                anchors.fill: parent
                enabled: v.interactive && !vial.leaving
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: v.host.hoverKey = vial.key
                onExited: if (v.host.hoverKey === vial.key) v.host.hoverKey = ""
                onClicked: {
                    if (!vial.s)
                        return;
                    const w = Gauges.terminalOf(vial.s);
                    if (w)
                        Hypr.focusWindow(w.address);
                    Bus.say({ title: vial.s.label, body: vial.s.detail || "", kind: "agent", sid: vial.s.sid });
                }
            }
        }
    }

    Item {
        visible: v.extra > 0
        x: v.width - 15
        y: 1
        width: 22
        height: 22
        Piece {
            anchors.fill: parent
            name: "lancet-seal"
            power: 0.5
            ambient: 0.6
            glow: v.host.activeKey === "agents+" ? 0.8 : 0.35
            Behavior on glow { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        }
        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 0.5
            text: "+" + v.extra
            font.family: Theme.ui
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.features: { "lnum": 1, "tnum": 1 }
            color: Theme.dark ? Theme.rare : Theme.sun
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -3
            enabled: v.interactive
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: v.host.hoverKey = "agents+"
            onExited: if (v.host.hoverKey === "agents+") v.host.hoverKey = ""
            onClicked: Bus.sanctum("")
        }
    }
}
