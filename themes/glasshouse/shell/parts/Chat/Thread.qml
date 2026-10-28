import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.core
import qs.kit
import qs.parts.Lancet

PanelWindow {
    id: win

    required property ShellScreen modelData
    property bool open: true
    property real seenAt: 0
    signal dismiss()
    signal sunk()

    readonly property var geo: Anchor.of(win.modelData.name)
    readonly property real u: win.geo ? win.geo.u : Screens.unit(win.modelData.name)
    readonly property var rd: {
        const r = win.geo && win.geo.roundel ? win.geo.roundel : win.geo && win.geo.folded ? win.geo.handle : null;
        return r ? { cx: r.cx / win.u, cy: r.cy / win.u, r: r.r / win.u } : { cx: 52, cy: 966, r: 46 };
    }
    readonly property real paneX: (win.geo ? win.geo.reach / win.u : 104) + 32
    readonly property real paneW: 430
    readonly property real paneBottom: win.rd.cy + 46
    readonly property real maxH: win.paneBottom - 92
    readonly property real wantH: Math.max(330, Math.min(win.maxH, win.headH + win.footH + 12 + col.height + 14))
    property real hFrom: win.wantH
    property real hTo: win.wantH
    property real hAt: -99
    readonly property real paneH: clock.glide(win.hFrom, win.hTo, win.hAt, 0.42)
    onWantHChanged: {
        if (!win.ready || win.reveal < 1) {
            win.hFrom = win.hTo = win.wantH;
            return;
        }
        const cur = win.paneH;
        win.hFrom = cur;
        win.hTo = win.wantH;
        win.hAt = clock.kick(0.42, true);
    }
    readonly property real paneTop: win.paneBottom - win.paneH
    readonly property point tip: Qt.point(win.rd.cx + win.rd.r + 1, win.rd.cy + 10)
    readonly property real headH: 84
    readonly property real footH: 62
    readonly property var en: Qt.locale("en_GB")
    readonly property color gold: Theme.dark ? Theme.rare : Theme.sun
    readonly property var faces: Her.faces[World.name] || Her.faces.dark
    readonly property var moodOf: ({ message: "message", error: "error", low: "rest", info: "greet", needs: "needs", done: "done" })

    readonly property var groups: {
        const by = {};
        const order = [];
        for (const e of Inbox.today) {
            const k = e.appKey || "glasshouse";
            if (!by[k]) {
                by[k] = { key: k, app: e.app, icon: e.icon, items: [], last: 0 };
                order.push(k);
            }
            const g = by[k];
            g.items.push(e);
            g.last = Math.max(g.last, e.time);
            g.app = e.app || g.app;
            g.icon = e.icon || g.icon;
            g.kind = e.kind;
        }
        return order.map(k => by[k]).sort((a, b) => a.last - b.last);
    }

    function face(kind: string): string {
        return Assets.face(World.name, win.faces[win.moodOf[kind] || "rest"] || win.faces.rest);
    }
    function scroll(dy: real): void {
        flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, flick.contentY + dy));
    }
    function toBottom(): void {
        flick.contentY = Math.max(0, flick.contentHeight - flick.height);
    }

    screen: win.modelData
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "glasshouse-chat-thread"
    WlrLayershell.keyboardFocus: Test.on ? WlrKeyboardFocus.None : WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors {
        left: true
        bottom: true
    }
    implicitWidth: Math.round(600 * win.u)
    implicitHeight: win.modelData.height
    color: "transparent"
    mask: Region {
        item: hitArea
    }

    HyprlandFocusGrab {
        active: !Test.on && win.open
        windows: [win]
        onCleared: win.dismiss()
    }

    Clock {
        id: clock
    }
    property real openAt: -99
    property bool ready: false
    property bool closing: false
    property real closeAt: -99
    property real closeFrom: 1
    function revealNow(): real {
        return clock.out((clock.t - win.openAt) / 0.58);
    }
    readonly property real reveal: win.closing ? win.closeFrom * (1 - clock.inout((clock.t - win.closeAt) / 0.38)) : win.revealNow()
    readonly property real sweep: {
        const d = (clock.t - win.openAt - 0.58) / 0.95;
        return !win.closing && d >= 0 && d < 1 ? clock.inout(d) : -1;
    }
    onOpenChanged: {
        if (win.open) {
            sinkTimer.stop();
            win.closing = false;
            win.openAt = clock.kick(0.58, true);
            clock.kick(1.55, false);
        } else {
            win.closeFrom = win.revealNow();
            win.closeAt = clock.kick(0.4, true);
            win.closing = true;
            sinkTimer.start();
        }
    }
    Timer {
        id: sinkTimer
        interval: 420
        onTriggered: win.sunk()
    }
    Component.onCompleted: {
        win.openAt = clock.kick(0.58, true);
        clock.kick(1.55, false);
        win.ready = true;
        Qt.callLater(win.toBottom);
    }

    Item {
        id: hitArea
        x: (win.paneX - 4) * win.u
        y: (win.paneTop - 22) * win.u
        width: win.reveal > 0.5 ? (win.paneW + 8) * win.u : 0
        height: (win.paneH + 26) * win.u
    }

    Item {
        id: body
        width: win.width / win.u
        height: win.height / win.u
        scale: win.u
        transformOrigin: Item.TopLeft
        opacity: Math.min(1, win.reveal * 1.5)
        transform: [
            Scale {
                origin.x: win.tip.x
                origin.y: win.tip.y
                xScale: 0.82 + 0.18 * win.reveal
                yScale: 0.7 + 0.3 * win.reveal
            }
        ]

        Pane {
            anchors.fill: parent
            pane: Qt.vector4d(win.paneX, win.paneTop, win.paneW, win.paneH)
            radius: 18
            band: 7
            jewel: 15
            cornerGlow: 0.35
            header: win.headH
            tailOn: 1
            tailA: Qt.vector2d(win.paneX + 14, win.paneBottom - 27)
            tailB: Qt.vector2d(win.paneX - 12, win.paneBottom - 22)
            tailC: Qt.vector2d(win.tip.x, win.tip.y)
            tailW: Qt.vector2d(12, 1.6)
            bodyTop: Theme.dark ? "#171c44" : "#22258a"
            bodyBottom: Theme.dark ? "#0d102e" : "#171a6c"
            glassAlpha: 0.97
            lightPos: Qt.vector2d(win.tip.x, win.tip.y)
            lightRadius: 320
            lightPower: 0.45
            spill: 0.45
            haloSize: 20
            shadow: 0.55
            sweep: win.sweep
        }

        Medal {
            x: win.paneX + win.paneW / 2 - width / 2
            y: win.paneTop - height / 2 + 2
            width: 34
            height: 34
            own: true
        }

        Text {
            id: day
            anchors.horizontalCenter: parent.left
            anchors.horizontalCenterOffset: win.paneX + win.paneW / 2
            y: win.paneTop + 43 - baselineOffset
            text: wall.date.toLocaleDateString(win.en, "dddd d MMMM").toUpperCase()
            font.family: Theme.caps
            font.pixelSize: 11
            font.letterSpacing: Theme.capsTracking
            font.weight: Font.DemiBold
            color: win.gold
            renderType: Text.NativeRendering
        }
        Text {
            anchors.horizontalCenter: day.horizontalCenter
            y: win.paneTop + 64 - baselineOffset
            readonly property int count: Inbox.today.length
            readonly property int fresh: Inbox.today.filter(e => e.time > win.seenAt).length
            text: [count === 0 ? "" : (count === 1 ? "one message" : count + " messages"), fresh > 0 ? fresh + " new" : "", Settings.dnd ? "she rests" : ""].filter(x => x).join("  ·  ")
            font.family: Theme.ui
            font.pixelSize: 12
            font.variableAxes: { "wght": 460 }
            color: Theme.dim
            renderType: Text.NativeRendering
        }

        Flickable {
            id: flick
            x: win.paneX + 12
            y: win.paneTop + win.headH + 4
            width: win.paneW - 24
            height: win.paneH - win.headH - win.footH - 8
            clip: true
            contentHeight: col.height + 8
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            onContentHeightChanged: if (win.reveal < 1 || atYEnd || contentHeight - contentY - height < 160) Qt.callLater(win.toBottom)

            Column {
                id: col
                width: flick.width
                topPadding: 6
                spacing: 6

                Repeater {
                    model: win.groups
                    Item {
                        id: grp
                        required property var modelData
                        required property int index
                        width: col.width
                        height: notes.y + notes.height
                        opacity: Math.max(0, Math.min(1, win.reveal * 3 - grp.index * 0.12 - 1.2))
                        Face {
                            x: 2
                            y: 0
                            width: 50
                            height: 50
                            face: win.face(grp.modelData.kind)
                        }
                        Row {
                            x: 62
                            y: 17 - appCaps.baselineOffset
                            spacing: 7
                            Image {
                                visible: !!grp.modelData.icon
                                width: 14
                                height: 14
                                anchors.verticalCenter: appCaps.verticalCenter
                                sourceSize: Qt.size(28, 28)
                                source: grp.modelData.icon || ""
                            }
                            Text {
                                id: appCaps
                                text: (grp.modelData.app || "Glasshouse").toUpperCase()
                                font.family: Theme.caps
                                font.pixelSize: 10
                                font.letterSpacing: Theme.capsTracking
                                font.weight: Font.DemiBold
                                color: win.gold
                                renderType: Text.NativeRendering
                            }
                            Text {
                                visible: grp.modelData.items.length > 1
                                text: String(grp.modelData.items.length)
                                anchors.baseline: appCaps.baseline
                                font.family: Theme.numerals
                                font.pixelSize: 12
                                font.features: { "lnum": 1, "tnum": 1 }
                                font.variableAxes: Theme.dark ? ({}) : ({ "wght": 560, "opsz": 12 })
                                color: Theme.dim
                                renderType: Text.NativeRendering
                            }
                        }
                        Column {
                            id: notes
                            x: 52
                            y: 22
                            width: grp.width - 52
                            spacing: -8
                            Repeater {
                                model: grp.modelData.items
                                Note {
                                    required property var modelData
                                    required property int index
                                    width: notes.width
                                    entry: modelData
                                    first: index === 0
                                    fresh: modelData.time > win.seenAt
                                    faceAt: Qt.point(-22, -2)
                                }
                            }
                        }
                    }
                }
            }
        }
        Column {
            visible: Inbox.today.length === 0
            anchors.horizontalCenter: parent.left
            anchors.horizontalCenterOffset: win.paneX + win.paneW / 2
            y: win.paneTop + win.headH + (win.paneH - win.headH - win.footH) / 2 - 60
            spacing: 14
            Face {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 76
                height: 76
                face: win.face("rest")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "QUIET DAY"
                font.family: Theme.caps
                font.pixelSize: 10
                font.letterSpacing: Theme.capsTracking
                font.weight: Font.DemiBold
                color: Theme.dim
                renderType: Text.NativeRendering
            }
        }

        Rectangle {
            x: win.paneX + 18
            y: win.paneBottom - win.footH
            width: win.paneW - 36
            height: 1
            color: Theme.dark ? "#3a3950" : "#c99a4e"
            opacity: 0.8
        }
        Row {
            anchors.horizontalCenter: parent.left
            anchors.horizontalCenterOffset: win.paneX + win.paneW / 2
            y: win.paneBottom - win.footH + 18
            spacing: 12
            Button {
                label: Settings.dnd ? "She rests  ·  wake her" : "Do not disturb"
                lit: Settings.dnd
                testKey: "thread:dnd"
                onClicked: Settings.dnd = !Settings.dnd
            }
            Button {
                visible: Inbox.today.length > 0
                label: "Clear all"
                testKey: "thread:clear"
                onClicked: Inbox.clearAll()
            }
        }
    }

    Item {
        focus: !Test.on
        Keys.onEscapePressed: win.dismiss()
        Keys.onUpPressed: win.scroll(-60)
        Keys.onDownPressed: win.scroll(60)
    }

    SystemClock {
        id: wall
        precision: SystemClock.Minutes
    }
}
