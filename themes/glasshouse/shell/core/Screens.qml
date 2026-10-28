pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: s

    readonly property string spec: Quickshell.env("GLASSHOUSE_SCREENS") || s.derived
    readonly property string derived: {
        const all = Array.from(Quickshell.screens).sort((a, b) => a.x - b.x || a.y - b.y);
        return all.map((sc, i) => all.length === 1 ? `${sc.name}=main:1-10` : `${sc.name}=${i === 0 ? "main" : "side"}:${5 * i + 1}-${5 * i + 5}`).join(",");
    }
    readonly property var roles: {
        const out = {};
        for (const part of s.spec.split(",")) {
            const m = part.trim().match(/^([^=]+)=(main|side):(\d+)-(\d+)$/);
            if (!m)
                continue;
            const ws = [];
            for (let i = Number(m[3]); i <= Number(m[4]); i++)
                ws.push(i);
            out[m[1]] = { name: m[1], role: m[2], workspaces: ws };
        }
        return out;
    }
    readonly property var list: Quickshell.screens.filter(sc => s.roles[sc.name] !== undefined)
    readonly property size design: Qt.size(1920, 1080)

    function fit(w: real, h: real): real {
        return w > 0 && h > 0 ? Math.min(w / s.design.width, h / s.design.height) : 1;
    }
    function unit(name: string): real {
        const sc = Quickshell.screens.find(x => x.name === name);
        return sc ? s.fit(sc.width, sc.height) : 1;
    }
    function unitOf(item: Item): real {
        const w = item ? item.QsWindow.window : null;
        return w && w.screen ? s.fit(w.screen.width, w.screen.height) : 1;
    }

    function info(name: string): var {
        return s.roles[name] || null;
    }
    function role(name: string): string {
        const i = s.roles[name];
        return i ? i.role : "";
    }
    function workspaces(name: string): var {
        const i = s.roles[name];
        return i ? i.workspaces : [];
    }
    function owner(ws: int): string {
        for (const n in s.roles)
            if (s.roles[n].workspaces.indexOf(ws) >= 0)
                return n;
        return "";
    }
}
