import QtQuick
import qs.core
import qs.parts.Lancet

Item {
    id: house

    required property var owner

    x: house.owner.at.cards[0]
    y: house.owner.at.house[0] + (house.owner.at.house[1] - house.owner.at.house[0] - height) / 2
    width: house.owner.at.cards[2]
    height: 46

    Text {
        id: tag
        y: 15 - baselineOffset
        text: house.owner.caption ? house.owner.caption.label : ""
        font.family: Theme.caps
        font.pixelSize: 10
        font.letterSpacing: Theme.capsTracking
        font.weight: Font.DemiBold
        color: house.owner.gold
    }
    Text {
        x: tag.text === "" ? 0 : tag.implicitWidth + 10
        y: 15 - baselineOffset
        width: parent.width - x
        elide: Text.ElideRight
        text: house.owner.caption ? house.owner.caption.value : ""
        font.family: house.owner.face
        font.pixelSize: 14
        font.italic: !!house.owner.caption.rest
        color: house.owner.caption.rest ? house.owner.dim : house.owner.ink
    }
    Gauge {
        visible: Gauges.sinkReady
        y: 22
        scale: house.width / width
        transformOrigin: Item.TopLeft
        sel: Rite.zone === "volume"
    }
}
