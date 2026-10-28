import QtQuick

ShaderEffect {
    id: impact

    required property var host
    required property var turn
    required property Item view

    anchors.fill: parent
    readonly property var c: impact.turn.clap
    readonly property bool lit: impact.host.main
    readonly property point palmClip: impact.turn.dawn ? Qt.point(616, 290) : Qt.point(616, 304)
    visible: impact.turn.running && c.on || impact.turn.warming
    property variant src: ShaderEffectSource { sourceItem: impact.view; live: impact.turn.running && impact.c.on || impact.turn.warming; hideSource: false; textureSize: impact.host.view }
    property variant frz: ShaderEffectSource { id: freeze; sourceItem: impact.view; live: false; hideSource: false; textureSize: impact.host.view }
    property size res: Qt.size(impact.host.sw / impact.host.u, impact.host.sh / impact.host.u)
    property point palm: Qt.point(impact.host.frame.x + palmClip.x * impact.host.frame.width / 1280, impact.host.frame.y + palmClip.y * impact.host.frame.height / 720)
    readonly property real sc: Math.max(0, c.ct)
    property point shake: Qt.point(c.amp * (0.75 * Math.sin(2 * Math.PI * 12.3 * sc + 1.2) + 0.3 * Math.sin(2 * Math.PI * 23.3 * sc + 2.0)),
                                   c.amp * 0.6 * (Math.cos(2 * Math.PI * 9.7 * sc) + 0.25 * Math.sin(2 * Math.PI * 27.1 * sc)))
    property real zoom: c.zoomV
    property real hold: c.held ? 1 : 0
    property real imp: c.n >= 1 && c.n <= 3 ? 1 : 0
    property real inv: c.n === 2 ? 1 : 0
    property real thrA: impact.turn.dawn ? 0.16 : 0.30
    property real thrB: impact.turn.dawn ? 0.40 : 0.52
    property real vig: c.n < 0 ? 0.25 * c.sstep(-0.45, -0.02) : 0
    property real ringR: c.n < 4 ? -200 : 1500 * (1 - Math.exp(-c.ringU / 0.16))
    property real ringW: 16 + 56 * (1 - Math.exp(-c.ringU / 0.2))
    property real ringI: !lit || c.n < 4 ? 0 : 1.3 * Math.exp(-c.ringU / 0.2)
    property real ringD: !lit || c.n < 4 ? 0 : 44 * Math.exp(-c.ringU / 0.28)
    property real split: 0.7
    property real ab: c.released ? 0.01 * Math.exp(-c.rel / 0.1) : 0
    property real blur: c.released && c.rel < 0.35 ? 0.04 * Math.exp(-c.rel / 0.06) : 0
    property real flash: !lit ? 0 : c.n === 4 ? 1.5 : c.n === 5 ? 0.3 : c.n === 6 ? 0.1 : 0
    property real flashR: 28
    property real sparkT: lit && c.released && c.rel < 0.95 ? c.rel + 0.001 : -1
    property real sparkI: 1.6
    property real lines: lit && c.released && c.rel < 0.16 ? 0.6 * (1 - c.rel / 0.16) : 0
    property real seed: c.n
    property color ink: impact.turn.ink
    property color gold: impact.turn.gold
    property color hot: impact.turn.hot
    property color warm: impact.turn.dawn ? impact.turn.warm : impact.turn.gold
    fragmentShader: Qt.resolvedUrl("shaders/clap_post.frag.qsb")

    Connections {
        target: impact.turn.clap
        function onOnset(): void {
            freeze.scheduleUpdate();
        }
    }
}
