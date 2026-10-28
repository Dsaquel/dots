import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.kit
import qs.parts.Lancet

PanelWindow {
    id: win

    required property ShellScreen modelData
    readonly property var geo: Anchor.of(win.modelData.name)
    readonly property bool main: !!win.geo && win.geo.role === "main"
    readonly property bool roundel: win.main && !!win.geo.roundel
    readonly property real u: win.geo ? win.geo.u : Screens.unit(win.modelData.name)
    readonly property real reach: win.geo ? win.geo.reach / win.u : 84
    readonly property bool on: Inbox.screen === win.modelData.name && Inbox.stack.count > 0
    readonly property real ww: 600
    readonly property real wh: 800
    readonly property real wtop: win.modelData.height - win.wh * win.u
    readonly property point her: win.roundel ? Qt.point(win.geo.roundel.cx / win.u, (win.geo.roundel.cy - win.wtop) / win.u) : Qt.point(win.main ? win.reach + 44 : win.ww - win.reach - 44, win.wh - 114)
    readonly property real herR: win.roundel ? win.geo.roundel.r / win.u : 36
    readonly property point tip: win.main ? Qt.point(win.her.x + win.herR + 1, win.her.y + 10) : Qt.point(win.her.x - win.herR - 1, win.her.y + 10)
    readonly property real paneW: 400
    readonly property real paneX: win.roundel ? win.reach + 32 : win.main ? win.tip.x + 37 : win.tip.x - 37 - win.paneW
    readonly property real base: win.her.y + 46
    property var heights: ({})
    property int rev: 0
    property real herAt: -99
    property color herColor: Theme.dark ? Theme.lamp : Theme.sun
    readonly property real herLight: {
        const d = motion.t - win.herAt;
        if (d < 0 || d > 0.9)
            return 0;
        return d < 0.16 ? motion.out(d / 0.16) : 1 - motion.inout((d - 0.16) / 0.74);
    }

    function setH(key: string, h: real): void {
        if (win.heights[key] !== h) {
            win.heights[key] = h;
            win.rev++;
        }
    }
    function live(): var {
        win.rev;
        const out = [];
        for (let j = 0; j < Inbox.stack.count; j++)
            if (!Inbox.stack.get(j).leaving)
                out.push(j);
        return out;
    }
    function floorOf(i: int): real {
        let y = win.base;
        for (const j of win.live())
            if (j > i)
                y -= (win.heights[Inbox.stack.get(j).key] || 90) + 12;
        return y;
    }
    function rankOf(i: int): int {
        return win.live().filter(j => j > i).length;
    }
    function newestIndex(): int {
        const l = win.live();
        return l.length ? l[l.length - 1] : -1;
    }
    function stackTop(): real {
        let y = win.base;
        for (const j of win.live())
            y -= (win.heights[Inbox.stack.get(j).key] || 90) + 12;
        return y;
    }

    screen: win.modelData
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "glasshouse-chat"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors {
        bottom: true
        left: win.main
        right: !win.main
    }
    implicitWidth: win.on ? Math.round(win.ww * win.u) : 1
    implicitHeight: win.on ? Math.round(win.wh * win.u) : 1
    color: "transparent"
    mask: Region {
        item: hit
    }

    Clock {
        id: motion
    }

    Connections {
        target: Inbox.stack
        function onCountChanged(): void {
            win.rev++;
        }
        function onDataChanged(): void {
            win.rev++;
        }
    }
    Connections {
        target: Inbox
        enabled: win.on
        function onRisen(key: string, urgency: int): void {
            win.herColor = urgency >= 2 ? (Theme.dark ? Theme.rare : Theme.sun) : (Theme.dark ? Theme.lamp : Theme.sun);
            win.herAt = motion.kick(0.9, false);
        }
    }

    property real faceAt: -99
    onOnChanged: if (win.on && !win.roundel)
        win.faceAt = motion.kick(0.4, false)

    Item {
        width: win.ww
        height: win.wh
        scale: win.u
        transformOrigin: Item.TopLeft

        Glass {
            visible: win.herLight > 0.005
            x: win.her.x - width / 2
            y: win.her.y - height / 2
            width: win.herR * 200 / 46
            height: width
            src: Theme.shared("chat-speak.png")
            additive: 1
            ambient: 0
            power: 0.5 * win.herLight
            radius: 2
            grain: 0
            tint: win.herColor
        }

        Face {
            visible: !win.roundel && win.on
            opacity: motion.out((motion.t - win.faceAt) / 0.4)
            x: win.her.x - width / 2
            y: win.her.y - height / 2
            width: 2 * win.herR
            height: width
        }

        Repeater {
            model: win.on ? Inbox.stack : null
            delegate: Bubble {
                clock: motion
                paneX: win.paneX
                paneW: win.paneW
                tip: win.tip
                mirror: !win.main
                newest: index === win.newestIndex()
                rank: win.rankOf(index)
                floor: win.floorOf(index)
                onPaneHChanged: win.setH(key, paneH)
                Component.onCompleted: win.setH(key, paneH)
            }
        }
    }

    Item {
        id: hit
        readonly property real t: win.on ? win.stackTop() : 0
        x: win.on ? (win.paneX - 4) * win.u : 0
        y: win.on ? Math.max(0, hit.t + 6) * win.u : 0
        width: win.on ? (win.paneW + 8) * win.u : 0
        height: win.on ? Math.max(0, win.base - hit.t + 4) * win.u : 0
    }
}
