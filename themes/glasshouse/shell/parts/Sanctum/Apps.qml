import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.kit

Item {
    id: apps

    readonly property var rows: Rite.results
    readonly property int count: apps.rows.length
    readonly property color gold: Theme.dark ? Theme.rare : "#e6c577"
    readonly property color dim: Theme.dark ? Theme.dim : "#bab9d4"
    readonly property color ink: Theme.dark ? Theme.ink : "#e8e7ee"
    readonly property string face: "Outfit"
    readonly property string figures: "Gilda Display"
    property int first: 0

    anchors.fill: parent

    function follow(): void {
        const n = apps.count;
        let t = apps.first;
        if (Rite.selected < t)
            t = Rite.selected;
        else if (Rite.selected >= t + 8)
            t = Rite.selected - 7;
        apps.first = Math.max(0, Math.min(t, Math.max(0, n - 8)));
    }
    Connections {
        target: Rite
        function onSelectedChanged(): void {
            apps.follow();
        }
        function onResultsChanged(): void {
            apps.follow();
        }
    }

    function glyphOf(r: var): string {
        const id = (r.key || "").toLowerCase();
        if (/kitty|alacritty|foot|wezterm|terminal|konsole|xterm/.test(id + " " + (r.icon || "").toLowerCase()))
            return "\u{f018d}";
        return "";
    }
    function jewelOf(key: string): int {
        let h = 0;
        for (let i = 0; i < key.length; i++)
            h = (h * 31 + key.charCodeAt(i)) % 9973;
        return h % 5;
    }
    function iconOf(r: var): string {
        if (!r.icon)
            return Quickshell.iconPath("application-x-executable", true);
        if (r.icon.startsWith("/"))
            return "file://" + r.icon;
        return Quickshell.iconPath(r.icon, true) || Quickshell.iconPath("application-x-executable", true);
    }

    readonly property var at: Theme.dark ? ({
            search: [157, 305, 375, 49],
            lens: 184,
            caret: 204.75,
            query: [209, 337.75, 17],
            count: [510.75, 337.75, 18],
            rows: [156.5, 376, 373.5, 54, 68.5],
            ring: 26.9,
            title: [67, -1.85],
            sub: [67.25, 15.25, 10, 2.0],
            ret: 354.25,
            bar: [539, 378, 5.75]
        }) : ({
            search: [130.5, 315, 372.5, 44],
            lens: 153.25,
            caret: 173,
            query: [176.25, 345, 17],
            count: [484.5, 343.5, 17],
            rows: [125.5, 374, 385.5, 59, 66.85],
            ring: 27.2,
            title: [67.75, -1.95],
            sub: [68.5, 14.6, 10, 2.2],
            ret: 366.1,
            bar: [522.5, 387.75, 5.5]
        })

    Nine {
        id: search
        x: apps.at.search[0] - 2.5
        y: apps.at.search[1] - 2.5
        width: apps.at.search[2] + 5
        height: apps.at.search[3] + 5
        name: "sanctum-search"
        border: 22
        power: 0.22
        ambient: 0.62
        light: Qt.point(0.2, 0.0)
    }
    Text {
        id: lens
        x: apps.at.lens - width / 2
        anchors.verticalCenter: search.verticalCenter
        text: "\u{f0349}"
        font.family: Theme.glyphs
        font.pixelSize: 18
        color: apps.gold
    }
    Text {
        id: query
        x: apps.at.query[0]
        y: apps.at.query[1] - baselineOffset
        width: apps.at.count[0] - 40 - x
        text: Rite.query
        elide: Text.ElideLeft
        font.family: apps.face
        font.pixelSize: 18
        color: apps.ink
    }
    Text {
        visible: Rite.query === ""
        x: apps.at.query[0]
        y: apps.at.query[1] - baselineOffset
        text: "Applications"
        font.family: apps.face
        font.pixelSize: apps.at.query[2]
        font.italic: true
        color: apps.dim
        opacity: 0.8
    }
    Rectangle {
        x: Rite.query === "" ? apps.at.caret : query.x + Math.min(query.width, query.implicitWidth) + 2
        width: 2.25
        height: 21
        anchors.verticalCenter: search.verticalCenter
        color: apps.gold
        visible: Rite.zone === "list"
    }
    Text {
        x: apps.at.count[0] - width
        y: apps.at.count[1] - baselineOffset
        text: apps.count
        font.family: apps.figures
        font.pixelSize: apps.at.count[2]
        font.features: { "lnum": 1, "tnum": 1 }
        color: Theme.dark ? apps.dim : "#d8d7f2"
    }

    MouseArea {
        x: apps.at.rows[0]
        y: apps.at.rows[1]
        width: apps.at.rows[2]
        height: 8 * apps.at.rows[4]
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            Rite.zone = "list";
            Rite.moveList(wheel.angleDelta.y > 0 ? -1 : 1);
        }
    }
    Repeater {
        model: 8
        Item {
            id: slot

            required property int index
            readonly property int at: apps.first + slot.index
            readonly property var r: slot.at < apps.count ? apps.rows[slot.at] : null
            readonly property bool sel: !!slot.r && Rite.zone === "list" && slot.at === Rite.selected
            readonly property string glyph: slot.r ? apps.glyphOf(slot.r) : ""

            visible: !!slot.r
            x: apps.at.rows[0]
            y: apps.at.rows[1] + slot.index * apps.at.rows[4]
            width: apps.at.rows[2]
            height: apps.at.rows[3]

            Pane {
                visible: slot.sel
                anchors.fill: parent
                anchors.margins: -2.5
                name: "sanctum-row"
                border: 10
                power: 0.08
                ambient: 0.97
                grain: 0.05
                light: Qt.point(0.15, 0.0)
            }
            Piece {
                id: ring
                name: slot.r ? "sanctum-ring-" + apps.jewelOf(slot.r.key) : "sanctum-ring"
                width: 46
                height: 46
                x: apps.at.ring - width / 2
                anchors.verticalCenter: parent.verticalCenter
                power: 0.5
                ambient: slot.sel ? 0.92 : 0.62
                glow: 0
                hasGlow: false
            }
            IconImage {
                visible: slot.glyph === "" && !!slot.r
                anchors.centerIn: ring
                implicitSize: 26
                source: slot.r && slot.glyph === "" ? apps.iconOf(slot.r) : ""
                asynchronous: true
            }
            Text {
                visible: slot.glyph !== ""
                anchors.centerIn: ring
                text: slot.glyph
                font.family: Theme.glyphs
                font.pixelSize: 19
                color: apps.gold
            }
            Text {
                x: apps.at.title[0]
                y: slot.height / 2 + apps.at.title[1] - baselineOffset
                width: slot.width - x - (slot.sel ? 40 : 14)
                text: slot.r ? slot.r.title : ""
                elide: Text.ElideRight
                maximumLineCount: 1
                font.family: apps.face
                font.pixelSize: 18
                font.weight: Font.Medium
                color: slot.sel ? Theme.inkOnLight : apps.ink
            }
            Text {
                visible: text !== ""
                x: apps.at.sub[0]
                y: slot.height / 2 + apps.at.sub[1] - baselineOffset
                width: slot.width - x - (slot.sel ? 40 : 14)
                text: slot.r ? slot.r.sub.toUpperCase() : ""
                elide: Text.ElideRight
                font.family: Theme.caps
                font.pixelSize: apps.at.sub[2]
                font.letterSpacing: apps.at.sub[3]
                font.weight: Font.DemiBold
                color: slot.sel ? "#6b5a86" : apps.dim
            }
            Text {
                visible: slot.sel
                x: apps.at.ret - width / 2
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{f0311}"
                font.family: Theme.glyphs
                font.pixelSize: 17
                color: "#7d5fae"
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    Rite.zone = "list";
                    Rite.selected = slot.at;
                }
                onClicked: {
                    Rite.zone = "list";
                    Rite.selected = slot.at;
                    Rite.activate();
                }
            }
        }
    }

    Item {
        visible: apps.count > 8
        x: apps.at.bar[0]
        y: apps.at.bar[1]
        width: apps.at.bar[2]
        height: 8 * apps.at.rows[4] - 2
        Rectangle {
            width: parent.width
            height: Math.max(22, parent.height * 8 / Math.max(8, apps.count))
            radius: width / 2
            y: (parent.height - height) * (apps.first / Math.max(1, apps.count - 8))
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.dark ? "#6b4f22" : "#7a5424" }
                GradientStop { position: 0.4; color: Theme.dark ? "#ffe8b0" : "#fff4cf" }
                GradientStop { position: 1; color: Theme.dark ? "#a37a3c" : "#c99a4e" }
            }
            border.width: 1
            border.color: Theme.dark ? "#1b1e31" : "#3b2410"
        }
    }

    Text {
        visible: apps.count === 0
        x: search.x
        y: apps.at.rows[1] + 24
        width: search.width
        horizontalAlignment: Text.AlignHCenter
        text: "Nothing matches “" + Rite.query + "”"
        textFormat: Text.PlainText
        font.family: apps.face
        font.pixelSize: 15
        font.italic: true
        color: apps.dim
    }
}
