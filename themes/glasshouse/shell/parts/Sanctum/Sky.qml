import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Scope {
    id: sky

    property var weather: null
    readonly property var latlon: (Quickshell.env("GLASSHOUSE_LATLON") || "").split(",")
    readonly property string url: sky.latlon.length === 2 ? `https://api.open-meteo.com/v1/forecast?latitude=${sky.latlon[0].trim()}&longitude=${sky.latlon[1].trim()}&current=temperature_2m,weather_code,is_day&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset&timezone=auto&forecast_days=2` : ""

    function refresh(): void {
        if (fetcher.running || !sky.url)
            return;
        if (!sky.weather || Date.now() - (sky.weather.fetched || 0) > 1800000)
            fetcher.running = true;
    }
    function absorb(text: string): void {
        let j;
        try {
            j = JSON.parse(text);
        } catch (e) {
            return;
        }
        if (!j || !j.current || !j.daily)
            return;
        const w = {
            fetched: Date.now(),
            temp: j.current.temperature_2m,
            code: j.current.weather_code,
            day: j.current.is_day === 1,
            hi: j.daily.temperature_2m_max[0],
            lo: j.daily.temperature_2m_min[0],
            sunrise: j.daily.sunrise,
            sunset: j.daily.sunset
        };
        sky.weather = w;
        cache.setText(JSON.stringify(w));
    }
    function about(code: int): var {
        if (code === 0)
            return { word: "Clear", day: "", night: "" };
        if (code <= 2)
            return { word: code === 1 ? "Mostly clear" : "Partly cloudy", day: "", night: "" };
        if (code === 3)
            return { word: "Overcast", day: "", night: "" };
        if (code <= 48)
            return { word: "Fog", day: "", night: "" };
        if (code <= 57)
            return { word: "Drizzle", day: "", night: "" };
        if (code <= 67)
            return { word: code >= 65 ? "Heavy rain" : "Rain", day: "", night: "" };
        if (code <= 77)
            return { word: "Snow", day: "", night: "" };
        if (code <= 82)
            return { word: "Showers", day: "", night: "" };
        if (code <= 86)
            return { word: "Snow showers", day: "", night: "" };
        return { word: "Thunderstorm", day: "", night: "" };
    }
    function nextSunEvent(now: var): var {
        if (!sky.weather || !sky.weather.sunrise || !sky.weather.sunset)
            return null;
        const t = now.getTime();
        const ev = [];
        for (const s of sky.weather.sunrise)
            ev.push({ kind: "sunrise", at: new Date(s) });
        for (const s of sky.weather.sunset)
            ev.push({ kind: "sunset", at: new Date(s) });
        const next = ev.filter(e => e.at.getTime() > t).sort((x, y) => x.at - y.at);
        return next.length ? next[0] : null;
    }
    function lunarPhase(date: var): real {
        const rad = Math.PI / 180;
        const T = (date.getTime() / 86400000 + 2440587.5 - 2451545.0) / 36525;
        const n = x => ((x % 360) + 360) % 360;
        const D = n(297.8501921 + 445267.1114034 * T);
        const M = n(357.5291092 + 35999.0502909 * T);
        const Mp = n(134.9633964 + 477198.8675055 * T);
        const e = D + 6.289 * Math.sin(Mp * rad) - 2.100 * Math.sin(M * rad) + 1.274 * Math.sin((2 * D - Mp) * rad) + 0.658 * Math.sin(2 * D * rad) + 0.214 * Math.sin(2 * Mp * rad) + 0.110 * Math.sin(D * rad);
        return n(e) / 360;
    }
    function moonLit(phase: real): real {
        return (1 - Math.cos(2 * Math.PI * phase)) / 2;
    }
    function moonName(phase: real): string {
        const lit = sky.moonLit(phase);
        const waxing = phase < 0.5;
        if (lit < 0.03)
            return "New moon";
        if (lit > 0.97)
            return "Full moon";
        if (lit < 0.4)
            return waxing ? "Waxing crescent" : "Waning crescent";
        if (lit <= 0.6)
            return waxing ? "First quarter" : "Last quarter";
        return waxing ? "Waxing gibbous" : "Waning gibbous";
    }

    FileView {
        id: cache
        path: Settings.dir + "/weather.json"
        printErrors: false
        onLoaded: {
            try {
                sky.weather = JSON.parse(text());
            } catch (e) {}
        }
    }
    Process {
        id: fetcher
        command: ["curl", "-sf", "--max-time", "8", sky.url]
        stdout: StdioCollector {
            onStreamFinished: sky.absorb(text)
        }
    }
}
