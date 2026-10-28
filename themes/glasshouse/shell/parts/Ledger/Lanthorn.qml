import QtQuick
import QtQuick3D
import QtQuick3D.Helpers

Item {
    id: lt

    required property Item still
    required property Item room
    required property point lamp
    required property bool back
    required property bool dark
    property var wins: []
    property var starts: [0, 0, 0, 0, 0, 0, 0, 0]
    property real total: 1.2
    property real landing: 1
    property bool fired: false
    property real t: 0
    readonly property bool running: clock.running
    readonly property color warm: "#ffb36b"
    readonly property real span: 0.65
    readonly property real life: 0.5
    readonly property real pitch: Math.max(20, lt.width / 96)
    readonly property real veil: lt.back ? lt.ease(0, 0.3) * (1 - lt.ease(lt.total - 0.35, lt.total)) : lt.ease(0.1 * lt.landing, 0.85 * lt.landing)
    readonly property real bloom: lt.back ? 0.6 * lt.ease(0.08, 0.3) * (1 - lt.ease(lt.total - 0.45, lt.total)) : lt.ease(0.25, 0.6) * (lt.dark ? 0.55 * (1 - lt.ease(lt.landing - 0.25, lt.landing + 0.18)) : 0.55)

    signal landed
    signal done

    onTChanged: if (!lt.back && !lt.fired && lt.t >= lt.landing) {
        lt.fired = true;
        out.start();
        lt.landed();
    }

    function ease(a: real, b: real): real {
        const u = Math.max(0, Math.min(1, (lt.t - a) / Math.max(0.001, b - a)));
        return u * u * (3 - 2 * u);
    }

    function rect(i: int): vector4d {
        const w = lt.wins[i];
        return w ? Qt.vector4d(w.x, w.y, w.w, w.h) : Qt.vector4d(0, 0, 0, 0);
    }

    function play(list: var): void {
        const wins = list.slice(0, 8);
        const near = w => Math.hypot(Math.max(w.x - lt.lamp.x, 0, lt.lamp.x - w.x - w.w), Math.max(w.y - lt.lamp.y, 0, lt.lamp.y - w.y - w.h));
        const rank = wins.map((w, i) => i).sort((a, b) => near(wins[a]) - near(wins[b]));
        const step = wins.length > 1 ? Math.min(0.12, 0.45 / (wins.length - 1)) : 0;
        const first = lt.back ? 0.55 : 0.05;
        const s = [0, 0, 0, 0, 0, 0, 0, 0];
        rank.forEach((i, k) => s[i] = first + k * step);
        lt.wins = wins;
        lt.starts = s;
        lt.total = first + Math.max(0, wins.length - 1) * step + lt.span + (lt.back ? 0.15 : 1.2 * lt.life);
        lt.landing = first + Math.max(0, wins.length - 1) * step + 0.8 * lt.span + 0.75 * lt.life;
        lt.fired = false;
        out.stop();
        lt.opacity = 1;
        lt.t = 0;
        clock.duration = Math.round(lt.total * 1000);
        clock.restart();
    }

    NumberAnimation {
        id: out
        target: lt
        property: "opacity"
        to: 0
        duration: 180
        easing.type: Easing.InOutSine
    }

    NumberAnimation {
        id: clock
        target: lt
        property: "t"
        from: 0
        to: lt.total
        onFinished: lt.done()
    }

    ShaderEffect {
        anchors.fill: parent
        property variant still: lt.still
        property variant room: lt.room
        property size res: Qt.size(width, height)
        property point lamp: lt.lamp
        property real t: lt.t
        property real span: lt.span
        property real back: lt.back ? 1 : 0
        property real bloom: lt.bloom
        property real veil: lt.veil
        property real margin: 18
        property color warm: lt.warm
        property vector4d w0: lt.rect(0)
        property vector4d w1: lt.rect(1)
        property vector4d w2: lt.rect(2)
        property vector4d w3: lt.rect(3)
        property vector4d w4: lt.rect(4)
        property vector4d w5: lt.rect(5)
        property vector4d w6: lt.rect(6)
        property vector4d w7: lt.rect(7)
        property vector4d sA: Qt.vector4d(lt.starts[0], lt.starts[1], lt.starts[2], lt.starts[3])
        property vector4d sB: Qt.vector4d(lt.starts[4], lt.starts[5], lt.starts[6], lt.starts[7])
        fragmentShader: Qt.resolvedUrl("../../shaders/lanthorn.frag.qsb")
    }

    View3D {
        anchors.fill: parent
        visible: lt.t < lt.total
        camera: eye
        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Transparent
            antialiasingMode: SceneEnvironment.NoAA
        }

        OrthographicCamera {
            id: eye
            z: 600
        }

        Texture {
            id: stillTex
            sourceItem: lt.still
        }

        Model {
            source: "#Rectangle"
            instancing: RandomInstancing {
                instanceCount: Math.ceil(lt.width / lt.pitch) * Math.ceil(lt.height / lt.pitch)
                gridSpacing: Qt.vector3d(0, 0, 0)
                position: InstanceRange {
                    from: Qt.vector3d(-1, -1, 0)
                    to: Qt.vector3d(1, 1, 0)
                }
            }
            materials: CustomMaterial {
                shadingMode: CustomMaterial.Unshaded
                sourceBlend: CustomMaterial.One
                destinationBlend: CustomMaterial.One
                depthDrawMode: Material.NeverDepthDraw
                cullMode: Material.NoCulling
                property vector2d grid: Qt.vector2d(Math.ceil(lt.width / lt.pitch), Math.ceil(lt.height / lt.pitch))
                property real pitch: lt.pitch
                property vector2d res: Qt.vector2d(lt.width, lt.height)
                property vector2d lamp: Qt.vector2d(lt.lamp.x, lt.lamp.y)
                property real t: lt.t
                property real span: lt.span
                property real mlife: lt.life
                property real back: lt.back ? 1 : 0
                property real gain: lt.back ? 0.45 : 0.6
                property color warm: lt.warm
                property vector4d w0: lt.rect(0)
                property vector4d w1: lt.rect(1)
                property vector4d w2: lt.rect(2)
                property vector4d w3: lt.rect(3)
                property vector4d w4: lt.rect(4)
                property vector4d w5: lt.rect(5)
                property vector4d w6: lt.rect(6)
                property vector4d w7: lt.rect(7)
                property vector4d sA: Qt.vector4d(lt.starts[0], lt.starts[1], lt.starts[2], lt.starts[3])
                property vector4d sB: Qt.vector4d(lt.starts[4], lt.starts[5], lt.starts[6], lt.starts[7])
                property TextureInput still: TextureInput {
                    texture: stillTex
                }
                vertexShader: "shaders/mote.vert"
                fragmentShader: "shaders/mote.frag"
            }
        }
    }
}
