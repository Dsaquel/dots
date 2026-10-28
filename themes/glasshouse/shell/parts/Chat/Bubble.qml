import QtQuick
import Quickshell
import qs.core
import qs.kit

Item {
    id: b

    required property int index
    required property string key
    required property string kind
    required property string app
    required property string icon
    required property string image
    required property string summary
    required property string body
    required property int urgency
    required property string actions
    required property int value
    required property int timeout
    required property string sid
    required property string state
    required property real time
    required property real born
    required property real stamp
    required property real touchedAt
    required property bool leaving

    property Clock clock
    property real paneX: 0
    property real paneW: 400
    property point tip: Qt.point(0, 0)
    property bool mirror: false
    property bool newest: false
    property real floor: 0
    property int rank: 0

    readonly property real pad: 22
    readonly property real headerH: 39
    readonly property real padX: 21
    readonly property bool critical: b.urgency >= 2
    readonly property bool agent: ["needs", "done", "working", "idle"].indexOf(b.kind) >= 0
    readonly property bool own: !b.agent && (b.kind === "info" || b.app === "Glasshouse")
    readonly property bool quiet: b.kind === "low"
    readonly property var acts: JSON.parse(b.actions || "[]").filter(a => a.id !== "default")
    readonly property bool hovered: hover.hovered || (Test.on && Test.hover.startsWith("bubble:" + b.key))
    readonly property color gold: Theme.dark ? Theme.rare : Theme.sun
    readonly property var stateWord: ({ needs: "NEEDS YOU", done: "DONE", working: "WORKING", idle: "IDLE" })
    readonly property color stateColor: b.kind === "needs" ? (Theme.dark ? "#e8789a" : "#ff9cc6") : b.kind === "done" ? (Theme.dark ? "#86d6ac" : "#a4f2cc") : b.kind === "working" ? (Theme.dark ? "#86c8ee" : "#9ce8ff") : Theme.dim
    readonly property string bodyText: b.styled(b.body)
    readonly property real textW: b.paneW - 2 * b.padX - (b.image !== "" ? 72 : 0)
    readonly property real contentH: Math.max(summaryText.height + (b.body !== "" ? 3 + bodyLabel.height : 0) + (b.value >= 0 ? 14 : 0), b.image !== "" ? 60 : 0)
    readonly property real paneH: Math.round(b.headerH + 9 + b.contentH + (b.acts.length ? 12 + 24 : 0) + 19)

    readonly property real t: b.clock ? b.clock.t : 0
    property real riseAt: -99
    property bool going: false
    property bool away: false
    property real fallAt: -99
    property real fallFrom: 1
    property real sweepAt: -99
    property real gildAt: -99
    property real yFrom: 0
    property real yTo: 0
    property real yAt: -99
    property real nearFrom: 1
    property real nearTo: 1
    property real nearAt: -99
    property real rankFrom: 0
    property real rankTo: 0
    property real rankAt: -99
    property bool placed: false

    function riseNow(): real {
        return b.clock ? b.clock.out((b.t - b.riseAt) / 0.5) : 1;
    }
    readonly property real appear: !b.clock ? 1 : b.going ? b.fallFrom * (1 - b.clock.inc((b.t - b.fallAt) / 0.34)) : b.riseNow()
    readonly property bool shown: !b.going && b.t >= b.riseAt + 0.5
    readonly property real sweep: {
        const d = (b.t - b.sweepAt) / 0.82;
        return d >= 0 && d < 1 && b.clock ? b.clock.inout(d) : -1;
    }
    readonly property real flash: {
        if (!b.critical || !b.clock)
            return 0;
        const d = b.t - b.gildAt;
        if (d >= 0 && d < 0.14)
            return 0.85 * b.clock.out(d / 0.14);
        if (d >= 0.14 && d < 1.24)
            return 0.85 - 0.63 * b.clock.inout((d - 0.14) / 1.1);
        return 0.22;
    }
    readonly property real near: b.clock ? b.clock.glide(b.nearFrom, b.nearTo, b.nearAt, 0.46) : (b.newest ? 1 : 0)
    readonly property real rankV: b.clock ? b.clock.glide(b.rankFrom, b.rankTo, b.rankAt, 0.46) : b.rank
    readonly property real targetY: b.floor - b.paneH - b.pad
    readonly property point origin: Qt.point(b.tip.x, b.tip.y - b.y)

    width: parent ? parent.width : 600
    height: b.paneH + 2 * b.pad
    y: b.clock ? b.clock.glide(b.yFrom, b.yTo, b.yAt, 0.46) : b.targetY

    onTargetYChanged: {
        if (!b.placed || !b.clock) {
            b.yFrom = b.yTo = b.targetY;
            return;
        }
        const cur = b.y;
        b.yFrom = cur;
        b.yTo = b.targetY;
        b.yAt = b.clock.kick(0.46, true);
    }
    onNewestChanged: {
        if (!b.clock)
            return;
        const cur = b.near;
        b.nearFrom = cur;
        b.nearTo = b.newest ? 1 : 0;
        b.nearAt = b.clock.kick(0.46, false);
    }
    onRankChanged: {
        if (!b.clock)
            return;
        const cur = b.rankV;
        b.rankFrom = cur;
        b.rankTo = b.rank;
        b.rankAt = b.clock.kick(0.46, false);
    }
    onLeavingChanged: if (b.leaving && !b.going) {
        b.fallFrom = b.riseNow();
        b.away = b.rank > 0;
        b.fallAt = b.clock ? b.clock.kick(0.36, true) : 0;
        b.going = true;
        drop.start();
    }
    onStampChanged: if (b.shown && b.clock) {
        b.sweepAt = b.clock.kick(0.82, false);
        if (b.critical)
            b.gildAt = b.clock.kick(1.24, false);
    }
    onTouchedAtChanged: if (timer.running)
        timer.restart()

    Component.onCompleted: {
        b.yFrom = b.yTo = b.targetY;
        b.nearFrom = b.nearTo = b.newest ? 1 : 0;
        b.rankFrom = b.rankTo = b.rank;
        b.placed = true;
        if (b.leaving) {
            b.going = true;
            b.fallFrom = 0;
            Qt.callLater(() => Inbox.drop(b.key));
            return;
        }
        if (Date.now() - b.born > 1500 || !b.clock)
            return;
        b.riseAt = b.clock.kick(0.5, true);
        b.sweepAt = b.clock.kick(0.82, false);
        if (b.critical)
            b.gildAt = b.clock.kick(1.24, false);
    }

    Timer {
        id: drop
        interval: 360
        onTriggered: Inbox.drop(b.key)
    }
    Timer {
        id: timer
        interval: Math.max(1000, b.timeout)
        running: b.timeout > 0 && b.shown && !b.hovered && !Inbox.frozen
        onTriggered: Inbox.expire(b.key)
    }

    opacity: Math.min(1, b.appear * 1.6)
    transform: [
        Scale {
            origin.x: b.away ? b.paneX + b.paneW / 2 : b.origin.x
            origin.y: b.away ? b.pad + b.paneH / 2 : b.origin.y
            xScale: b.away ? 0.97 + 0.03 * b.appear : 0.6 + 0.4 * b.appear
            yScale: b.away ? 0.97 + 0.03 * b.appear : 0.6 + 0.4 * b.appear
        },
        Translate {
            x: b.away ? 0 : (b.mirror ? 1 : -1) * (1 - b.appear) * (b.going ? 16 : 0)
            y: b.away ? -(1 - b.appear) * 16 : (1 - b.appear) * (b.going ? 0 : 14)
        }
    ]

    Pane {
        id: glass
        anchors.fill: parent
        pane: Qt.vector4d(b.paneX, b.pad, b.paneW, b.paneH)
        radius: 15
        band: 6
        jewel: 13
        cornerGlow: (b.quiet ? 0.1 : 0.26 + 0.16 * b.near) + 0.4 * b.flash + 0.35 * glass.lift
        header: b.headerH
        tailOn: b.near
        tailA: Qt.vector2d(b.mirror ? b.paneX + b.paneW - 14 : b.paneX + 14, b.pad + b.paneH - 27)
        tailB: Qt.vector2d(b.mirror ? b.paneX + b.paneW + 12 : b.paneX - 12, b.pad + b.paneH - 22)
        tailC: Qt.vector2d(b.origin.x, b.origin.y)
        tailW: Qt.vector2d(12, 1.6)
        lightPos: Qt.vector2d(b.origin.x, b.origin.y)
        lightRadius: 210
        lightPower: (b.quiet ? 0.3 : 0.3 + 0.3 * b.near) + 0.12 * b.flash
        shade: 1 - 0.08 * Math.min(2, b.rankV)
        goldMix: b.critical ? 1 : 0
        jewelA: b.critical ? (Theme.dark ? "#7a2846" : "#8a2238") : (Theme.dark ? "#3f58a6" : "#6e3866")
        flash: b.flash
        spill: (b.quiet ? 0.1 : 0.3 + 0.2 * b.near) + 0.35 * glass.lift
        haloSize: 16
        sweep: b.sweep
        lift: b.hovered ? 1 : 0
        Behavior on lift { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    Medal {
        x: b.paneX + 17
        y: b.pad + 13
        icon: b.icon
        own: b.own
        letter: (b.app || "?").charAt(0).toUpperCase()
        vial: b.agent ? Assets.url("potions/lancet/" + (Theme.dark ? "night-star-vial" : "day-gold-ampoule") + "-full.png") : ""
        vialLight: b.kind === "needs" ? b.gold : b.kind === "working" ? b.stateColor : "#e8f0ff"
    }
    Row {
        x: b.paneX + 49
        y: b.pad + 29 - appLabel.baselineOffset
        spacing: 0
        Text {
            id: appLabel
            text: (b.app || "Notification").toUpperCase()
            width: Math.min(implicitWidth, b.paneW - 49 - 80 - (b.agent ? stateLabel.implicitWidth : 0))
            elide: Text.ElideRight
            font.family: Theme.caps
            font.pixelSize: 10
            font.letterSpacing: Theme.capsTracking
            font.weight: Font.DemiBold
            color: b.quiet ? Theme.dim : b.gold
            renderType: Text.NativeRendering
        }
        Text {
            id: stateLabel
            visible: b.agent
            text: "  ·  " + (b.stateWord[b.kind] || "")
            font: appLabel.font
            color: b.stateColor
            renderType: Text.NativeRendering
        }
    }
    Text {
        visible: b.critical || b.timeout === 0
        anchors.right: parent.right
        anchors.rightMargin: parent.width - b.paneX - b.paneW + 20
        y: b.pad + 29 - baselineOffset
        text: Qt.formatTime(new Date(b.time), "hh:mm")
        font.family: Theme.numerals
        font.pixelSize: 13
        font.features: { "lnum": 1, "tnum": 1 }
        font.variableAxes: Theme.dark ? ({}) : ({ "wght": 560, "opsz": 13 })
        color: b.critical ? b.gold : Theme.dim
        renderType: Text.NativeRendering
    }

    Text {
        id: summaryText
        x: b.paneX + b.padX
        y: b.pad + b.headerH + 9
        width: b.textW
        text: b.summary
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
        font.family: Theme.ui
        font.pixelSize: 15
        font.variableAxes: { "wght": 620 }
        color: Theme.ink
        lineHeight: 1.08
        renderType: Text.NativeRendering
    }
    Text {
        id: bodyLabel
        visible: b.body !== ""
        x: summaryText.x
        y: summaryText.y + summaryText.height + 3
        width: b.textW
        text: b.bodyText
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        maximumLineCount: 3
        elide: Text.ElideRight
        font.family: Theme.ui
        font.pixelSize: 13
        font.variableAxes: { "wght": 420 }
        color: Theme.inkSoft
        linkColor: b.gold
        lineHeight: 1.12
        renderType: Text.NativeRendering
    }
    Tube {
        visible: b.value >= 0
        clock: b.clock
        x: summaryText.x
        y: (b.body !== "" ? bodyLabel.y + bodyLabel.height : summaryText.y + summaryText.height) + 6
        width: b.textW
        value: Math.max(0, Math.min(100, b.value)) / 100
    }
    Thumb {
        visible: b.image !== ""
        x: b.paneX + b.paneW - b.padX - width + 2
        y: b.pad + b.headerH + 10
        source: b.image
    }

    Row {
        visible: b.acts.length > 0
        x: b.paneX + b.padX
        y: b.pad + b.paneH - 19 - 24
        spacing: 8
        Repeater {
            model: b.acts
            Button {
                required property var modelData
                required property int index
                label: modelData.label
                primary: index === 0
                testKey: "bubble:" + b.key + ":" + modelData.id
                onClicked: Inbox.invoke(b.key, modelData.id)
            }
        }
    }

    Item {
        z: -1
        x: b.paneX
        y: b.pad
        width: b.paneW
        height: b.paneH
        HoverHandler {
            id: hover
        }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton)
                    Inbox.click(b.key);
                else
                    Inbox.dismiss(b.key);
            }
        }
    }

    function styled(t: string): string {
        return (t || "").replace(/<img[^>]*>/gi, "").replace(/\r?\n/g, "<br>");
    }
}
