import QtQuick
import Quickshell
import qs.core
import qs.kit

Item {
    id: rosary

    required property var owner

    visible: Rite.tray.length > 0
    width: parent.width
    height: beads.height
    Flow {
        id: beads
        width: Math.min(parent.width, Rite.tray.length * 48)
        spacing: 8
        Repeater {
            model: Rite.tray
            Item {
                id: bd
                required property var modelData
                required property int index
                readonly property bool sel: rosary.owner.isSel("tray", bd.index)
                readonly property bool symbolic: /symbolic/.test(String(bd.modelData.icon))
                width: 40
                height: 40
                function use(how: string): void {
                    const at = bd.QsWindow.itemPosition(bd);
                    Rite.trayItem(bd.modelData, how, bd.QsWindow.window, Math.round(at.x), Math.round(at.y + (bd.height + 6) * Screens.unitOf(bd)));
                }
                Connections {
                    target: Rite
                    function onTrayMenu(i: int): void {
                        if (i === bd.index)
                            bd.use("menu");
                    }
                }
                Glass {
                    anchors.fill: parent
                    src: Theme.a("sanctum-bead.png")
                    light: Qt.point(0.35, 0.2)
                    power: 0.4
                    ambient: bd.sel ? 1.0 : 0.75
                    radius: 0.6
                }
                Lead {
                    anchors.fill: parent
                    src: Theme.a("sanctum-bead-lead.png")
                    lx: 0.3
                    ly: -0.6
                    depth: 3
                }
                Image {
                    id: trayIcon
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    sourceSize: Qt.size(40, 40)
                    source: bd.modelData.icon
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    visible: !bd.symbolic
                }
                ShaderEffect {
                    visible: bd.symbolic
                    anchors.fill: trayIcon
                    property variant icon: trayIcon
                    property color ink: bd.sel ? Theme.ivory : rosary.owner.inkSoft
                    fragmentShader: Qt.resolvedUrl("../../shaders/sanctum-tint.frag.qsb")
                }
                Rectangle {
                    visible: bd.sel
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.ivory
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onEntered: rosary.owner.pick("tray", bd.index)
                    onClicked: mouse => {
                        rosary.owner.pick("tray", bd.index);
                        bd.use(mouse.button === Qt.LeftButton ? "activate" : mouse.button === Qt.RightButton ? "menu" : "secondary");
                    }
                }
            }
        }
    }
    Text {
        visible: Rite.zone === "tray"
        x: beads.width + 14
        width: parent.width - x
        anchors.verticalCenter: beads.verticalCenter
        elide: Text.ElideRight
        readonly property var item: Rite.tray[Rite.index]
        text: item ? (item.tooltipTitle || item.title || item.id) : ""
        font.family: rosary.owner.face
        font.pixelSize: 14
        color: rosary.owner.inkSoft
    }
}
