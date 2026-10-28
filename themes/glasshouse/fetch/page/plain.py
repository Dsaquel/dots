from .layout.listing import list_layout
from .system import shell_name, terminal_name


def plain(f):
    t, cpu, mem = f.get("Title") or {}, f.get("CPU") or {}, f.get("Memory") or {}
    disks = f.get("Disk") or []
    root = next((d for d in disks if d.get("mountpoint") == "/"), disks[0] if disks else None)
    db = (root or {}).get("bytes") or {}
    du, dt = db.get("total", 0) - db.get("free", 0), db.get("total", 0)
    ip = next((i for i in f.get("LocalIp") or [] if i.get("ipv4")), None)
    gpu = (f.get("GPU") or [{}])[0]
    pk = f.get("Packages") or {}
    sw = (f.get("Swap") or [{}])[0]
    up = (f.get("Uptime") or {}).get("uptime", 0) // 60000
    ver = lambda m: " ".join(x for x in ((f.get(m) or {}).get("prettyName"), (f.get(m) or {}).get("version")) if x)
    pct = lambda u, a: f"{round(100 * u / a) if a else 0}%"
    rows = [
        ("title", [(t.get("userName", "user"), "raw-key"), ("@", "raw"), (t.get("hostName", "host"), "raw-key")]),
        ("sep", [("-" * (len(t.get("userName", "user")) + len(t.get("hostName", "host")) + 1), "raw")]),
        ("os", "OS", f"{(f.get("OS") or {}).get("prettyName", "Linux")} {(f.get("Kernel") or {}).get("architecture", "")}"),
        ("host", "Host", (f.get("Host") or {}).get("name", "")),
        ("kernel", "Kernel", f"Linux {(f.get("Kernel") or {}).get("release", "")}"),
        ("uptime", "Uptime", f"{up // 60} hours, {up % 60} mins" if up >= 60 else f"{up} mins"),
        ("packages", "Packages", ", ".join(f"{v} ({k.replace("System", "")})" for k, v in pk.items() if k != "all" and v)),
        ("shell", "Shell", shell_name()),
        ("wm", "WM", f"{ver("WM")} ({(f.get("WM") or {}).get("protocolName", "")})"),
        ("terminal", "Terminal", terminal_name()),
        ("cpu", "CPU", f"{cpu.get("cpu", "")} ({(cpu.get("cores") or {}).get("online", "")}) @ {(cpu.get("frequency") or {}).get("max", 0) / 1000:.2f} GHz"),
        ("gpu", "GPU", f"{gpu.get("name", "")} [{gpu.get("type", "")}]"),
        ("memory", "Memory", f"{mem.get("used", 0) / 2 ** 30:.2f} GiB / {mem.get("total", 0) / 2 ** 30:.2f} GiB ({pct(mem.get("used", 0), mem.get("total", 0))})"),
        ("swap", "Swap", f"{sw.get("used", 0) / 2 ** 30:.2f} GiB / {sw.get("total", 0) / 2 ** 30:.2f} GiB ({pct(sw.get("used", 0), sw.get("total", 0))})"),
        ("disk", "Disk (/)", f"{du / 2 ** 30:.2f} GiB / {dt / 2 ** 30:.2f} GiB ({pct(du, dt)}) - {(root or {}).get("filesystem", "")}"),
        ("localip", f"Local IP ({(ip or {}).get("name", "lo")})", (ip or {}).get("ipv4", "")),
        ("locale", "Locale", f.get("Locale") or ""),
    ]
    return [{"id": r[0], "spans": r[1]} if len(r) == 2 else {"id": r[0], "spans": [(r[1], "raw-key"), (": " + str(r[2]), "raw")]}
            for r in rows if len(r) == 2 or r[2]]


def plain_text(F):
    lay = list_layout(F)
    rows = {}
    for t in lay["texts"]:
        rows.setdefault(t["row"], []).append(t)
    return "\n".join("  " + "  ".join("".join(s for s, _ in t["spans"]) for t in sorted(rows.get(r, []), key=lambda t: t["col"]))
                     for r in range(lay["height"])) + "\n"
