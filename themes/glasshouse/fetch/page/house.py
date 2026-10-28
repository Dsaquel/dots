import re
import time
from datetime import datetime

from .env import HOUSE, read_json


def agents():
    now = time.time() * 1000
    found = [read_json(p) for p in sorted((HOUSE / "agents").glob("*.json"))]
    live = [a for a in found if a and a.get("sid") and now - a.get("updated", 0) < 86400000
            and (a.get("state") != "done" or now - a.get("updated", 0) < 600000)]
    for a in live:
        cwd = a.get("cwd") or ""
        label = cwd.split("/.claude/worktrees/")[0].rsplit("/", 1)[-1] + " agent" if "/.claude/worktrees/" in cwd else a.get("label") or "claude"
        a["label"] = re.sub(r"[\x00-\x1f\x7f-\x9f]", "", str(label))
    return sorted(live, key=lambda a: a.get("updated", 0))


def letters():
    box = read_json(HOUSE / "notifications.json", {}) or {}
    start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0).timestamp() * 1000
    today = [e for e in box.get("entries", []) if e.get("time", 0) >= start]
    unread = [e for e in box.get("entries", []) if e.get("time", 0) > box.get("seen", 0)]
    return today, unread
