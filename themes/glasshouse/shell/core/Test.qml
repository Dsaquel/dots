pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: t

    readonly property bool on: Quickshell.env("GLASSHOUSE_TEST") === "1"
    readonly property string sink: on ? Quickshell.env("GLASSHOUSE_SINK") || "" : ""
    readonly property string source: on ? Quickshell.env("GLASSHOUSE_SOURCE") || "" : ""
    property string focus: ""
    property string hover: ""
    property bool keepalive: false

    IpcHandler {
        target: "test"
        enabled: t.on
        function focus(address: string): void {
            t.focus = address.replace(/^0x/, "");
        }
        function hover(key: string): void {
            t.hover = key;
        }
        function keepalive(on: bool): void {
            t.keepalive = on;
        }
        function clear(): void {
            t.focus = "";
            t.hover = "";
        }
    }
}
