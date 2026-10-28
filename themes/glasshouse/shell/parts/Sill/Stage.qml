import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

Scope {
    id: stage

    required property ShellScreen modelData
    required property var her
    readonly property string name: stage.modelData.name
    readonly property var mon: Hypr.monitors[stage.name] || null
    readonly property var box: stage.her.perchBox && stage.her.perchBox.screen === stage.name ? stage.her.perchBox : null

    component Hit: Region {
        required property int slot
        property var hits: []
        readonly property var r: hits[slot] || null
        x: r ? Math.round(r.x) : 0
        y: r ? Math.round(r.y) : 0
        width: r ? Math.round(r.width) : 0
        height: r ? Math.round(r.height) : 0
    }

    LazyLoader {
        active: stage.her.perchOn && !!stage.box && !!stage.mon

        PanelWindow {
            screen: stage.modelData
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "glasshouse-sill"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                left: true
            }
            margins {
                top: stage.box ? stage.box.y : 0
                left: stage.box ? stage.box.x : 0
            }
            implicitWidth: stage.box ? stage.box.w : 1
            implicitHeight: stage.box ? stage.box.h : 1
            color: "transparent"
            mask: Region {
                Hit { slot: 0; hits: perched.hits }
                Hit { slot: 1; hits: perched.hits }
                Hit { slot: 2; hits: perched.hits }
                Hit { slot: 3; hits: perched.hits }
                Hit { slot: 4; hits: perched.hits }
                Hit { slot: 5; hits: perched.hits }
                Hit { slot: 6; hits: perched.hits }
                Hit { slot: 7; hits: perched.hits }
                Hit { slot: 8; hits: perched.hits }
                Hit { slot: 9; hits: perched.hits }
                Hit { slot: 10; hits: perched.hits }
                Hit { slot: 11; hits: perched.hits }
            }

            Figure {
                id: perched
                anchors.fill: parent
                her: stage.her
                slot: "perch:" + stage.name
                visible: !stage.her.perchHide
                origin: Qt.point((stage.mon ? stage.mon.x : 0) + (stage.box ? stage.box.x : 0), (stage.mon ? stage.mon.y : 0) + (stage.box ? stage.box.y : 0))
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                onPressed: mouse => stage.her.grab(perched.origin.x + mouse.x, perched.origin.y + mouse.y)
                onPositionChanged: mouse => stage.her.drag(perched.origin.x + mouse.x, perched.origin.y + mouse.y)
                onReleased: stage.her.drop()
                onCanceled: stage.her.drop()
            }
        }
    }

    LazyLoader {
        active: stage.her.flightOn && stage.her.flightScreens.indexOf(stage.name) >= 0 && !!stage.mon

        PanelWindow {
            screen: stage.modelData
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "glasshouse-sill"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            mask: Region {}

            Figure {
                anchors.fill: parent
                her: stage.her
                slot: "flight:" + stage.name
                origin: Qt.point(stage.mon ? stage.mon.x : 0, stage.mon ? stage.mon.y : 0)
            }
        }
    }
}
