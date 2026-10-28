import QtQuick
import qs.core
import qs.kit

Item {
    id: r

    property string kind: "main"
    readonly property real unit: Screens.unitOf(r)
    property var rose: ({ cx: 0, cy: 0, r: 44, heart: 13 })
    property var workspaces: []
    property int current: -1
    property int previous: -1
    property real pulse: 0
    property real t: 0
    property real switchAt: -9
    readonly property real s: r.t - r.switchAt
    readonly property real hand: r.s >= 0 && r.s < 0.45 ? 1 - Math.pow(1 - r.s / 0.45, 3) : 1
    property bool interactive: true
    property string hoverKey: ""
    readonly property real rad: r.rose.r
    readonly property string prefix: "lancet-" + r.kind + "-rose"
    readonly property point light: Qt.point(Theme.dark ? 0.8 : 0.25, 0.1)
    readonly property var angs: [0, 1, 2, 3, 4].map(k => -Math.PI / 2 + k * 2 * Math.PI / 5)
    readonly property bool pulsing: r.workspaces.some(ws => ws !== r.current && Hypr.wsUrgent(ws))
    readonly property int currentIndex: r.workspaces.indexOf(r.current)

    signal hovered(string key)
    property real wheelAcc: 0

    width: 2 * r.rad + 8
    height: width

    function mix(a: color, b: color, k: real): color {
        return Qt.rgba(a.r + (b.r - a.r) * k, a.g + (b.g - a.g) * k, a.b + (b.b - a.b) * k, 1);
    }
    function keyAt(x: real, y: real): string {
        const dx = x - r.width / 2;
        const dy = y - r.height / 2;
        const d = Math.hypot(dx, dy);
        if (d <= r.rose.heart + 2)
            return "rose";
        if (d > r.rad + 3)
            return "";
        const a = ((Math.atan2(dy, dx) + Math.PI / 2) % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI);
        const i = Math.round(a / (2 * Math.PI / 5)) % 5;
        return i < r.workspaces.length ? "ws" + r.workspaces[i] : "";
    }
    function tipOf(key: string): var {
        if (key === "rose")
            return { x: r.width / 2, y: r.height / 2 };
        const i = r.workspaces.indexOf(Number(key.slice(2)));
        if (i < 0)
            return null;
        return { x: r.width / 2 + r.rad * 0.62 * Math.cos(r.angs[i]), y: r.height / 2 + r.rad * 0.62 * Math.sin(r.angs[i]) };
    }

    Item {
        id: glass
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        layer.mipmap: true
        layer.textureSize: Qt.size(2 * width * r.unit, 2 * height * r.unit)

        Glass {
            anchors.fill: parent
            src: Theme.a(r.prefix + "-frame-glow.png")
            additive: 1
            ambient: 0
            power: r.hoverKey === "rose" ? 0.62 : 0.32
            Behavior on power { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            radius: 2
            light: r.light
            grain: 0
        }
        Glass {
            anchors.fill: parent
            src: Theme.a(r.prefix + "-frame.png")
            light: r.light
            power: 0.5
            ambient: 0.66
        }
        Repeater {
            model: 5
            Item {
                id: petal
                required property int index
                readonly property int ws: index < r.workspaces.length ? r.workspaces[index] : -1
                readonly property bool isCurrent: petal.ws === r.current
                readonly property bool isUsed: Hypr.wsCount(petal.ws) > 0
                readonly property bool isUrgent: !petal.isCurrent && Hypr.wsUrgent(petal.ws)
                readonly property real lit: petal.isCurrent ? r.hand : (petal.ws === r.previous ? 1 - r.hand : 0)
                property real hov: r.hoverKey === "ws" + petal.ws ? 1 : 0
                Behavior on hov { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                readonly property real rest: petal.isUrgent ? 0.7 + 0.3 * r.pulse : (petal.isUsed ? 0.66 : 0.34)
                readonly property color restTint: petal.isUrgent ? (Theme.dark ? Qt.rgba(1, 0.84 + 0.08 * r.pulse, 0.36 + 0.14 * r.pulse, 1) : Qt.rgba(1, 0.58 + 0.12 * r.pulse, 0.22 + 0.1 * r.pulse, 1)) : petal.isUsed ? (Theme.dark ? "#6f95f0" : "#9fb4ff") : (Theme.dark ? "#2a3674" : "#4b49b8")
                anchors.fill: parent
                Glass {
                    anchors.fill: parent
                    src: Theme.a(r.prefix + "-petal-" + (petal.index + 1) + "-glow.png")
                    additive: 1
                    ambient: 0
                    radius: 2
                    grain: 0
                    light: r.light
                    power: 1.15 * petal.lit + (petal.isUrgent ? (0.45 + 0.75 * r.pulse) * (1 - petal.lit) : 0) + 0.4 * petal.hov * (1 - petal.lit)
                    tint: petal.isUrgent && !petal.isCurrent ? (Theme.dark ? "#ffc23c" : "#ff9a3a") : (Theme.dark ? "#ffb35a" : "#ffc861")
                }
                Glass {
                    anchors.fill: parent
                    src: Theme.a(r.prefix + "-petal-" + (petal.index + 1) + ".png")
                    light: r.light
                    ambient: petal.rest + ((Theme.dark ? 0.74 : 0.98) - petal.rest) * petal.lit + 0.16 * petal.hov * (1 - petal.lit)
                    power: 0.32 + ((Theme.dark ? 0.5 : 0.7) - 0.32) * petal.lit
                    tint: r.mix(petal.restTint, Theme.dark ? "#ff9a42" : "#ffcf5c", petal.lit)
                }
            }
        }
        Moon {
            visible: Theme.dark
            anchors.centerIn: parent
            width: 2 * r.rose.heart - 5
            height: width
        }
        Lead {
            anchors.fill: parent
            src: Theme.a(r.prefix + "-lead.png")
            depth: 3.4
            lx: r.light.x - 0.4
            ly: r.light.y - 1.0
        }
        Gilt {
            visible: !Theme.dark
            anchors.fill: parent
            src: Theme.a(r.prefix + "-gilt.png")
            depth: 3
            lx: 0.2
            ly: -0.6
        }
        Image {
            visible: !Theme.dark && r.currentIndex >= 0
            opacity: r.hand
            readonly property real a: r.angs[Math.max(0, r.currentIndex)]
            width: Math.round(r.rad * 0.3)
            height: width
            x: r.width / 2 + (r.rad - 9) * Math.cos(a) - width / 2
            y: r.height / 2 + (r.rad - 9) * Math.sin(a) - height / 2
            source: Theme.a("lancet-glint.png")
            smooth: true
            mipmap: true
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: r.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: r.keyAt(mouseX, mouseY) !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPositionChanged: mouse => r.hovered(r.keyAt(mouse.x, mouse.y))
        onExited: r.hovered("")
        onClicked: mouse => {
            const key = r.keyAt(mouse.x, mouse.y);
            if (key === "rose")
                Bus.sanctum("");
            else if (key.startsWith("ws"))
                Hypr.focusWorkspace(Number(key.slice(2)));
        }
        onWheel: wheel => {
            r.wheelAcc += wheel.angleDelta.y;
            if (Math.abs(r.wheelAcc) < 120 || r.workspaces.length === 0)
                return;
            const step = r.wheelAcc < 0 ? 1 : -1;
            r.wheelAcc = 0;
            const n = r.workspaces.length;
            const i = Math.max(0, r.currentIndex);
            Hypr.focusWorkspace(r.workspaces[(i + step + n) % n]);
        }
    }
}
