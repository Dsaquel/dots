pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Singleton {
    id: a

    readonly property var layouts: a.parse(geometry.text())
    readonly property var bottles: a.parse(bottleMeta.text())

    function parse(text: string): var {
        try {
            return JSON.parse(text || "{}");
        } catch (e) {
            return {};
        }
    }

    function layout(role: string): var {
        return a.layouts[role] || null;
    }

    function of(output: string): var {
        const role = Screens.role(output);
        const L = a.layouts[role];
        if (!L)
            return null;
        const sc = Quickshell.screens.find(s => s.name === output);
        const edge = role === "main" ? "left" : "right";
        const sw = sc ? sc.width : Screens.design.width;
        const u = sc ? Screens.fit(sc.width, sc.height) : 1;
        const zone = Math.round(L.zone * u);
        const strip = edge === "left" ? 0 : sw - zone;
        const x = strip + L.x * u;
        const y = L.y * u;
        const folded = Fold.folded(role);
        const H = L.handle;
        const hx = edge === "left" ? H.inset * u : sw - (H.inset + H.w) * u;
        const hy = (L.y + H.cy - H.h / 2) * u;
        return {
            role: role,
            edge: edge,
            u: u,
            zone: zone,
            strip: strip,
            x: x,
            y: y,
            w: L.W * u,
            h: L.H * u,
            folded: folded,
            reach: folded ? Math.round(H.zone * u) : zone,
            roundel: L.roundel && !folded ? { cx: x + L.roundel.cx * u, cy: y + L.roundel.cy * u, r: (L.roundel.r + 4) * u } : null,
            handle: { x: hx, y: hy, w: H.w * u, h: H.h * u, cx: hx + H.w * u / 2, cy: hy + (H.pearl ? H.pearl.cy : H.h / 2) * u, r: H.w * u / 2 },
            layout: L
        };
    }

    function bottle(sprite: string): var {
        return a.bottles[sprite] || null;
    }

    FileView {
        id: geometry
        path: Quickshell.shellPath("assets/shared/lancet.json")
        blockLoading: true
    }

    FileView {
        id: bottleMeta
        path: Assets.root + "/potions/lancet/potions.json"
        blockLoading: true
        printErrors: false
    }
}
