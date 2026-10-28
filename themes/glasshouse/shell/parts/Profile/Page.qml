import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.core
import qs.kit
import qs.parts.Lancet
import qs.parts.Chat

PanelWindow {
    id: win

    required property ShellScreen modelData
    property bool open: true
    signal dismiss()
    signal folded()

    readonly property var geo: Anchor.of(win.modelData.name)
    readonly property real u: win.geo ? win.geo.u : Screens.unit(win.modelData.name)
    readonly property var lay: JSON.parse(layoutFile.text() || "{}")
    readonly property real pageW: win.lay.W || 380
    readonly property real pageH: win.lay.H || 714
    readonly property point light: Theme.dark ? Qt.point(0.86, 0.02) : Qt.point(0.18, 0.0)
    readonly property color gold: Theme.dark ? Theme.rare : Theme.sun

    screen: win.modelData
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "glasshouse-profile"
    WlrLayershell.keyboardFocus: Test.on ? WlrKeyboardFocus.None : WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors {
        left: true
        top: true
        bottom: true
    }
    margins.left: win.geo ? win.geo.reach : 104
    implicitWidth: Math.round((win.pageW + (win.lay.gap || 6) + 44) * win.u)
    color: "transparent"
    mask: Region {
        item: hit
    }

    HyprlandFocusGrab {
        active: !Test.on && win.open
        windows: [win]
        onCleared: win.dismiss()
    }

    FileView {
        id: layoutFile
        path: Quickshell.shellPath("assets/shared/profile.json")
        blockLoading: true
    }

    Clock {
        id: clock
    }
    property real openAt: -99
    property bool closing: false
    property real closeAt: -99
    property real closeFrom: 1
    function revealNow(): real {
        return clock.out((clock.t - win.openAt) / 0.7);
    }
    readonly property real reveal: win.closing ? win.closeFrom * (1 - clock.inout((clock.t - win.closeAt) / 0.45)) : win.revealNow()
    readonly property real lightUp: clock.out((clock.t - win.openAt - 0.12) / 0.8)
    onOpenChanged: {
        if (win.open) {
            foldTimer.stop();
            win.closing = false;
            win.openAt = clock.kick(1.25, true);
        } else {
            win.closeFrom = win.revealNow();
            win.closeAt = clock.kick(0.47, true);
            win.closing = true;
            foldTimer.start();
        }
    }
    Timer {
        id: foldTimer
        interval: 480
        onTriggered: win.folded()
    }
    Component.onCompleted: win.openAt = clock.kick(1.25, true)

    readonly property var moodWords: ({ pout: "pouting", wink: "playful", laugh: "laughing" })
    readonly property string moodWhy: {
        if (Settings.dnd)
            return "do not disturb: she rests";
        if (Her.idle)
            return "you stepped away";
        const r = ({ done: "a brew is done", needs: "a session asks for you", error: "a critical letter came", message: "a letter came", greet: "she has news" })[Her.reaction];
        if (r)
            return r;
        if (Agents.needing > 0)
            return Agents.needing === 1 ? "a session waits for you" : Agents.needing + " sessions wait for you";
        const w = Agents.live.filter(s => s.state === "working").map(s => s.label);
        return w.length ? "brewing " + w.slice(0, 2).join("  ·  ") : "nothing on the fire";
    }

    Item {
        id: hit
        x: leaf.x
        y: leaf.y
        width: win.reveal > 0.5 ? win.pageW * win.u : 0
        height: win.pageH * win.u
    }

    Item {
        id: leaf
        x: ((win.lay.gap || 6) - (win.pageW + 50) * (1 - win.reveal)) * win.u
        y: win.geo ? win.geo.y : 6
        width: win.pageW
        height: win.pageH
        scale: win.u
        transformOrigin: Item.TopLeft
        visible: win.reveal > 0.001 && !!win.lay.W

        Image {
            readonly property real pad: win.lay.shadowPad || 30
            x: -pad + 5
            y: -pad + 9
            width: win.pageW + 2 * pad
            height: win.pageH + 2 * pad
            source: Theme.shared("profile-page-shadow.png")
        }
        Glass {
            anchors.fill: parent
            src: Theme.a("profile-page.png")
            light: win.light
            radius: 0.62
            power: Theme.dark ? 0.56 : 0.5
            ambient: Theme.dark ? 0.72 : 0.78
            grain: 0.14
        }
        ShaderEffect {
            id: portrait
            readonly property var pt: win.lay.portrait || ({ x: 0, y: 0, w: 1, bottom: 1 })
            readonly property real cu: Theme.dark ? 0.43 : 0.6
            readonly property real dv: 0.97
            readonly property real du: portrait.dv * portrait.width / Math.max(1, portrait.height)
            x: pt.x
            y: pt.y
            width: pt.w
            height: pt.bottom - pt.y
            visible: portrait.portrait.status === Image.Ready
            property variant portrait: Image {
                source: Assets.url("heroine/portrait-" + World.name + ".png")
                sourceSize: Qt.size(1024, 1024)
                asynchronous: true
                smooth: true
                mipmap: true
                visible: false
            }
            property variant arch: Image {
                source: Theme.shared("profile-portrait-mask.png")
                smooth: true
                visible: false
            }
            property variant grainTex: Image {
                source: Theme.shared("glass-noise.png")
                visible: false
            }
            property vector4d crop: Qt.vector4d(portrait.cu - portrait.du / 2, 0.015, portrait.du, portrait.dv)
            property color rim: Theme.dark ? Theme.lamp : Theme.sun
            property size grainScale: Qt.size(portrait.width / 256, portrait.height / 256)
            property real reveal: win.lightUp
            property real shade: 0.38
            property real grain: 0.035
            fragmentShader: Qt.resolvedUrl("../../shaders/profile-portrait.frag.qsb")
        }
        Glow {
            readonly property var rg: win.lay.mood ? win.lay.mood.ring : ({ cx: 0, cy: 0, r: 0 })
            x: rg.cx - width / 2
            y: rg.cy - height / 2
            width: 130
            height: 130
            color: Theme.dark ? Theme.lamp : Theme.sun
            core: 0.25
            intensity: Settings.dnd ? 0.06 : 0.2
        }
        Image {
            readonly property var rg: win.lay.mood ? win.lay.mood.ring : ({ cx: 0, cy: 0, r: 2 })
            x: rg.cx - (rg.r - 6)
            y: rg.cy - (rg.r - 6)
            width: 2 * (rg.r - 6)
            height: width
            sourceSize: Qt.size(128, 128)
            source: Her.face
            smooth: true
            mipmap: true
            opacity: Settings.dnd ? 0.6 : 1
        }
        Metal {
            anchors.fill: parent
            src: Theme.a("profile-page-lead.png")
            base: Theme.dark ? "#3a3950" : "#3b3470"
            hi: Theme.dark ? "#d6d3f2" : "#c9c0ff"
            low: Theme.dark ? "#06070e" : "#0c0a24"
            sky: Theme.dark ? "#7d88ba" : "#8f86d8"
            metal: 0.45
            shininess: 12
            depth: 2.4
            lx: win.light.x - 0.3
            ly: win.light.y - 0.25
        }
        Metal {
            anchors.fill: parent
            src: Theme.a("profile-page-gilt.png")
            base: Theme.dark ? Theme.metalBase : "#c99a4e"
            hi: Theme.dark ? Theme.metalHi : "#fff4cf"
            low: Theme.dark ? Theme.metalLow : "#3b2410"
            sky: Theme.dark ? Theme.metalSky : "#f7dfa4"
            metal: Theme.dark ? 0.7 : 1.0
            shininess: Theme.dark ? 30 : 46
            depth: 4.2
            lx: win.light.x - 0.2
            ly: win.light.y - 0.3
        }
        Repeater {
            model: !Theme.dark && win.lay.pearls ? win.lay.pearls : []
            Pearl {
                required property var modelData
                width: 8
                height: 8
                x: modelData[0] - 4
                y: modelData[1] - 4
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: titulus
            readonly property var r: win.lay.titulus || ({ x: 0, y: 0, w: 0, h: 0 })
            x: r.x
            y: r.y
            width: r.w
            height: r.h
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 29 - jp.baselineOffset
                Text {
                    visible: !Theme.dark
                    anchors.baseline: jp.baseline
                    text: "【"
                    font.family: Theme.jp
                    font.pixelSize: 20
                    color: "#ff5fae"
                }
                Text {
                    id: jp
                    text: "錬金術師"
                    font.family: Theme.jp
                    font.weight: Theme.dark ? Font.ExtraBold : Font.Normal
                    font.pixelSize: Theme.dark ? 22 : 20
                    font.letterSpacing: Theme.dark ? 4 : 2
                    color: Theme.dark ? "#eef1fb" : Theme.ink
                    renderType: Text.CurveRendering
                }
                Text {
                    visible: !Theme.dark
                    anchors.baseline: jp.baseline
                    text: "】"
                    font.family: Theme.jp
                    font.pixelSize: 20
                    color: "#ff5fae"
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 46 - baselineOffset
                text: "THE ALCHEMIST"
                font.family: Theme.caps
                font.pixelSize: 10
                font.letterSpacing: Theme.capsTracking + 1
                font.weight: Font.DemiBold
                color: win.gold
                renderType: Text.NativeRendering
            }
        }

        Item {
            id: mood
            readonly property var r: win.lay.mood || ({ x: 0, y: 0, w: 0, h: 0, ring: { cx: 0, cy: 0, r: 0 } })
            readonly property real textX: mood.r.ring.cx - mood.r.x + mood.r.ring.r + 20
            x: r.x
            y: r.y
            width: r.w
            height: r.h
            Item {
                x: mood.textX
                width: mood.width - mood.textX - 14
                height: mood.height
                Text {
                    y: 27 - baselineOffset
                    text: "HER MOOD"
                    font.family: Theme.caps
                    font.pixelSize: 10
                    font.letterSpacing: Theme.capsTracking
                    font.weight: Font.DemiBold
                    color: win.gold
                    renderType: Text.NativeRendering
                }
                Text {
                    y: 58 - baselineOffset
                    text: win.moodWords[Her.faceName] || Her.faceName
                    font.family: Theme.numerals
                    font.pixelSize: 28
                    font.variableAxes: Theme.dark ? ({}) : ({ "wght": 560, "opsz": 28 })
                    color: Theme.ink
                    renderType: Text.CurveRendering
                }
                Text {
                    y: 76 - baselineOffset
                    width: parent.width
                    text: win.moodWhy
                    elide: Text.ElideRight
                    font.family: Theme.ui
                    font.pixelSize: 12
                    color: Theme.dim
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    Item {
        focus: !Test.on
        Keys.onEscapePressed: win.dismiss()
    }
}
