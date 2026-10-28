import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.core

Scope {
    id: reliquary

    LazyLoader {
        active: Keeper.shown && !!Keeper.screenObj
        Case {
            screen: Keeper.screenObj
        }
    }

    Timer {
        interval: 3000
        running: true
        onTriggered: {
            Keeper.clips.load();
            later.start();
        }
    }
    Timer {
        id: later
        interval: 500
        onTriggered: warmth.active = !!Screens.list.find(s => s.name === Keeper.mainScreen)
    }
    LazyLoader {
        id: warmth
        active: false
        Case {
            warm: true
            screen: Screens.list.find(s => s.name === Keeper.mainScreen) || null
            onWarmed: warmth.active = false
        }
    }

    GlobalShortcut {
        appid: Test.on ? "glasshouse-test" : "glasshouse"
        name: "clipboard"
        description: "The clipboard's history"
        onPressed: Keeper.toggle()
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void {
            Keeper.toggle();
        }
        function open(): void {
            Keeper.open();
        }
        function close(): void {
            Keeper.close();
        }
        function type(text: string): void {
            if (Test.on)
                Keeper.typed(text);
        }
        function key(name: string): string {
            if (!Test.on)
                return "test only";
            const m = name.match(/^(ctrl\+)?(.+)$/i);
            const k = m[2].length === 1 ? m[2].toUpperCase() : m[2];
            return Keeper.key(k, !!m[1]) ? "ok" : "unhandled";
        }
        function screen(name: string): void {
            if (Test.on)
                Keeper.testScreen = name;
        }
        function dump(): string {
            return JSON.stringify({
                opened: Keeper.opened,
                shown: Keeper.shown,
                screen: Keeper.screenName,
                query: Test.on ? Keeper.query : "",
                selected: Keeper.selected,
                target: Keeper.target,
                count: Keeper.results.length,
                results: Test.on ? Keeper.results.slice(0, 12).map(r => r.clip.image ? "image " + r.clip.w + "x" + r.clip.h : r.clip.text) : [],
                firstFrameMs: Keeper.firstFrame,
                acts: Keeper.acts
            });
        }
    }

    Component.onCompleted: Keeper.ruleOut()
}
