import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.core
import qs.parts.Chat

PanelWindow {
    id: win

    readonly property real paneW: 560
    readonly property real headH: 64
    readonly property real pitch: 50
    readonly property real rowH: 46
    readonly property int slots: 8
    readonly property real listY: win.headH + 12
    readonly property real paneH: win.listY + (win.slots - 1) * win.pitch + win.rowH + 14
    readonly property real m: 40
    readonly property real u: win.screen ? Screens.fit(win.screen.width, win.screen.height) : 1
    readonly property color gold: Theme.dark ? Theme.rare : Theme.sun
    readonly property var rows: Keeper.results
    readonly property int count: win.rows.length
    property int first: 0
    property bool warm: false
    signal warmed()

    WlrLayershell.layer: win.warm ? WlrLayer.Background : WlrLayer.Overlay
    WlrLayershell.namespace: win.warm ? "glasshouse-warm" : "glasshouse-reliquary"
    WlrLayershell.keyboardFocus: !win.warm && !Test.on && Keeper.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Math.round((win.paneW + 2 * win.m) * win.u)
    implicitHeight: Math.round((win.paneH + 2 * win.m) * win.u)
    color: "transparent"
    mask: Region {
        item: hit
    }

    HyprlandFocusGrab {
        active: !win.warm && !Test.on && Keeper.opened
        windows: [win]
        onCleared: Keeper.close()
    }

    Clock {
        id: clock
    }
    property real openAt: -99
    property bool closing: false
    property real closeAt: -99
    property real closeFrom: 1
    function riseNow(): real {
        return clock.out((clock.t - win.openAt) / 0.15);
    }
    readonly property real reveal: win.closing ? win.closeFrom * (1 - clock.inout((clock.t - win.closeAt - win.holdS) / win.fadeS)) : win.riseNow()
    readonly property real holdS: Keeper.pasting ? 0.07 : 0
    readonly property real fadeS: Keeper.pasting ? 0.22 : 0.13
    readonly property real bloom: {
        const d = (clock.t - win.openAt) / 0.6;
        return !win.closing && d < 1 ? 1 - clock.out(d) : 0;
    }
    function rise(): void {
        win.closing = false;
        win.moved = false;
        win.seen = Qt.point(-1, -1);
        win.openAt = clock.kick(0.15, true);
        clock.kick(0.6, false);
    }
    Connections {
        target: Keeper
        enabled: !win.warm
        function onOpenedChanged(): void {
            if (Keeper.opened) {
                done.stop();
                win.rise();
            } else {
                win.closeFrom = win.riseNow();
                win.closeAt = clock.kick(win.holdS + win.fadeS, true);
                win.closing = true;
                done.start();
            }
        }
        function onSelectedChanged(): void {
            win.follow();
            win.glide();
        }
        function onResultsChanged(): void {
            win.follow();
            win.glide();
        }
    }
    Timer {
        running: win.warm
        interval: 2000
        onTriggered: win.warmed()
    }
    Timer {
        id: done
        interval: Math.round((win.holdS + win.fadeS) * 1000) + 30
        onTriggered: Keeper.shown = false
    }

    function follow(): void {
        let t = win.first;
        if (Keeper.selected < t)
            t = Keeper.selected;
        else if (Keeper.selected >= t + win.slots)
            t = Keeper.selected - win.slots + 1;
        win.first = Math.max(0, Math.min(t, Math.max(0, win.count - win.slots)));
    }
    readonly property real selAim: win.m + win.listY + Math.max(0, Keeper.selected - win.first) * win.pitch
    property real selFrom: 0
    property real selTo: 0
    property real selAt: -99
    readonly property real selY: clock.glide(win.selFrom, win.selTo, win.selAt, 0.1)
    function glide(): void {
        if (win.selTo === win.selAim)
            return;
        win.selFrom = win.selY;
        win.selTo = win.selAim;
        win.selAt = clock.kick(0.1, true);
    }

    property bool moved: false
    property point seen: Qt.point(-1, -1)

    property real madeAt: Date.now()
    Component.onCompleted: {
        win.follow();
        win.selFrom = win.selTo = win.selAim;
        win.rise();
    }

    Item {
        id: hit
        x: (win.m - 2) * win.u
        y: (win.m - 26) * win.u
        width: !win.warm && win.reveal > 0.3 ? (win.paneW + 4) * win.u : 0
        height: (win.paneH + 28) * win.u
    }

    Item {
        id: body
        width: win.width / win.u
        height: win.height / win.u
        scale: win.u
        transformOrigin: Item.TopLeft
        opacity: win.warm ? 0.01 : win.closing ? win.reveal : 0.55 + 0.45 * win.reveal
        transform: Translate {
            y: Math.round((1 - win.reveal) * (win.closing ? 4 : 6))
        }

        BorderImage {
            x: win.m - 26
            y: win.m - 18
            width: win.paneW + 52
            height: win.paneH + 58
            source: Theme.shared("lancet-shadow.png")
            border {
                left: 30
                right: 30
                top: 30
                bottom: 30
            }
            opacity: 0.85
        }
        Pane {
            anchors.fill: parent
            pane: Qt.vector4d(win.m, win.m, win.paneW, win.paneH)
            radius: 16
            rim: 3.2
            band: 6
            inner: 1.8
            jewel: 13
            cornerGlow: 0.3
            header: win.headH
            headTop: Theme.dark ? "#2e3a8c" : "#4b3aa6"
            headBottom: Theme.dark ? "#1f2766" : "#3a2d8c"
            bodyTop: Theme.dark ? "#171c44" : "#22258a"
            bodyBottom: Theme.dark ? "#0d102e" : "#171a6c"
            glassAlpha: 0.97
            lightPos: Qt.vector2d(win.m + win.paneW / 2, win.m)
            lightRadius: 300 + 120 * win.bloom
            lightPower: 0.42 + 0.5 * win.bloom
            spill: 0.3
            haloSize: 18
            shadow: 0.55
        }

        Pane {
            id: crest
            readonly property real d: 44
            x: win.m + win.paneW / 2 - crest.d / 2 - 6
            y: win.m - crest.d / 2 - 6
            width: crest.d + 12
            height: crest.d + 16
            pane: Qt.vector4d(6, 6, crest.d, crest.d)
            radius: crest.d / 2
            rim: 2.4
            band: 5
            inner: 1.4
            jewel: 7
            jewelA: Theme.dark ? "#3558b8" : "#e8759a"
            bodyTop: Theme.dark ? "#121733" : "#1a1d6a"
            bodyBottom: Theme.dark ? "#0a0d22" : "#12145a"
            glassAlpha: 1
            lightPos: Qt.vector2d(14, 10)
            lightRadius: 40
            lightPower: 0.4 + 0.5 * win.bloom
            shadow: 0.45
        }
        Text {
            x: crest.x + 6 + crest.d / 2 - width / 2
            y: crest.y + 6 + crest.d / 2 - height / 2
            text: "\u{f014c}"
            font.family: Theme.glyphs
            font.pixelSize: 18
            color: win.gold
        }

        Item {
            id: head
            x: win.m
            y: win.m + 3
            width: win.paneW
            height: win.headH
        }
        Text {
            x: win.m + 26
            anchors.verticalCenter: head.verticalCenter
            text: "\u{f0349}"
            font.family: Theme.glyphs
            font.pixelSize: 17
            color: win.gold
        }
        Text {
            id: query
            x: win.m + 54
            width: win.paneW - 54 - 76
            anchors.verticalCenter: head.verticalCenter
            text: Keeper.query
            elide: Text.ElideLeft
            font.family: Theme.ui
            font.pixelSize: 17
            color: Theme.ink
        }
        Text {
            visible: Keeper.query === ""
            x: query.x
            anchors.verticalCenter: head.verticalCenter
            text: "Search the clipboard"
            font.family: Theme.ui
            font.pixelSize: 16
            font.italic: true
            color: Theme.dim
            opacity: 0.85
        }
        Rectangle {
            x: query.x + (Keeper.query === "" ? -1 : Math.min(query.width, query.implicitWidth) + 2)
            width: 2
            height: 20
            anchors.verticalCenter: head.verticalCenter
            color: win.gold
        }
        Text {
            visible: win.count > 0
            anchors.right: head.right
            anchors.rightMargin: 26
            anchors.verticalCenter: head.verticalCenter
            text: win.count
            font.family: Theme.numerals
            font.pixelSize: 17
            font.features: { "lnum": 1, "tnum": 1 }
            color: Theme.dim
        }

        Repeater {
            model: win.slots - 1
            Rectangle {
                required property int index
                visible: index + 1 < win.count
                x: win.m + 26
                y: win.m + win.listY + (index + 1) * win.pitch - (win.pitch - win.rowH) / 2 - 0.5
                width: win.paneW - 52
                height: 1
                color: Theme.dark ? Theme.metalSky : Theme.metalBase
                opacity: 0.22
            }
        }
        Pane {
            visible: win.count > 0
            x: win.m + 14 - 5
            y: win.selY - 3
            width: win.paneW - 28 + 10
            height: win.rowH + 11
            pane: Qt.vector4d(5, 3, win.paneW - 28, win.rowH)
            radius: 11
            rim: 1.9
            shadow: 0.32
            bodyTop: "#f6efe0"
            bodyBottom: "#ddd0b6"
            glassAlpha: 0.98
            lightPos: Qt.vector2d(40, 2)
            lightRadius: 160
            lightPower: 0.12
            grain: 0.05
            goldMix: Keeper.pasting ? 1 : 0
            flash: Keeper.pasting ? 1 : 0
            lift: Keeper.pasting ? 1 : 0
            spill: Keeper.pasting ? 1 : 0
            haloSize: 16
        }
        Repeater {
            model: win.slots
            Slip {
                required property int index
                readonly property int at: win.first + index
                visible: at < win.count
                x: win.m + 14
                y: win.m + win.listY + index * win.pitch
                width: win.paneW - 28
                height: win.rowH
                r: at < win.count ? win.rows[at] : null
                sel: Math.abs(win.selY - y) < win.pitch / 2
            }
        }

        Rectangle {
            readonly property real track: (win.slots - 1) * win.pitch + win.rowH
            visible: win.count > win.slots
            x: win.m + win.paneW - 12
            y: win.m + win.listY + (track - height) * (win.first / Math.max(1, win.count - win.slots))
            width: 4
            height: Math.max(18, track * win.slots / Math.max(win.slots, win.count))
            radius: 2
            color: win.gold
        }

        Column {
            visible: win.count === 0
            anchors.horizontalCenter: head.horizontalCenter
            y: win.m + win.listY + 118
            spacing: 14
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Keeper.query === "" ? "\u{f014c}" : "\u{f0980}"
                font.family: Theme.glyphs
                font.pixelSize: 54
                color: win.gold
                opacity: 0.3
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Keeper.query === "" ? "The clipboard is empty" : "Nothing matches “" + Keeper.query + "”"
                font.family: Theme.ui
                font.pixelSize: 15
                font.italic: true
                color: Theme.dim
            }
        }

        MouseArea {
            id: pointer
            x: win.m + 14
            y: win.m + win.listY
            width: win.paneW - 28
            height: win.slots * win.pitch
            hoverEnabled: true
            function at(my: real): int {
                return win.first + Math.floor(my / win.pitch);
            }
            onPositionChanged: mouse => {
                if (!win.moved) {
                    if (win.seen.x < 0) {
                        win.seen = Qt.point(mouse.x, mouse.y);
                        return;
                    }
                    if (Math.abs(mouse.x - win.seen.x) + Math.abs(mouse.y - win.seen.y) < 4)
                        return;
                    win.moved = true;
                }
                const i = pointer.at(mouse.y);
                if (Keeper.opened && i < win.count)
                    Keeper.selected = i;
            }
            onClicked: mouse => {
                const i = pointer.at(mouse.y);
                if (Keeper.opened && i < win.count) {
                    Keeper.selected = i;
                    Keeper.paste(win.rows[i]);
                }
            }
            onWheel: wheel => Keeper.move(wheel.angleDelta.y > 0 ? -1 : 1)
        }

        Connections {
            target: body.Window.window
            enabled: win.warm
            function onFrameSwapped(): void {
                win.warmed();
            }
        }
        Connections {
            target: body.Window.window
            enabled: !win.warm && Keeper.firstFrame < 0
            function onFrameSwapped(): void {
                Keeper.firstFrame = Date.now() - Keeper.askedAt;
                if (Test.on)
                    console.log("reliquary: first frame " + Date.now() + " (" + Keeper.firstFrame + " ms after the ask; window made +" + (win.madeAt - Keeper.askedAt) + ")");
            }
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (Keeper.opened && Keeper.keyEvent(event))
                event.accepted = true;
        }
    }
}
