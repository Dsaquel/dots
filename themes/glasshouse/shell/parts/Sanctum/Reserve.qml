import QtQuick
import Quickshell
import qs.core

Scope {
    id: reserve

    property int herPx: 0
    readonly property var held: {
        const own = ["window", "sun", "sun-lead", "predella", "predella-lead", "halo", "halo-glow", "arch-iron", "arch-glass", "arch-glass-glow", "loz", "loz-on", "loz-on-glow", "loz-lead", "bead", "bead-lead", "row", "row-lead", "search", "search-lead", "card", "card-lead", "plaque", "plaque-lead", "gauge", "gauge-lead", "gauge-glow", "ring", "ring-lead", "btn", "btn-lead", "medal-gilt", "crest-gilt", "week", "week-lead", "week-lit", "week-lit-glow"];
        for (let k = 0; k < 5; k++)
            own.push("ring-" + k, "ring-" + k + "-lead");
        for (const n of ["medal", "crest", "art", "power", "power-armed"])
            own.push(n, n + "-glow", n + "-lead");
        for (const side of ["left", "right"]) {
            for (const n of ["", "-glow", "-jewels-glow", "-lead", "-gilt", "-lights", "-lights-glow", "-lights-order"])
                own.push("wing-" + side + n);
        }
        for (const side of ["left", "right"])
            own.push(...(Theme.dark ? ["wing-" + side + "-drop", "wing-" + side + "-drop-glow"] : ["rose-" + side, "rose-" + side + "-glow"]));
        if (!Theme.dark)
            own.push("rose-lead");
        const urls = own.map(n => Theme.a("sanctum-" + n + ".png").toString());
        for (const n of ["glass-noise", "sanctum-grain", "sanctum-circle-outer", "sanctum-circle-outer-glow", "sanctum-circle-inner", "sanctum-circle-inner-glow"])
            urls.push(Theme.shared(n + ".png").toString());
        const skin = ["left", "left-lead", "left-lights", "left-lights-glow", "right", "right-lead", "right-lights", "right-lights-glow", "centre-frame", "centre-frame-lead", "centre-window"];
        for (const side of ["left", "right"])
            skin.push(...(Theme.dark ? [side + "-drop", side + "-drop-glow"] : [side + "-rose", side + "-rose-glow", side + "-rose-gold"]));
        for (const n of skin) {
            const u = Assets.url("wings/skin/" + Theme.world + "/" + n + ".png");
            if (u !== "")
                urls.push(u);
        }
        return urls;
    }
    Instantiator {
        model: reserve.held
        delegate: Image {
            required property string modelData
            source: modelData
            visible: false
        }
    }
    Image {
        source: Assets.url("heroine/cut/menu-" + World.name + ".png")
        sourceSize: Qt.size(reserve.herPx, reserve.herPx)
        visible: false
    }
}
