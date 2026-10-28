import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.core

// NVIDIA idles at P8 (405 MHz memory) and takes ~150 ms of load to clock up, so the first workspace switch
// after a pause dropped 3-12 frames at 144 Hz: Super's press heats the GPU until the switch lands
Scope {
    id: part

    readonly property var screen: Screens.list.find(sc => Screens.role(sc.name) === "main") || Screens.list[0]
    readonly property real u: Screens.unit(part.screen.name)

    GlobalShortcut {
        appid: Test.on ? "glasshouse-test" : "glasshouse"
        name: "warm"
        description: "Heats the GPU before a workspace switch"
        onPressed: heat.restart()
    }

    Connections {
        target: Hypr
        function onWorkspaceSwitched(monitor: string, from: int, to: int): void {
            heat.stop();
        }
    }

    Timer {
        id: heat
        interval: 400
    }

    PanelWindow {
        screen: part.screen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "glasshouse-kiln"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { bottom: true; right: true }
        implicitWidth: 512 * part.u
        implicitHeight: 512 * part.u
        color: "transparent"
        mask: Region {}

        ShaderEffect {
            anchors.fill: parent
            property real t: 0
            NumberAnimation on t {
                running: heat.running
                from: 0
                to: 1000
                duration: 1000000
                loops: Animation.Infinite
            }
            fragmentShader: Qt.resolvedUrl("../../shaders/kiln.frag.qsb")
        }
    }
}
