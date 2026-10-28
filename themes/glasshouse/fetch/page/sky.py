import math
import subprocess
import sys
import time
from datetime import datetime, timedelta

from .env import HOUSE, LATLON, read_json


def lunar_phase(when):
    rad = math.pi / 180
    t = (when.timestamp() / 86400 + 2440587.5 - 2451545.0) / 36525
    n = lambda x: (x % 360 + 360) % 360
    d = n(297.8501921 + 445267.1114034 * t)
    m = n(357.5291092 + 35999.0502909 * t)
    mp = n(134.9633964 + 477198.8675055 * t)
    e = d + 6.289 * math.sin(mp * rad) - 2.100 * math.sin(m * rad) + 1.274 * math.sin((2 * d - mp) * rad) \
        + 0.658 * math.sin(2 * d * rad) + 0.214 * math.sin(2 * mp * rad) + 0.110 * math.sin(d * rad)
    return n(e) / 360


def moon_words(phase):
    lit = (1 - math.cos(2 * math.pi * phase)) / 2
    waxing = phase < 0.5
    name = ("new moon" if lit < 0.03 else "full moon" if lit > 0.97
            else ("waxing" if waxing else "waning") + (" crescent" if lit < 0.4 else " gibbous" if lit > 0.6 else "")
            if lit < 0.4 or lit > 0.6 else "first quarter" if waxing else "last quarter")
    return name, round(lit * 100)


def sun_times(day, where=LATLON):
    if not where:
        return datetime(day.year, day.month, day.day, 7), datetime(day.year, day.month, day.day, 19)
    lat, lon = where
    rad = math.pi / 180
    noon = datetime(day.year, day.month, day.day, 12)
    n_day = round(noon.timestamp() / 86400 + 2440587.5 - 2451545.0 + 0.0008)
    js = n_day - lon / 360
    m = ((357.5291 + 0.98560028 * js) % 360 + 360) % 360
    c = 1.9148 * math.sin(m * rad) + 0.02 * math.sin(2 * m * rad) + 0.0003 * math.sin(3 * m * rad)
    lam = (m + c + 180 + 102.9372) % 360
    jt = 2451545.0 + js + 0.0053 * math.sin(m * rad) - 0.0069 * math.sin(2 * lam * rad)
    dec = math.asin(math.sin(lam * rad) * math.sin(23.44 * rad))
    cw = (math.sin(-0.833 * rad) - math.sin(lat * rad) * math.sin(dec)) / (math.cos(lat * rad) * math.cos(dec))
    w = math.acos(max(-1, min(1, cw))) / rad
    at = lambda j: datetime.fromtimestamp((j - 2440587.5) * 86400)
    return at(jt - w / 360), at(jt + w / 360)


SKY_URL = (f"https://api.open-meteo.com/v1/forecast?latitude={LATLON[0]}&longitude={LATLON[1]}&current=temperature_2m,weather_code,"
           "is_day&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset&timezone=auto&forecast_days=2") if LATLON else ""
REFRESH = (
    "import json, os, sys, time, urllib.request\n"
    "j = json.load(urllib.request.urlopen(sys.argv[1], timeout=8))\n"
    "w = {'fetched': int(time.time() * 1000), 'temp': j['current']['temperature_2m'], 'code': j['current']['weather_code'],\n"
    "     'day': j['current']['is_day'] == 1, 'hi': j['daily']['temperature_2m_max'][0], 'lo': j['daily']['temperature_2m_min'][0],\n"
    "     'sunrise': j['daily']['sunrise'], 'sunset': j['daily']['sunset']}\n"
    "open(sys.argv[2] + '.tmp', 'w').write(json.dumps(w))\n"
    "os.replace(sys.argv[2] + '.tmp', sys.argv[2])\n")


def refresh_weather(age_ms):
    stamp = HOUSE / ".fetch-weather"
    if not SKY_URL or age_ms < 30 * 60000 or (stamp.exists() and time.time() - stamp.stat().st_mtime < 30 * 60):
        return
    HOUSE.mkdir(parents=True, exist_ok=True)
    stamp.touch()
    subprocess.Popen([sys.executable, "-I", "-c", REFRESH, SKY_URL, str(HOUSE / "weather.json")], stdin=subprocess.DEVNULL,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


WEATHER = {0: "clear", 1: "mostly clear", 2: "partly cloudy", 3: "overcast", 45: "fog", 48: "fog"}


def weather_word(code):
    return WEATHER.get(code) or ("drizzle" if code <= 57 else "rain" if code <= 67 else "snow" if code <= 77
                                 else "showers" if code <= 82 else "snow showers" if code <= 86 else "thunderstorm")


def sky(now):
    rise, set_ = sun_times(now)
    m = timedelta(minutes=1)
    word = ("night" if now < rise - 40 * m or now > set_ + 40 * m else "blue hour" if now < rise or now > set_
            else "golden hour" if now < rise + 60 * m or now > set_ - 60 * m else "daylight")
    nxt = (f"sunrise {rise:%H:%M}" if now < rise else f"sunset {set_:%H:%M}" if now < set_
           else f"sunrise {sun_times(now + timedelta(days=1))[0]:%H:%M}")
    w = read_json(HOUSE / "weather.json", {}) or {}
    age = time.time() * 1000 - (w.get("fetched") or 0)
    refresh_weather(age)
    fresh = age < 90 * 60000
    outside = f"{weather_word(int(w.get("code", 0)))} {round(w["temp"])} °C" if fresh and "temp" in w else ""
    return word, nxt, outside
