pragma Singleton

import QtQuick
import Quickshell
import qs.core

Singleton {
    id: f

    function folded(role: string): bool {
        return role === "side" ? Settings.foldSide : Settings.foldMain;
    }
    function roles(which: string): var {
        if (which === "both")
            return ["main", "side"];
        if (which === "main" || which === "side")
            return [which];
        const role = Screens.role(which === "focused" ? Hypr.focusedMonitor : which);
        return role ? [role] : [];
    }
    function set(which: string, on: bool): void {
        for (const role of f.roles(which)) {
            if (role === "side")
                Settings.foldSide = on;
            else
                Settings.foldMain = on;
        }
    }
    function toggle(which: string): void {
        f.set(which, !f.roles(which).every(r => f.folded(r)));
    }
    function status(): string {
        return JSON.stringify(Screens.list.map(sc => {
            const g = Anchor.of(sc.name);
            return { output: sc.name, role: g ? g.role : "", folded: !!g && g.folded, zone: g ? g.reach : 0 };
        }));
    }
}
