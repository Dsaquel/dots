import QtQuick
import qs.core
import qs.kit

Item {
    id: body

    required property string output
    property string world: World.name
    property bool life: false
    property int fadeMs: 1200
    readonly property var out: Stage.of(output)
    readonly property string role: out ? out.role : "main"
    readonly property bool plain: Assets.ready && Stage.still(role, world) === ""
    readonly property bool ready: plain || (slotOf(world).ready && slotOf(world).opacity >= 1)

    function slotOf(w: string): Item {
        return w === "light" ? lightSlot : darkSlot;
    }

    function settle(): void {
        if (!Assets.ready || !body.out)
            return;
        const inc = body.slotOf(body.world);
        const oth = inc === darkSlot ? lightSlot : darkSlot;
        if (body.plain) {
            inc.fadeTo(0);
            oth.fadeTo(0);
            return;
        }
        if (!inc.ready)
            return;
        if (inc.opacity >= 1 && oth.opacity > 0 && oth.z > inc.z) {
            oth.fadeTo(0);
            return;
        }
        if (inc.opacity < 1) {
            inc.z = oth.z + 1;
            inc.fadeTo(1);
            return;
        }
        oth.opacity = 0;
    }

    onWorldChanged: settle()
    onOutChanged: settle()
    Component.onCompleted: settle()

    Connections {
        target: Assets
        function onReadyChanged(): void {
            body.settle();
        }
    }

    component Slot: Item {
        id: slot

        required property string name
        readonly property bool wanted: Assets.ready && body.out !== null && (body.world === slot.name || slot.opacity > 0)
        readonly property var art: body.out ? Stage.layers(body.output, slot.name) : ({})
        readonly property bool ready: plate.status === Image.Ready && (!slot.art.deep || deep.status === Image.Ready)

        function fadeTo(v: real): void {
            fade.stop();
            if (Math.abs(slot.opacity - v) < 0.001)
                return;
            const first = v > 0 && darkSlot.opacity <= 0 && lightSlot.opacity <= 0;
            const ms = body.fadeMs <= 0 ? 0 : (first ? 700 : body.fadeMs);
            if (ms <= 0) {
                slot.opacity = v;
                Qt.callLater(body.settle);
                return;
            }
            fade.to = v;
            fade.duration = ms * Math.abs(slot.opacity - v);
            fade.start();
        }

        anchors.fill: parent
        opacity: 0
        visible: opacity > 0
        layer.enabled: opacity > 0 && opacity < 1

        onReadyChanged: body.settle()

        NumberAnimation {
            id: fade
            target: slot
            property: "opacity"
            easing.type: Easing.InOutCubic
            onFinished: body.settle()
        }

        Image {
            id: deep
            x: body.out ? body.out.deepX : 0
            y: plate.y
            width: plate.width
            height: plate.height
            sourceSize: Qt.size(width, height)
            source: slot.wanted ? (slot.art.deep || "") : ""
            asynchronous: true
            smooth: true
            cache: false
        }
        Image {
            id: plate
            x: body.out ? body.out.farX : 0
            y: body.out ? body.out.fy : 0
            width: body.out ? body.out.fw : 0
            height: body.out ? body.out.fh : 0
            sourceSize: Qt.size(width, height)
            source: slot.wanted ? slot.art.plate : ""
            asynchronous: true
            smooth: true
            cache: false
        }

        Repeater {
            model: body.life && slot.wanted && slot.ready ? Stage.fx(body.role, slot.name) : []
            Loader {
                required property var modelData
                Component.onCompleted: setSource(Qt.resolvedUrl(modelData.kind + ".qml"), Stage.props(modelData, body.output, slot.name, Qt.point(0, 0)))
                onLoaded: item.t = Qt.binding(() => body.out ? body.out.t : 0)
            }
        }
    }

    Slot {
        id: darkSlot
        name: "dark"
    }
    Slot {
        id: lightSlot
        name: "light"
    }

    Item {
        anchors.fill: parent
        visible: body.plain

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Theme.field
                    Behavior on color { ColorAnimation { duration: body.fadeMs; easing.type: Easing.InOutCubic } }
                }
                GradientStop {
                    position: 1.0
                    color: Theme.ground
                    Behavior on color { ColorAnimation { duration: body.fadeMs; easing.type: Easing.InOutCubic } }
                }
            }
        }
        Glow {
            x: (parent.width - width) / 2
            y: -height * 0.34
            width: parent.width * 1.4
            height: parent.height * 1.5
            color: Theme.dark ? "#6577bd" : "#ffd48a"
            core: 0.45
            intensity: Theme.dark ? 0.2 : 0.26
            Behavior on color { ColorAnimation { duration: body.fadeMs; easing.type: Easing.InOutCubic } }
        }
        Image {
            anchors.fill: parent
            source: Theme.shared("glass-noise.png")
            fillMode: Image.Tile
            opacity: 0.04
        }
    }
}
