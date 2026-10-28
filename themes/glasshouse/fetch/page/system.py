import json
import os
import re
import subprocess
from pathlib import Path

MODULES = "title:os:kernel:uptime:packages:wm:cpu:gpu:memory:disk:localip:host:swap:locale"


def start_fastfetch():
    try:
        return subprocess.Popen(["fastfetch", "--format", "json", "-s", MODULES], stdout=subprocess.PIPE,
                                stderr=subprocess.DEVNULL, text=True)
    except OSError:
        return None


def join_fastfetch(proc):
    try:
        out = proc.communicate(timeout=3)[0] if proc else "[]"
        return {m["type"]: m["result"] for m in json.loads(out or "[]") if "result" in m}
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.communicate()
        return {}
    except ValueError:
        return {}


def gib(n):
    g = n / 2 ** 30
    return f"{g / 1024:.1f} TiB" if g >= 1000 else f"{g:.1f} GiB" if g < 100 else f"{g:.0f} GiB"


def share(part, whole):
    g = whole / 2 ** 30
    return f"{part / 2 ** 40:.1f}" if g >= 1000 else f"{part / 2 ** 30:.1f}" if g < 100 else f"{part / 2 ** 30:.0f}"


def thousands(n):
    return f"{n:,}"


def shell_name():
    try:
        return Path(f"/proc/{os.getppid()}/comm").read_text().strip()
    except OSError:
        return Path(os.environ.get("SHELL", "sh")).name


def terminal_name():
    return "kitty" if "KITTY_WINDOW_ID" in os.environ else os.environ.get("TERM_PROGRAM") or os.environ.get("TERM", "tty")


def clean_cpu(name):
    name = re.sub(r"\((R|TM|tm|r)\)", "", name or "")
    name = re.sub(r"\b(Intel|AMD|Core|CPU|Processor|\d+-Core|with Radeon Graphics)\b", "", name)
    return re.sub(r"\s+", " ", name).strip() or "unknown"


def clean_gpu(name):
    return re.sub(r"^(NVIDIA|AMD|Advanced Micro Devices, Inc\.|Intel)\s+", "", name or "").strip()


def span(minutes):
    minutes = int(minutes)
    days, hours, mins = minutes // 1440, minutes // 60 % 24, minutes % 60
    return f"{days} d {hours} h" if days else f"{hours} h {mins:02d} min" if hours else f"{mins} min"
