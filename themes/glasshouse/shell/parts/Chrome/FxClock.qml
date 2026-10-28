import QtQuick

QtObject {
    id: c

    property real rate: 60
    readonly property int step: Math.max(1, Math.floor(1000 / c.rate * Math.ceil(c.rate / 62)))
    property int users: 0

    signal tick(double now)

    readonly property Timer timer: Timer {
        interval: c.step
        repeat: true
        running: c.users > 0
        onTriggered: c.tick(Date.now())
    }
}
