import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import qs.core
import qs.parts.Lancet

Item {
    id: today

    readonly property color gold: Theme.dark ? Theme.rare : "#e6c577"
    readonly property color dim: Theme.dark ? Theme.dim : "#bab9d4"
    readonly property color ink: Theme.dark ? Theme.ink : "#e8e7ee"
    readonly property color inkSoft: Theme.dark ? Theme.inkSoft : "#dcdbea"
    readonly property string face: "Outfit"
    readonly property string figures: "Gilda Display"
    readonly property var en: Qt.locale("en_GB")
    readonly property var w: Rite.sky.weather
    readonly property var about: today.w ? Rite.sky.about(today.w.code) : null
    readonly property real moon: Rite.sky.lunarPhase(clock.date)
    readonly property var sun: Rite.sky.nextSunEvent(clock.date)
    readonly property var p: Rite.player
    readonly property var at: Theme.dark ? ({
            numeral: [1400.75, 401.25, 130],
            column: 1548,
            month: [331, 15, 4.8],
            day: [1547.5, 360.5, 16],
            sky: [384, 1557.5, 18],
            temp: [1579.5, 390.75, 21],
            word: [1617.5, 389.75, 14],
            range: [1705.5, 389.75, 14],
            moon: [414.9, 1557.4, 17.5],
            phase: [1578, 420, 15],
            loz: [1409.1, 484.1, 57.5, 53],
            label: [1385, 607, 12, 2.6],
            cards: [1384, 621.5, 382, 44, 58.5],
            pill: [13.75, 10.25, 11.5, 26.25],
            name: [42.25, 20.1, 16],
            status: [41.75, 37, 11, 1.3],
            time: [13.25, 27.25, 14],
            house: [511, 596],
            play: [784, 939]
        }) : ({
            numeral: [1451, 421.75, 121.5],
            column: 1593,
            month: [355.5, 14, 4.6],
            day: [1591.75, 384.25, 16],
            sky: [408.3, 1602.1, 17],
            temp: [1622.5, 415.25, 21],
            word: [1658.75, 414.75, 13.5],
            range: [1744.5, 415, 13.5],
            moon: [440.4, 1603.25, 17],
            phase: [1622.5, 444.25, 14.5],
            loz: [1445.25, 508.3, 54.85, 56],
            label: [1428, 621.5, 12, 3.2],
            cards: [1428, 636, 364.5, 45.5, 60.25],
            pill: [14.5, 10.25, 10.5, 26.5],
            name: [42, 16, 16],
            status: [41.75, 37.25, 12, 0.6],
            time: [13.75, 27.5, 13],
            house: [535, 609],
            play: [805, 923]
        })
    readonly property var planets: [
        { glyph: "\u2609", name: "SOL", metal: "aurum, gold", line: "the sun's day" },
        { glyph: "\u263D", name: "LUNA", metal: "argentum, silver", line: "the moon's day" },
        { glyph: "\u2642", name: "MARS", metal: "ferrum, iron", line: "the day of Mars" },
        { glyph: "\u263F", name: "MERCURIUS", metal: "argentum vivum, quicksilver", line: "the day of Mercury" },
        { glyph: "\u2643", name: "IUPPITER", metal: "stannum, tin", line: "the day of Jupiter" },
        { glyph: "\u2640", name: "VENUS", metal: "cuprum, copper", line: "the day of Venus" },
        { glyph: "\u2644", name: "SATURNUS", metal: "plumbum, lead", line: "the day of Saturn" }
    ]
    readonly property int day: clock.date.getDay()
    readonly property var planet: today.planets[today.day]
    readonly property var caption: Rite.zone === "system" && today.lozenges[Rite.index] ? today.lozenges[Rite.index] : (Rite.zone === "volume" ? { label: "VOLUME", value: Gauges.sinkLabel } : { label: "", value: [today.netLozenge.value, today.btDevices.map(d => d.name).join(", "), today.sink ? Rite.label(today.sink) : ""].filter(v => v !== "").join("   ·   "), rest: true })

    anchors.fill: parent

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function tone(state: string): color {
        if (state === "needs")
            return today.gold;
        if (state === "working")
            return Theme.dark ? Theme.info : "#7dbbd4";
        if (state === "done")
            return Theme.dark ? Theme.ok : "#86dcae";
        return today.dim;
    }
    function pick(zone: string, i: int): void {
        Rite.zone = zone;
        Rite.index = i;
    }
    function isSel(zone: string, i: int): bool {
        return Rite.zone === zone && Rite.index === i;
    }
    function elapsed(ms: real): string {
        const m = Math.max(0, Math.round(ms / 60000));
        if (m < 1)
            return "now";
        if (m < 60)
            return m + " min";
        return Math.floor(m / 60) + " h " + String(m % 60).padStart(2, "0");
    }
    function ago(ms: real): string {
        const e = today.elapsed(ms);
        return e === "now" ? "just now" : e + " ago";
    }
    function clockOf(s: real): string {
        const t = Math.max(0, Math.floor(s));
        return Math.floor(t / 60) + ":" + String(t % 60).padStart(2, "0");
    }

    Almanac {
        owner: today
        watch: clock
    }
    Weather {
        owner: today
    }
    Luminary {
        owner: today
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var wifiNet: {
        for (const d of Networking.devices.values)
            if (d.type === DeviceType.Wifi)
                for (const n of d.networks.values)
                    if (n.connected)
                        return n;
        return null;
    }
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) || null
    readonly property var btDevices: Bluetooth.devices.values.filter(d => d.connected)
    readonly property var netLozenge: {
        const n = today.wifiNet;
        const wifiOff = Networking.wifiEnabled ? "" : "  ·  Wi-Fi off";
        if (n) {
            const q = Math.max(0, Math.min(3, Math.floor(n.signalStrength * 4)));
            return { glyph: ["\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"][q], on: true, value: "Wi-Fi  " + n.name + "  " + Math.round(n.signalStrength * 100) + " %" };
        }
        if (today.wired)
            return { glyph: "\u{f0200}", on: true, value: "Wired  " + today.wired.name + wifiOff };
        return { glyph: Networking.wifiEnabled ? "\u{f05a9}" : "\u{f05aa}", on: false, value: Networking.wifiEnabled ? "Wi-Fi on, not connected" : "offline, Wi-Fi off" };
    }
    readonly property var lozenges: [
        { key: "wifi", on: today.netLozenge.on, glyph: today.netLozenge.glyph, label: "NETWORK", value: today.netLozenge.value },
        { key: "bluetooth", on: !!Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled, glyph: today.btDevices.length ? "\u{f00b1}" : (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "\u{f00af}" : "\u{f00b2}"), label: "BLUETOOTH", value: !Bluetooth.defaultAdapter ? "no adapter" : (!Bluetooth.defaultAdapter.enabled ? "off" : (today.btDevices.length ? today.btDevices.map(d => d.name).join(", ") : "on, nothing connected")) },
        { key: "audio", on: !!today.sink, glyph: today.sink && /head|ear|buds|xm[0-9]/i.test(Rite.label(today.sink)) ? "\u{f02cb}" : "\u{f04c3}", label: "OUTPUT", value: today.sink ? Rite.label(today.sink) : "none" },
        { key: "night", on: Settings.nightLight, glyph: "\u{f0594}", label: "NIGHT LIGHT", value: Settings.nightLight ? "4300 K" : "off" },
        { key: "pointer", on: Settings.pointerDust, glyph: "\u{f0674}", label: "POINTER DUST", value: Settings.pointerDust ? "on, fast moves shed dust" : "off" },
        { key: "dnd", on: Settings.dnd, glyph: Settings.dnd ? "\u{f009b}" : "\u{f009a}", label: "DO NOT DISTURB", value: Settings.dnd ? "on, she sleeps" : "off" },
        { key: "sounds", on: !Settings.muted, glyph: Settings.muted ? "\u{f0581}" : "\u{f057e}", label: "SOUNDS", value: Settings.muted ? "muted" : "on" }
    ]

    Lozenges {
        owner: today
    }

    House {
        owner: today
    }

    Roster {
        owner: today
    }

    Column {
        x: today.at.cards[0]
        y: today.at.play[0] + (today.at.play[1] - today.at.play[0] - height) / 2
        width: today.at.cards[2]
        spacing: 12

        Rosary {
            owner: today
        }

        Player {
            owner: today
        }

        Week {
            owner: today
        }
    }
}
