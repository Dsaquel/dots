import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.core
import qs.parts.Lancet
import qs.parts.Chrome

Item {
    id: desk

    required property string output
    property bool solid: false
    property var looks: ({})
    property var bg: null
    readonly property var geo: Anchor.of(desk.output)
    readonly property var shown: Hypr.on(desk.output)
    readonly property bool full: desk.shown.some(w => w.fullscreen && !w.special)
    readonly property bool anySpecial: desk.shown.some(w => w.special)

    function rank(w: var): int {
        return w.fullscreen && !w.special ? 3 : (w.special ? 2 : (w.floating ? 1 : 0));
    }
    readonly property var stack: desk.shown.slice().sort((a, b) => desk.rank(a) - desk.rank(b) || (a.floating && b.floating ? b.history - a.history : 0))

    function isAbove(o: var, w: var): bool {
        if (o.special !== w.special)
            return o.special;
        if (o.floating !== w.floating)
            return o.floating;
        return o.floating && o.history < w.history;
    }
    function overlaps(o: var, w: var, m: real): bool {
        return o.lx < w.lx + w.w + m && o.lx + o.w > w.lx - m && o.ly < w.ly + w.h + m && o.ly + o.h > w.ly - m;
    }
    readonly property var frames: {
        const live = desk.shown.filter(w => !w.fullscreen && !(desk.full && !w.special));
        return live.map(w => Object.assign({}, w, {
                key: w.address,
                above: live.filter(o => o !== w && desk.isAbove(o, w) && desk.overlaps(o, w, 72)).map(o => ({ x: o.lx, y: o.ly, w: o.w, h: o.h })),
                dimmed: desk.anySpecial && !w.special
            }));
    }

    Repeater {
        model: ScriptModel {
            values: desk.stack.filter(w => desk.rank(w) < 3)
            objectProp: "address"
        }
        Win {
            required property var modelData
            required property int index
            win: modelData
            look: desk.looks[modelData.address] || ({})
            solid: desk.solid
            bg: desk.bg
            screen: Qt.size(desk.width, desk.height)
            z: index
        }
    }

    LancetBody {
        z: 100
        visible: !!desk.geo && !desk.geo.folded
        output: desk.output
        interactive: false
        x: desk.geo ? desk.geo.x : 0
        y: desk.geo ? desk.geo.y : 0
        scale: desk.geo ? desk.geo.u : 1
        transformOrigin: Item.TopLeft
    }
    Handle {
        z: 100
        visible: !!desk.geo && desk.geo.folded
        output: desk.output
        interactive: false
        x: desk.geo ? desk.geo.handle.x : 0
        y: desk.geo ? desk.geo.handle.y : 0
        scale: desk.geo ? desk.geo.u : 1
        transformOrigin: Item.TopLeft
    }

    Item {
        z: 200
        anchors.fill: parent
        Repeater {
            model: ScriptModel {
                values: desk.frames
                objectProp: "key"
            }
            Frame {
                required property var modelData
                win: modelData
                focused: modelData.address === Hypr.active
                above: modelData.above
                dimmed: modelData.dimmed
                z: modelData.special ? 3 : (modelData.floating ? 2 : 1)
            }
        }
    }

    Repeater {
        model: ScriptModel {
            values: desk.stack.filter(w => desk.rank(w) === 3)
            objectProp: "address"
        }
        Win {
            required property var modelData
            win: modelData
            look: desk.looks[modelData.address] || ({})
            solid: desk.solid
            bg: desk.bg
            screen: Qt.size(desk.width, desk.height)
            z: 300
        }
    }
}
