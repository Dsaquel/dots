import os
from datetime import timedelta

from .env import safe
from .her import her_line
from .house import letters
from .sky import lunar_phase, moon_words, sky, sun_times
from .system import clean_cpu, clean_gpu, gib, share, shell_name, span, terminal_name, thousands

PLANETS = [("☽", "moon", "silver"), ("♂", "mars", "iron"), ("☿", "mercury", "quicksilver"), ("♃", "jupiter", "tin"),
           ("♀", "venus", "copper"), ("♄", "saturn", "lead"), ("☉", "sun", "gold")]


def facts(f, w, now, live, settings):
    t, cpu, mem = f.get("Title") or {}, f.get("CPU") or {}, f.get("Memory") or {}
    disks = [d for d in f.get("Disk") or [] if d.get("mountpoint") in ("/", "/home")]
    ip = next((i for i in f.get("LocalIp") or [] if i.get("ipv4")), None)
    gpu = (f.get("GPU") or [{}])[0]
    pk = f.get("Packages") or {}
    wm = f.get("WM") or {}
    up = lambda: (f.get("Uptime") or {}).get("uptime", 0) // 60000
    light, nxt, outside = sky(now)
    phase = lunar_phase(now)
    moon, lit = moon_words(phase)
    today, unread = letters()
    cores = (cpu.get("cores") or {}).get("online") or os.cpu_count() or 1
    load = os.getloadavg()[0]
    used = lambda d: d["bytes"]["total"] - d["bytes"]["free"]
    total = lambda d: d["bytes"]["total"]
    sep = lambda: (" · ", "dim")
    words = {"working": "brewing", "needs": "waits for you", "idle": "resting", "done": "done"}
    brew = {}
    for a in live:
        k = (a["label"], words.get(a.get("state"), a.get("state")))
        brew[k] = brew.get(k, 0) + 1
    athanor = ([x for i, ((label, state), n) in enumerate(list(brew.items())[-3:]) for x in ([sep()] if i else [])
                + [(label + (f" ×{n}" if n > 1 else ""), "fg"), (" " + state, "dim")]] or [("nothing on the fire", "dim")])
    row = lambda glyph, name, style, value, src=(): {"glyph": glyph, "name": name, "style": style, "value": safe(value, [("unreadable", "dim")]),
                                                     "from": list(src)}
    freq = lambda: (cpu.get("frequency") or {}).get("max", 0) / 1000
    pct = lambda: round(100 * mem.get("used", 0) / max(1, mem.get("total", 1)))
    kernel = (f.get("Kernel") or {}).get("release", "")
    rows = {
        "sky": row("☉" if w == "light" else "☽", w, "sky",
                   lambda: [(light, "fg"), sep(), (nxt, "fg")] + ([sep(), (outside, "dim")] if outside else [])),
        "moon": row("◐", "moon", "moon", lambda: [(moon, "fg"), sep(), (f"{lit} % lit", "dim")]),
        "athanor": row("⚗", "athanor", "athanor", lambda: athanor),
        "letters": row("✉", "letters", "letters", lambda: [(f"{len(today)} today", "fg"), sep(),
                                                          ((f"{len(unread)} unread" if unread else "all read"), "dim")]),
        "awake": row("⧗", "awake", "awake", lambda: [(span(up()), "fg"), sep(), (f"since {now - timedelta(minutes=up()):%H:%M}", "dim")], ["uptime"]),
        "fire": row("🜂", "fire", "fire", lambda: [(clean_cpu(cpu.get("cpu")), "fg"), sep(), (f"{cores} cores", "dim"), sep(), (f"{freq():.1f} GHz", "dim")]
                    + ([sep(), (f"{round(cpu["temperature"])} °C", "fg")] if cpu.get("temperature") else [])
                    + [sep(), (f"load {load:.1f}", "dim")], ["cpu"]),
        "water": row("🜄", "water", "water", lambda: [(share(mem.get("used", 0), mem.get("total", 0)), "fg"),
                     (f" of {gib(mem.get("total", 0))}", "dim"), sep(), (f"{pct()} %", "fg")], ["memory", "swap"]),
        "earth": row("🜃", "earth", "earth", lambda: [x for i, d in enumerate(disks) for x in ([sep()] if i else [])
                     + [(share(used(d), total(d)), "fg"), (f" of {gib(total(d))} on {d["mountpoint"]}", "dim")]], ["disk"]),
        "air": row("🜁", "air", "air", lambda: [(ip.get("name", ""), "dim"), (" ", "dim"), (ip.get("ipv4", "").split("/")[0], "fg")]
                   if ip else [("no link", "dim")], ["localip", "locale"]),
        "aether": row("✧", "aether", "aether", lambda: [(clean_gpu(gpu.get("name")), "fg")]
                      + ([sep(), (f"{round(gpu["temperature"])} °C", "fg")] if gpu.get("temperature") else []), ["gpu"]),
        "mercury": row("☿", "mercury", "mercury", lambda: [(f"linux {kernel}", "fg")], ["kernel"]),
        "sulphur": row("🜍", "sulphur", "sulphur", lambda: [(f"{wm.get("prettyName", "").lower()} {wm.get("version", "")}".strip(), "fg"),
                       sep(), (shell_name(), "dim"), sep(), (terminal_name(), "dim")], ["wm", "shell", "terminal"]),
        "salt": row("🜔", "salt", "salt", lambda: [((f.get("OS") or {}).get("prettyName", "linux").lower(), "fg"), sep(),
                    (f"{thousands(pk.get("all", 0))} packages", "dim")], ["os", "packages", "host"]),
    }
    return {
        "world": w, "user": t.get("userName", "you"), "title": "硝子の聖堂", "day": now.strftime("%A").lower(),
        "date": now.strftime("%-d %B").lower(), "time": now.strftime("%H:%M"), "planet": PLANETS[now.weekday()],
        "names": ("月", "rubedo dark") if w == "dark" else ("陽", "rubedo light"), "rows": rows,
        "her": her_line(w, now, live, settings), "phase": phase, "lit": lit, "hour": now.hour + now.minute / 60,
        "sun": tuple(d.hour + d.minute / 60 for d in sun_times(now)),
        "levels": {"fire": min(1.0, load / cores), "water": safe(lambda: mem.get("used", 0) / max(1, mem.get("total", 1)), 0.0),
                   "earth": safe(lambda: used(disks[0]) / max(1, total(disks[0])), 0.0)},
    }
