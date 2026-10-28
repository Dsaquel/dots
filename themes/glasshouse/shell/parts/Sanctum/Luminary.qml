import QtQuick
import qs.core

Item {
    id: luminary

    required property var owner

    visible: Theme.dark || !!luminary.owner.sun
    ShaderEffect {
        visible: Theme.dark
        x: luminary.owner.at.moon[1] - width / 2
        y: luminary.owner.at.moon[0] - height / 2
        width: luminary.owner.at.moon[2]
        height: luminary.owner.at.moon[2]
        property real phase: luminary.owner.moon
        property color lit: "#dfe6f6"
        property color dark: "#1b2350"
        fragmentShader: Qt.resolvedUrl("../../shaders/moon.frag.qsb")
    }
    Text {
        visible: !Theme.dark
        x: luminary.owner.at.moon[1] - width / 2
        y: luminary.owner.at.moon[0] - height / 2
        text: luminary.owner.sun && luminary.owner.sun.kind === "sunrise" ? "\u{f059c}" : "\u{f059b}"
        font.family: Theme.glyphs
        font.pixelSize: luminary.owner.at.moon[2]
        color: luminary.owner.gold
    }
    Text {
        id: phase
        x: luminary.owner.at.phase[0]
        y: luminary.owner.at.phase[1] - baselineOffset
        text: Theme.dark ? Rite.sky.moonName(luminary.owner.moon) : (luminary.owner.sun ? (luminary.owner.sun.kind === "sunrise" ? "Sunrise " : "Sunset ") + luminary.owner.en.toString(luminary.owner.sun.at, "HH:mm") : "")
        font.family: luminary.owner.face
        font.pixelSize: luminary.owner.at.phase[2]
        color: luminary.owner.dim
    }
    Text {
        visible: Theme.dark
        x: phase.x + phase.implicitWidth + 8.5
        y: luminary.owner.at.phase[1] - baselineOffset
        text: Math.round(Rite.sky.moonLit(luminary.owner.moon) * 100) + " %"
        font.family: luminary.owner.face
        font.pixelSize: luminary.owner.at.phase[2]
        color: luminary.owner.dim
    }
}
