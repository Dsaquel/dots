import QtQuick
import qs.core
import qs.kit

Item {
    id: c

    property int quarter: 0
    property point at
    property point light
    property real glow: 0.5
    property real scaleBy: 1.0
    property real bloom: 1
    readonly property real size: 120 * c.scaleBy
    readonly property real anchor: 36 * c.scaleBy
    readonly property real angle: [0, 90, 180, 270][c.quarter] * Math.PI / 180
    readonly property point localLight: {
        const dx = c.light.x - c.at.x;
        const dy = c.light.y - c.at.y;
        const ca = Math.cos(-c.angle);
        const sa = Math.sin(-c.angle);
        return Qt.point((c.anchor + dx * ca - dy * sa) / c.size, (c.anchor + dx * sa + dy * ca) / c.size);
    }
    readonly property point glassLight: {
        const lx = c.localLight.x - c.anchor / c.size;
        const ly = c.localLight.y - c.anchor / c.size;
        const n = Math.max(1e-3, Math.hypot(lx, ly));
        return Qt.point(0.3 + 0.14 * lx / n, 0.3 + 0.14 * ly / n);
    }

    x: c.at.x - c.anchor
    y: c.at.y - c.anchor
    width: c.size
    height: c.size
    opacity: Math.min(1, c.bloom * 1.6)
    visible: c.bloom > 0.003
    transform: [
        Rotation {
            origin.x: c.anchor
            origin.y: c.anchor
            angle: [0, 90, 180, 270][c.quarter]
        },
        Scale {
            origin.x: c.anchor
            origin.y: c.anchor
            xScale: 0.55 + 0.45 * c.bloom
            yScale: 0.55 + 0.45 * c.bloom
        }
    ]

    Glass {
        anchors.fill: parent
        src: Theme.a("chrome-corner-glow.png")
        additive: 1
        ambient: 0
        power: c.glow * 0.8 * (1 + 1.4 * Math.sin(Math.PI * c.bloom))
        radius: 3.0
        light: c.glassLight
        grain: 0
    }
    Glass {
        anchors.fill: parent
        src: Theme.a("chrome-corner.png")
        light: c.glassLight
        power: 0.16 + 0.5 * c.glow
        ambient: 0.52
        radius: 1.6
    }
    Lead {
        anchors.fill: parent
        src: Theme.a("chrome-corner-lead.png")
        lx: c.localLight.x
        ly: c.localLight.y
        lightZ: 1.4
    }
    Loader {
        anchors.fill: parent
        sourceComponent: Theme.dark ? silver : gilt
        Component {
            id: gilt
            Gilt {
                src: Theme.a("chrome-corner-gilt.png")
                lx: c.localLight.x
                ly: c.localLight.y
                lightZ: 1.4
                depth: 3
            }
        }
        Component {
            id: silver
            Metal {
                src: Theme.a("chrome-corner-gilt.png")
                base: "#9aa3c8"
                hi: "#f2f0ff"
                low: "#141626"
                sky: "#c9d1ee"
                metal: 0.8
                shininess: 40
                depth: 3
                lx: c.localLight.x
                ly: c.localLight.y
                lightZ: 1.4
            }
        }
    }
}
