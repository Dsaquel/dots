import QtQuick
import qs.core

Item {
    id: fx

    required property string output
    property point origin: Qt.point(0, 0)
    property rect area: Qt.rect(0, 0, 0, 0)
    property string ride: "far"
    property real t: 0
    property real seed: 0
    property bool relit: false
    property bool cutout: false
    property string world: "dark"
    readonly property var out: Stage.of(output)
    readonly property real s: out ? out.s : 1
    readonly property real u: Screens.unit(output)
    readonly property real lx: out ? (ride === "deep" ? out.deepX : out.farX) : 0
    readonly property real ly: out ? out.fy : 0
    readonly property var art: out ? Stage.layers(output, world) : ({})
    readonly property bool layered: !!art.deep
    readonly property bool ready: !relit || (farImg.status === Image.Ready && (!layered || nearImg.status === Image.Ready) && (maskUrl === "" || maskImg.status === Image.Ready) && (cutUrl === "" || cutImg.status === Image.Ready))

    readonly property real dec: out ? Math.min(1, (art.source ? art.source[0] : out.fw) / out.fw) : 1
    readonly property size decSize: out ? Qt.size(Math.round(out.fw * dec), Math.round(out.fh * dec)) : Qt.size(1, 1)
    readonly property rect clip: {
        if (!out)
            return Qt.rect(0, 0, 1, 1);
        const m = Math.abs(Stage.deepPx - out.farPx) + 4;
        const x0 = Math.max(0, Math.floor((area.x * s - m) * dec));
        const y0 = Math.max(0, Math.floor(area.y * s * dec));
        const x1 = Math.min(decSize.width, Math.ceil(((area.x + area.width) * s + m) * dec));
        const y1 = Math.min(decSize.height, Math.ceil((area.y + area.height) * s * dec));
        return Qt.rect(x0, y0, Math.max(1, x1 - x0), Math.max(1, y1 - y0));
    }
    readonly property rect crop: Qt.rect(clip.x / dec, clip.y / dec, clip.width / dec, clip.height / dec)
    function map(layerX: real): vector4d {
        const ox = (lx - layerX + area.x * s - crop.x) / crop.width;
        const oy = (area.y * s - crop.y) / crop.height;
        return Qt.vector4d(ox, oy, width / crop.width, height / crop.height);
    }
    readonly property vector4d farMap: out ? map(layered ? out.deepX : out.farX) : Qt.vector4d(0, 0, 1, 1)
    readonly property vector4d nearMap: out ? map(out.farX) : Qt.vector4d(0, 0, 1, 1)
    property string mask: ""
    readonly property string maskUrl: mask !== "" ? Assets.url(mask) : ""
    readonly property Item farTex: farImg
    readonly property Item nearTex: layered ? nearImg : farImg
    readonly property Item maskTex: maskUrl !== "" ? maskImg : farImg
    readonly property real hasNear: layered ? 1 : 0
    readonly property real hasMask: maskUrl !== "" ? 1 : 0
    readonly property string cutUrl: cutout ? (art.cut || "") : ""
    readonly property Item cutTex: cutUrl !== "" ? cutImg : farImg
    readonly property real hasCut: cutUrl !== "" ? 1 : 0

    function px(sx: real, sy: real): point {
        return Qt.point((sx - fx.area.x) * fx.s, (sy - fx.area.y) * fx.s);
    }
    function uv(sx: real, sy: real): point {
        return Qt.point((sx - area.x) / Math.max(1, area.width), (sy - area.y) / Math.max(1, area.height));
    }

    x: lx + area.x * s - origin.x
    y: ly + area.y * s - origin.y
    width: area.width * s
    height: area.height * s
    visible: ready

    Image {
        id: farImg
        visible: false
        source: fx.relit && fx.out ? (fx.art.deep || fx.art.plate) : ""
        sourceSize: fx.decSize
        sourceClipRect: fx.clip
        asynchronous: true
        smooth: true
        cache: false
    }
    Image {
        id: nearImg
        visible: false
        source: fx.relit && fx.out && fx.layered ? fx.art.plate : ""
        sourceSize: fx.decSize
        sourceClipRect: fx.clip
        asynchronous: true
        smooth: true
        cache: false
    }

    Image {
        id: maskImg
        visible: false
        source: fx.relit && fx.out ? fx.maskUrl : ""
        sourceSize: fx.decSize
        sourceClipRect: fx.clip
        asynchronous: true
        smooth: true
        cache: false
    }

    Image {
        id: cutImg
        visible: false
        source: fx.relit && fx.out ? fx.cutUrl : ""
        sourceSize: fx.decSize
        sourceClipRect: fx.clip
        asynchronous: true
        smooth: true
        cache: false
    }

    property bool hurried: false
    onHurriedChanged: Stage.hurry(fx.output, fx.hurried ? 1 : -1)

    Component.onCompleted: Stage.want(fx.output, 1)
    Component.onDestruction: {
        if (fx.hurried)
            Stage.hurry(fx.output, -1);
        Stage.want(fx.output, -1);
    }
}
