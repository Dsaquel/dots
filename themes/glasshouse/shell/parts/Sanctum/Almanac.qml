import QtQuick
import Quickshell
import qs.core

Item {
    id: almanac

    required property var owner
    required property SystemClock watch

    TextMetrics {
        id: dayInk
        font: day.font
        text: day.text
    }
    Text {
        id: day
        x: almanac.owner.at.numeral[0] - dayInk.tightBoundingRect.x
        y: almanac.owner.at.numeral[1] - baselineOffset
        text: almanac.watch.date.getDate()
        font.family: almanac.owner.figures
        font.pixelSize: almanac.owner.at.numeral[2]
        font.features: { "lnum": 1 }
        color: Theme.dark ? almanac.owner.gold : "#f7ca82"
        renderType: Text.CurveRendering
    }
    Text {
        x: almanac.owner.at.column
        y: almanac.owner.at.month[0] - baselineOffset
        text: almanac.owner.en.toString(almanac.watch.date, "MMMM").toUpperCase()
        font.family: Theme.caps
        font.pixelSize: almanac.owner.at.month[1]
        font.letterSpacing: almanac.owner.at.month[2]
        font.weight: Font.DemiBold
        color: almanac.owner.ink
    }
    Text {
        x: almanac.owner.at.day[0]
        y: almanac.owner.at.day[1] - baselineOffset
        text: almanac.owner.en.toString(almanac.watch.date, "dddd") + "  ·  " + almanac.owner.en.toString(almanac.watch.date, "HH:mm")
        font.family: almanac.owner.face
        font.pixelSize: almanac.owner.at.day[2]
        color: almanac.owner.inkSoft
    }
}
