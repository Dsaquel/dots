import QtQuick
import Quickshell
import qs.core
import qs.kit

Item {
    id: slot

    required property var modelData
    required property int index
    required property var host
    readonly property var n: slot.host.lay.niches[index]
    readonly property string key: modelData.key
    readonly property var meta: Anchor.bottle(modelData.sprite)
    readonly property real k: slot.meta ? Math.min(68 / slot.meta.w, 100 / slot.meta.h) : 1
    x: n.x
    y: n.y
    width: n.w
    height: n.h
    Potion {
        id: pot
        sprite: slot.modelData.sprite
        width: slot.meta ? Math.round(slot.meta.w * slot.k) : 0
        height: slot.meta ? Math.round(slot.meta.h * slot.k) : 0
        x: Math.round((slot.width - width) / 2)
        y: Math.round(slot.height - height - 3)
        level: slot.key === "volume" ? slot.host.volumeLevel : slot.key === "mic" ? slot.host.micLevel : slot.key === "cpu" ? slot.host.cpuLevel : slot.host.memoryLevel
        wave: slot.key === "cpu" ? 0 : slot.host.wave(slot.key)
        phase: slot.key === "cpu" ? 0 : (slot.host.t - slot.host.sloshAt[slot.key]) * 18.3
        bubbles: slot.key === "cpu" ? slot.host.bubbles() : 0
        time: slot.key === "cpu" ? (slot.host.t - slot.host.burstAt) * 1.78 : 0
        grey: (slot.key === "volume" && Gauges.muted) || (slot.key === "mic" && Gauges.micMuted) ? 1 : 0
        warm: slot.key === "cpu" ? Math.max(0, Math.min(1, (slot.host.cpuLevel - 0.8) / 0.15)) : 0
        Behavior on grey { NumberAnimation { duration: 500; easing.type: Easing.InOutCubic } }
    }
    Glow {
        visible: slot.key === "mic" && Gauges.micMuted && !!slot.meta
        width: 30
        height: 30
        x: pot.x + pot.width * (slot.meta ? slot.meta.stopper[0] : 0.5) - width / 2
        y: pot.y + pot.height * (slot.meta ? slot.meta.stopper[1] : 0.1) - height / 2
        color: Theme.alert
        core: 0.18
        intensity: 1.15
    }
    MouseArea {
        anchors.fill: parent
        enabled: slot.host.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        property real acc: 0
        onEntered: slot.host.hoverKey = slot.key
        onExited: if (slot.host.hoverKey === slot.key) slot.host.hoverKey = ""
        onClicked: {
            if (slot.key === "volume")
                Gauges.toggleMute();
            else if (slot.key === "mic")
                Gauges.toggleMic();
            else
                Quickshell.execDetached(["kitty", "--class", "glasshouse-btop", "btop"]);
        }
        onWheel: wheel => {
            if (slot.key !== "volume" && slot.key !== "mic")
                return;
            acc += wheel.angleDelta.y;
            if (Math.abs(acc) < 120)
                return;
            const step = acc > 0 ? 0.05 : -0.05;
            acc = 0;
            if (slot.key === "volume")
                Gauges.setVolume(Math.round((Gauges.volume + step) * 20) / 20);
            else
                Gauges.setMic(Math.round((Gauges.micVolume + step) * 20) / 20);
        }
    }
}
