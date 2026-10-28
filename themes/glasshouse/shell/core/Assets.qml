pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: a

    readonly property string root: Quickshell.env("GLASSHOUSE_PACK") || Quickshell.env("HOME") + "/.local/share/glasshouse"
    property var files: ({})
    property bool ready: false

    function has(rel: string): bool {
        return !!a.files[rel];
    }
    function path(rel: string): string {
        return a.files[rel] ? a.root + "/" + rel : "";
    }
    function url(rel: string): string {
        return a.files[rel] ? "file://" + a.root + "/" + rel : "";
    }

    function room(world: string): string {
        return a.url("world/room-" + world + "-1440.png");
    }
    function diner(world: string): string {
        return a.url("world/diner-" + world + ".png");
    }
    function asleep(world: string): string {
        return a.url("world/room-" + world + "-asleep.png");
    }
    function face(world: string, mood: string): string {
        return a.url("heroine/faces/" + world + "-" + mood + ".png");
    }
    function potion(world: string, name: string): string {
        return a.url("potions/" + (world === "dark" ? "night-" : "day-") + name + ".png");
    }
    function clip(name: string): string {
        return a.url("clips/" + name + ".mp4");
    }

    Process {
        running: true
        command: ["find", "-L", a.root, "-type", "f", "-printf", "%P\\n"]
        stdout: StdioCollector {
            onStreamFinished: {
                const set = {};
                for (const line of text.split("\n"))
                    if (line)
                        set[line] = true;
                a.files = set;
                a.ready = true;
            }
        }
        onExited: code => {
            if (code !== 0)
                a.ready = true;
        }
    }
}
