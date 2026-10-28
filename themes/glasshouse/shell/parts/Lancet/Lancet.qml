import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

Scope {
    id: part

    required property ShellScreen screen
    readonly property var geo: Anchor.of(part.screen.name)
    readonly property bool main: !!part.geo && part.geo.role === "main"
    readonly property bool folded: !!part.geo && part.geo.folded
    readonly property bool stowed: part.folded && part.main
    readonly property bool peek: part.stowed && (edge.hovered || handle.lit)
    property real reveal: part.stowed && !part.peek ? 0 : 1
    Behavior on reveal {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    readonly property real u: part.geo ? part.geo.u : 1
    readonly property var tip: body.covered || part.folded ? null : body.tip
    property var shownTip: null
    property bool tipOn: false
    property bool slide: true
    property real lastTick: 0
    property bool built: false
    property real shut: part.folded ? 1 : 0
    Behavior on shut {
        enabled: part.built
        NumberAnimation {
            duration: 278
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.2, 0.9, 0.24, 1, 1, 1]
        }
    }
    readonly property real travel: !part.geo ? 0 : part.main ? -(part.geo.x + part.geo.w) : part.geo.zone - part.geo.x + part.geo.strip
    readonly property int reach: part.geo ? part.geo.reach : 84
    property int zone: part.reach
    property bool moved: false
    Connections {
        target: body.Window.window
        enabled: part.zone !== part.reach
        function onAfterAnimating(): void {
            part.moved = !part.built || (part.shut > 0 && part.shut < 1);
        }
        function onFrameSwapped(): void {
            if (part.moved)
                part.zone = part.reach;
        }
    }
    property bool warm: false
    Connections {
        target: body.Window.window
        enabled: !part.warm
        function onFrameSwapped(): void {
            part.warm = true;
        }
    }

    onFoldedChanged: {
        if (!part.built)
            return;
        if (part.folded)
            handle.shine();
        body.hoverKey = "";
        Sfx.play(part.folded ? "menu-close" : "menu-open", 0.6);
    }
    Component.onCompleted: part.built = true

    onTipChanged: {
        if (part.tip) {
            const far = part.tipOn && !!part.shownTip && Math.abs(part.tip.y - part.shownTip.y) > 200;
            part.slide = !far;
            part.shownTip = part.tip;
            if (far)
                Qt.callLater(() => part.slide = true);
            part.tipOn = true;
            tipLinger.stop();
        } else if (part.tipOn) {
            part.tipOn = false;
            tipLinger.restart();
        }
    }
    Timer {
        id: tipLinger
        interval: 400
    }

    PanelWindow {
        id: win
        screen: part.screen
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "glasshouse-lancet"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        anchors {
            top: true
            bottom: true
            left: part.main
            right: !part.main
        }
        implicitWidth: part.geo ? part.geo.zone : 84
        exclusiveZone: part.stowed ? 0 : part.zone
        color: "transparent"
        mask: Region {
            item: hit
        }

        Item {
            id: hit
            x: part.folded && !part.main ? win.width - part.reach : 0
            y: part.folded ? part.geo.handle.y - 14 * part.u : 0
            width: part.folded ? (part.stowed && !part.peek ? 4 * part.u : part.reach) : win.width
            height: part.folded ? part.geo.handle.h + 28 * part.u : win.height
            HoverHandler {
                id: edge
            }
        }
        Handle {
            id: handle
            output: part.screen.name
            visible: part.shut > 0 && part.reveal > 0
            opacity: part.reveal
            x: (part.geo ? part.geo.handle.x - part.geo.strip : 0) - (1 - part.reveal) * 14 * part.u
            y: part.geo ? part.geo.handle.y : 0
            scale: part.u
            transformOrigin: Item.TopLeft
        }
        LancetBody {
            id: body
            output: part.screen.name
            visible: part.shut < 1 || !part.warm
            x: Math.round((part.geo ? part.geo.x - part.geo.strip : 0) + part.shut * part.travel * (part.warm ? 1 : 2))
            y: part.geo ? part.geo.y : 0
            scale: part.u
            transformOrigin: Item.TopLeft
        }
    }

    PanelWindow {
        id: tipWin
        readonly property int bleed: Math.round(18 * part.u)
        screen: part.screen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "glasshouse-lancet-tip"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors {
            top: true
            bottom: true
            left: part.main
            right: !part.main
        }
        margins.left: part.main ? part.geo.zone - tipWin.bleed : 0
        margins.right: part.main ? 0 : part.geo.zone - tipWin.bleed
        implicitWidth: part.tipOn || tipLinger.running ? Math.round(340 * part.u) + tipWin.bleed : 1
        color: "transparent"
        mask: Region {}

        Tip {
            id: plaque
            info: part.shownTip
            shown: part.tipOn
            edge: part.main ? "left" : "right"
            readonly property real target: (part.geo ? part.geo.y : 0) + (part.shownTip ? part.shownTip.y * part.u : 0)
            scale: part.u
            transformOrigin: Item.TopLeft
            x: part.main ? tipWin.bleed + 10 * part.u : parent.width - (width + 10) * part.u - tipWin.bleed
            y: Math.round(Math.max(6 * part.u, Math.min(parent.height - (height + 6) * part.u, target - height * part.u / 2)))
            aim: (target - y) / part.u
            Behavior on y {
                enabled: plaque.visible && part.slide
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
        }
    }

    Connections {
        target: Hypr
        function onWorkspaceSwitched(monitor: string, from: int, to: int): void {
            if (monitor !== part.screen.name)
                return;
            const i = Screens.workspaces(monitor).indexOf(to);
            if (i >= 0)
                Sfx.note(i);
        }
    }
    Connections {
        target: Gauges
        enabled: part.main && !Audio.phial
        function onVolumeTouched(): void {
            const n = Date.now();
            if (n - part.lastTick < 140)
                return;
            part.lastTick = n;
            Sfx.play("volume");
        }
    }
}
