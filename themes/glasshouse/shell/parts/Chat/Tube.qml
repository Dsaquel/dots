import QtQuick
import qs.core

Item {
    id: t

    property Clock clock
    property real value: 0
    property real from: t.value
    property real to: t.value
    property real at: -99
    readonly property real shown: t.clock ? t.clock.glide(t.from, t.to, t.at, 0.45) : t.value

    onValueChanged: {
        const cur = t.shown;
        t.from = cur;
        t.to = t.value;
        t.at = t.clock ? t.clock.kick(0.45, false) : 0;
    }

    height: 10

    Pane {
        x: -4
        y: -3
        width: t.width + 8
        height: t.height + 10
        pane: Qt.vector4d(4, 3, t.width, t.height)
        radius: 5
        rim: 1.7
        shadow: 0.25
        bodyTop: Theme.dark ? "#0c1028" : "#15176a"
        bodyBottom: Theme.dark ? "#090c1f" : "#10125a"
        lightPower: 0
        grain: 0.06
    }
    Rectangle {
        id: liquid
        x: 2.5
        y: 2.5
        height: t.height - 5
        width: Math.max(liquid.height, (t.width - 5) * t.shown)
        visible: t.shown > 0.002
        radius: height / 2
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.dark ? "#d8e2f6" : "#fff0b8" }
            GradientStop { position: 0.45; color: Theme.dark ? "#8aa2dc" : "#ffc04a" }
            GradientStop { position: 1; color: Theme.dark ? "#3e58a8" : "#e07a1f" }
        }
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: parent.height + 1
            radius: 1
            color: "#ffffff"
            opacity: 0.85
        }
    }
}
