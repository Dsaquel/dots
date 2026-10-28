import QtQuick
import qs.core

Item {
    id: n

    required property var entry
    property bool first: false
    property bool fresh: false
    property point faceAt: Qt.point(-30, 18)
    property real sweep: -1
    readonly property real pad: 10
    readonly property real w: width - 2 * n.pad
    readonly property bool hasImage: (n.entry.image || "") !== ""
    readonly property var acts: n.entry.live ? (n.entry.actions || []).filter(a => a.id !== "default") : []
    readonly property bool hovered: hover.hovered || (Test.on && Test.hover.startsWith("thread:" + n.entry.key))
    readonly property color gold: Theme.dark ? Theme.rare : Theme.sun
    readonly property real textW: n.w - 28 - (n.hasImage ? 56 : 0)
    readonly property real paneH: Math.round(12 + Math.max(sum.height + (n.entry.body ? 2 + body.height : 0), n.hasImage ? 44 : 0) + (n.acts.length ? 10 + 22 : 0) + 12)

    height: n.paneH + 2 * n.pad

    Pane {
        anchors.fill: parent
        pane: Qt.vector4d(n.pad, n.pad, n.w, n.paneH)
        radius: 11
        rim: 2.6
        band: 0
        bodyTop: n.entry.urgency >= 2 ? (Theme.dark ? "#2a1d44" : "#4a2a8e") : (Theme.dark ? "#232a5e" : "#3a40b8")
        bodyBottom: n.entry.urgency >= 2 ? (Theme.dark ? "#1c1433" : "#36206e") : (Theme.dark ? "#181d46" : "#2b2f9c")
        goldMix: n.entry.urgency >= 2 ? 1 : 0
        tailOn: n.first ? 1 : 0
        tailA: Qt.vector2d(n.pad + 12, n.pad + 16)
        tailB: Qt.vector2d(n.pad - 6, n.pad + 10)
        tailC: Qt.vector2d(n.faceAt.x, n.faceAt.y)
        tailW: Qt.vector2d(8, 1.2)
        lightPos: Qt.vector2d(n.faceAt.x, n.faceAt.y)
        lightRadius: 200
        lightPower: 0.3
        shadow: 0.35
        sweep: n.sweep
        lift: n.hovered ? 1 : 0
        spill: 0.4 * lift
        haloSize: 10
        Behavior on lift { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }
    Text {
        id: sum
        x: n.pad + 14
        y: n.pad + 10
        width: n.textW - when.implicitWidth - 18
        text: n.entry.summary || n.entry.app
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
        font.family: Theme.ui
        font.pixelSize: 13
        font.variableAxes: { "wght": 620 }
        color: Theme.ink
        renderType: Text.NativeRendering
    }
    Text {
        id: body
        visible: !!n.entry.body
        x: sum.x
        y: sum.y + sum.height + 2
        width: n.textW
        text: (n.entry.body || "").replace(/<img[^>]*>/gi, "").replace(/\r?\n/g, "<br>")
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        maximumLineCount: 4
        elide: Text.ElideRight
        font.family: Theme.ui
        font.pixelSize: 12
        font.variableAxes: { "wght": 420 }
        color: Theme.inkSoft
        linkColor: n.gold
        lineHeight: 1.1
        renderType: Text.NativeRendering
    }
    Text {
        id: when
        anchors.right: parent.right
        anchors.rightMargin: n.pad + 12
        y: n.pad + 10 + sum.baselineOffset - baselineOffset
        text: Qt.formatTime(new Date(n.entry.time), "hh:mm")
        font.family: Theme.numerals
        font.pixelSize: 12
        font.features: { "lnum": 1, "tnum": 1 }
        font.variableAxes: Theme.dark ? ({}) : ({ "wght": 560, "opsz": 12 })
        color: n.entry.urgency >= 2 ? n.gold : Theme.dim
        renderType: Text.NativeRendering
    }
    Rectangle {
        visible: n.fresh
        width: 5
        height: 5
        radius: 2.5
        anchors.right: when.left
        anchors.rightMargin: 6
        anchors.verticalCenter: when.verticalCenter
        color: n.gold
    }
    Thumb {
        visible: n.hasImage
        width: 44
        height: 44
        x: n.pad + n.w - 14 - width
        y: n.pad + 28
        source: n.hasImage ? n.entry.image : ""
    }
    Row {
        visible: n.acts.length > 0
        x: n.pad + 14
        y: n.pad + n.paneH - 12 - 22
        spacing: 6
        Repeater {
            model: n.acts
            Button {
                required property var modelData
                required property int index
                height: 22
                label: modelData.label
                primary: index === 0
                testKey: "thread:" + n.entry.key + ":" + modelData.id
                onClicked: Inbox.invoke(n.entry.key, modelData.id)
            }
        }
    }
    Item {
        z: -1
        x: n.pad
        y: n.pad
        width: n.w
        height: n.paneH
        HoverHandler {
            id: hover
        }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    Inbox.forget(n.entry.key);
                else if (n.entry.live && (n.entry.actions || []).some(a => a.id === "default" || a.id === "open"))
                    Inbox.invoke(n.entry.key, (n.entry.actions || []).some(a => a.id === "default") ? "default" : "open");
            }
        }
    }
}
