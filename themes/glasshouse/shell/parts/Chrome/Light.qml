import QtQuick
import qs.core

QtObject {
    id: l

    property string screen
    property real width: Hypr.monitors[l.screen] ? Hypr.monitors[l.screen].w : Screens.design.width
    property real height: Hypr.monitors[l.screen] ? Hypr.monitors[l.screen].h : Screens.design.height

    readonly property var info: Screens.info(l.screen)
    readonly property bool main: !l.info || l.info.role === "main"
    readonly property int index: l.info ? Math.max(0, l.info.workspaces.indexOf(Hypr.activeWs(l.screen))) : 0
    readonly property point uv: l.main ? (World.dark ? Qt.point(0.523, 0.323) : Qt.point(0.57, 0.06)) : (World.dark ? Qt.point(0.293, 0.319) : Qt.point(0.184, 0.312))
    readonly property real fw: Math.max(l.width, l.height * 16 / 9) * 1.025
    readonly property real fh: l.fw * 9 / 16
    readonly property point pos: Qt.point(-(l.fw - l.width) * l.index / 4 + l.uv.x * l.fw, (l.height - l.fh) / 2 + l.uv.y * l.fh)
    readonly property color color: World.dark ? Theme.lamp : Theme.sun
}
