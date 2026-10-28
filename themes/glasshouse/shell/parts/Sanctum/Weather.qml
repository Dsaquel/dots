import QtQuick
import qs.core

Item {
    id: weather

    required property var owner

    visible: !!weather.owner.about
    Text {
        x: weather.owner.at.sky[1] - width / 2
        y: weather.owner.at.sky[0] - height / 2
        text: weather.owner.about ? (weather.owner.w.day ? weather.owner.about.day : weather.owner.about.night) : ""
        font.family: Theme.glyphs
        font.pixelSize: weather.owner.at.sky[2]
        color: weather.owner.gold
    }
    TextMetrics {
        id: tempInk
        font: temp.font
        text: temp.text
    }
    Text {
        id: temp
        x: weather.owner.at.temp[0] - tempInk.tightBoundingRect.x
        y: weather.owner.at.temp[1] - baselineOffset
        text: weather.owner.w ? Math.round(weather.owner.w.temp) + "°" : ""
        font.family: weather.owner.figures
        font.pixelSize: weather.owner.at.temp[2]
        font.features: { "lnum": 1 }
        color: weather.owner.ink
    }
    Text {
        id: word
        x: Math.max(weather.owner.at.word[0], temp.x + temp.implicitWidth + 4)
        y: weather.owner.at.word[1] - baselineOffset
        text: weather.owner.about ? weather.owner.about.word : ""
        font.family: weather.owner.face
        font.pixelSize: weather.owner.at.word[2]
        color: weather.owner.dim
    }
    Text {
        x: Math.max(weather.owner.at.range[0], word.x + word.implicitWidth + 10)
        y: weather.owner.at.range[1] - baselineOffset
        text: weather.owner.w ? Math.round(weather.owner.w.lo) + "° / " + Math.round(weather.owner.w.hi) + "°" : ""
        font.family: weather.owner.face
        font.pixelSize: weather.owner.at.range[2]
        color: weather.owner.dim
    }
}
