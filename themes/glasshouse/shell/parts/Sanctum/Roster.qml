import QtQuick
import qs.core
import qs.kit

Item {
    id: roster

    required property var owner

    Text {
        id: agentsLabel
        x: roster.owner.at.label[0]
        y: roster.owner.at.label[1] - baselineOffset
        text: "CLAUDE AGENTS"
        font.family: Theme.caps
        font.pixelSize: roster.owner.at.label[2]
        font.letterSpacing: roster.owner.at.label[3]
        font.weight: Font.DemiBold
        color: roster.owner.gold
    }
    Text {
        visible: Rite.agents.length > 3
        x: agentsLabel.x + agentsLabel.implicitWidth + 10
        y: roster.owner.at.label[1] - baselineOffset
        text: "+" + (Rite.agents.length - 3)
        font.family: Theme.caps
        font.pixelSize: roster.owner.at.label[2]
        font.letterSpacing: roster.owner.at.label[3]
        font.weight: Font.DemiBold
        color: roster.owner.dim
    }
    Text {
        visible: Rite.agents.length === 0
        x: roster.owner.at.cards[0]
        y: roster.owner.at.cards[1] + roster.owner.at.cards[3] / 2 - height / 2
        text: "No session running"
        font.family: roster.owner.face
        font.pixelSize: 14
        font.italic: true
        color: roster.owner.dim
    }
    Repeater {
        model: Rite.agents.slice(0, 3)
        Item {
            id: ag
            required property var modelData
            required property int index
            readonly property bool sel: roster.owner.isSel("agents", ag.index)
            readonly property color tone: roster.owner.tone(ag.modelData.state)
            x: roster.owner.at.cards[0]
            y: roster.owner.at.cards[1] + ag.index * roster.owner.at.cards[4]
            width: roster.owner.at.cards[2]
            height: roster.owner.at.cards[3]
            Pane {
                anchors.fill: parent
                anchors.margins: -2.5
                name: ag.sel ? "sanctum-row" : "sanctum-card"
                border: 10
                power: ag.sel ? 0.08 : 0.24
                ambient: ag.sel ? 0.97 : 0.6
                grain: ag.sel ? 0.05 : 0.12
            }
            Glow {
                x: pill.x + pill.width / 2 - 20
                y: pill.y + pill.height / 2 - 20
                width: 40
                height: 40
                color: ag.tone
                core: 0.16
                intensity: ag.sel ? 0.3 : 0.75
            }
            Rectangle {
                id: pill
                x: roster.owner.at.pill[0]
                y: roster.owner.at.pill[1]
                width: roster.owner.at.pill[2]
                height: roster.owner.at.pill[3]
                radius: width / 2
                color: ag.tone
                border.width: 1
                border.color: Qt.lighter(ag.tone, 1.5)
            }
            Text {
                x: roster.owner.at.name[0]
                y: roster.owner.at.name[1] - baselineOffset
                width: 250
                elide: Text.ElideRight
                text: ag.modelData.label
                font.family: roster.owner.face
                font.pixelSize: roster.owner.at.name[2]
                font.weight: Font.Medium
                color: ag.sel ? Theme.inkOnLight : roster.owner.ink
            }
            Text {
                x: roster.owner.at.status[0]
                y: roster.owner.at.status[1] - baselineOffset
                width: 250
                elide: Text.ElideRight
                text: ({ working: "WORKING", needs: "NEEDS YOU", done: "DONE", idle: "IDLE" })[ag.modelData.state] + (ag.modelData.detail && ag.modelData.state === "needs" ? "  ·  " + ag.modelData.detail : "")
                font.family: Theme.caps
                font.pixelSize: roster.owner.at.status[2]
                font.letterSpacing: roster.owner.at.status[3]
                font.weight: Font.DemiBold
                color: ag.sel ? "#6b5a86" : ag.tone
            }
            Text {
                x: parent.width - roster.owner.at.time[0] - width
                y: roster.owner.at.time[1] - baselineOffset
                text: ag.modelData.state === "done" ? roster.owner.ago(Agents.now - ag.modelData.updated) : roster.owner.elapsed(Agents.now - ag.modelData.since)
                font.family: roster.owner.face
                font.pixelSize: roster.owner.at.time[2]
                color: ag.sel ? "#6b5a86" : Theme.dark ? "#7f8aa5" : roster.owner.dim
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: roster.owner.pick("agents", ag.index)
                onClicked: {
                    roster.owner.pick("agents", ag.index);
                    Rite.activate();
                }
            }
        }
    }
}
