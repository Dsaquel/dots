import json
import os
import select
import signal
import sys
import termios
import time
from pathlib import Path

from .compose import her_of
from .kitty import IMG, apc, b64, png_size
from .place import page_items, place_items
from .spans import cells, fit_spans
from .style import draw
from .term import ESC, at, release, reserve, write

FPS = 60
RING = 8
AHEAD = 4
SETTLE = 0.18
JITTER = 0.07
INK = "dim"


def fits(lay, hm, cols, lines, cw, ch):
    return lay["her"]["x"] + hm["extent"][0] <= cols * cw and stage(lay, hm, ch) < lines


def stage(lay, hm, ch):
    return max(lay["height"], -(-(lay["her"]["y"] + hm["extent"][1]) // ch))


class Show:
    def __init__(self, lay, sprite_dir, meta):
        self.lay, self.dir = lay, sprite_dir
        self.cw, self.ch = meta["cell"]
        hm = her_of(meta, lay["name"])
        self.hm, self.frames, self.fps = hm, hm["frames"], hm["fps"]
        self.items = page_items(lay, self.cw, self.ch)
        self.out, self.sent, self.ticks, self.work, self.skip = [], 0, 0, 0.0, False
        self.ahead, self.shown, self.placed, self.loaded = 0, None, 0, set()
        self.plan()

    def when(self, x, y):
        writ = self.hm.get("written")
        if not writ:
            return self.hm["cues"]["light"][0] + 0.3
        t, b = writ["t"], writ["block"]
        row = min(len(t) - 1, max(0, int((y - self.lay["her"]["y"]) // b)))
        return t[row][min(len(t[0]) - 1, max(0, int((x - self.lay["her"]["x"]) // b)))]

    def written_at(self, x, y):
        if x < self.lay["her"]["x"]:
            return -1.0
        return self.when(x, y) + JITTER * ((round(y) * 7919 + round(x) * 104729) % 1000 / 1000)

    def plan(self):
        cw, ch = self.cw, self.ch
        self.cells = []
        for tt in self.lay["texts"]:
            col = tt["col"]
            k = 2 if tt.get("tall") else 1
            for text_, style in fit_spans(tt):
                for c in text_:
                    w = cells(c) * k
                    if c != " ":
                        at_ = self.written_at(col * cw + w * cw / 2, tt["row"] * ch + ch * k / 2)
                        self.cells.append({"t": at_, "row": tt["row"], "col": col, "c": c, "style": style, "tall": k == 2, "stage": 0})
                    col += w
        self.cells.sort(key=lambda c: c["t"])
        self.reveal = []
        for k, it in enumerate(self.items):
            if it["kind"] != "page" or it["z"] == -3:
                continue
            w, h = png_size(self.dir / it["name"])
            sx, sy, sw, sh = it["crop"] or (0, 0, w, h)
            x0, y0 = it["col"] * cw + it["x"], it["row"] * ch + it["y"]
            strips = [{"k": k, "t": min(self.written_at(x0 + bx + min(cw, sw - bx) / 2, y0 + by + min(ch, sh - by) / 2) for by in range(0, sh, ch))
                       if x0 >= self.lay["her"]["x"] else -1.0, "src": (sx + bx, sy, min(cw, sw - bx), sh), "x": x0 + bx, "y": y0}
                      for bx in range(0, sw, cw)]
            self.reveal += strips if it["z"] < 0 else [dict(strips[0], t=sorted(r["t"] for r in strips)[len(strips) // 2], src=(sx, sy, sw, sh))]
        self.reveal.sort(key=lambda r: r["t"])
        done = max([c["t"] for c in self.cells] + [r["t"] for r in self.reveal] + [0])
        self.end = max(self.hm["seconds"], done + SETTLE + 0.05)
        self.beats = {"light": self.hm["cues"]["light"], "first": next((c["t"] for c in self.cells if c["t"] >= 0), None),
                      "written": round(done, 3), "end": round(self.end, 3)}

    def send(self):
        self.out.append(apc(f"a=t,t=f,f=100,i={IMG["clip"] + self.ahead % RING}", b64(str(self.dir / self.frames[self.ahead][0]))))
        self.ahead += 1

    def tick_her(self, t):
        n = len(self.frames)
        k = min(n - 1, int(t * self.fps))
        if k != self.shown:
            self.place(k)
        while self.ahead < min(n, k + AHEAD + 1):
            self.send()

    def place(self, k):
        if self.ahead <= k:
            self.ahead = k
            self.send()
        name, fx, fy = self.frames[k]
        x, y = self.lay["her"]["x"] + fx, self.lay["her"]["y"] + fy
        w, h = png_size(self.dir / name)
        src = (max(0, -x), max(0, -y), w - max(0, -x), h - max(0, -y))
        x, y = max(0, x), max(0, y)
        (row, Y), (col, X) = divmod(y, self.ch), divmod(x, self.cw)
        self.out.append(at(row, col) + apc(f"a=p,i={IMG["clip"] + k % RING},p=1,X={X},Y={Y},z=-2,C=1,x={src[0]},y={src[1]},w={src[2]},h={src[3]}"))
        if self.shown is not None and self.shown % RING != k % RING:
            self.out.append(apc(f"a=d,d=I,i={IMG["clip"] + self.shown % RING}"))
        self.shown = k

    def tick_text(self, t):
        for c in self.cells:
            if c["t"] > t:
                break
            stage = 2 if t >= c["t"] + SETTLE else 1
            if stage != c["stage"]:
                c["stage"] = stage
                style = c["style"] if stage == 2 else ("s2|" + INK if c["tall"] else INK)
                self.out.append(at(c["row"], c["col"]) + draw([(c["c"], style)]))

    def tick_items(self, t):
        while self.placed < len(self.reveal) and self.reveal[self.placed]["t"] <= t:
            r = self.reveal[self.placed]
            it = self.items[r["k"]]
            iid = IMG["page"] + r["k"]
            if iid not in self.loaded:
                self.out.append(apc(f"a=t,t=f,f=100,i={iid}", b64(str(self.dir / it["name"]))))
                self.loaded.add(iid)
            (row, Y), (col, X) = divmod(r["y"], self.ch), divmod(r["x"], self.cw)
            sx, sy, sw, sh = r["src"]
            self.placed += 1
            self.out.append(at(row, col) + apc(f"a=p,i={iid},p={self.placed},X={X},Y={Y},z={it["z"]},C=1,x={sx},y={sy},w={sw},h={sh}"))

    def first(self):
        self.out.append(reserve(stage(self.lay, self.hm, self.ch)))
        self.out += place_items([it for it in self.items if it["kind"] == "page" and it["z"] == -3], self.dir, IMG["page"] + 100)
        self.tick_her(0.0)
        self.tick_items(0.0)
        self.tick_text(0.0)

    def flush(self):
        if self.out:
            data = f"{ESC}[?2026h" + "".join(self.out) + f"{ESC}8{ESC}[?2026l"
            write(data)
            self.sent += len(data)
            self.out = []

    def finish(self, t):
        h = self.lay["height"]
        out = [apc(f"a=d,d=I,i={IMG["clip"] + k}") for k in range(RING)]
        out += [apc(f"a=d,d=I,i={IMG["page"] + k}") for k in range(len(self.items) + 160)]
        out += [at(r, 0) + f"{ESC}[2K" for r in range(h)]
        out += [at(t_["row"], t_["col"]) + draw(fit_spans(t_)) for t_ in self.lay["texts"]]
        out += place_items(self.items, self.dir)
        write(f"{ESC}[?2026h" + "".join(out) + release(h) + f"{ESC}[?2026l")
        if os.environ.get("GLASSHOUSE_FETCH_STATS"):
            Path(os.environ["GLASSHOUSE_FETCH_STATS"]).write_text(json.dumps({"ended": round(t, 3), "skipped": self.skip, "bytes": self.sent,
                                                                             "ticks": self.ticks, "work_ms": round(self.work * 1000, 1),
                                                                             "beats": self.beats}))

    def run(self):
        infd = sys.stdin.fileno()
        saved = termios.tcgetattr(infd) if os.isatty(infd) else None
        if saved:
            mode = termios.tcgetattr(infd)
            mode[3] &= ~(termios.ICANON | termios.ECHO)
            termios.tcsetattr(infd, termios.TCSANOW, mode)
        previous = signal.signal(signal.SIGINT, lambda *_: setattr(self, "skip", True))
        t0 = time.perf_counter()
        try:
            self.first()
            self.flush()
            while not self.skip:
                t = time.perf_counter() - t0
                if t >= self.end:
                    break
                if saved and select.select([infd], [], [], 0)[0]:
                    self.skip = True
                    break
                w0 = time.perf_counter()
                self.tick_her(t)
                self.tick_items(t)
                self.tick_text(t)
                self.flush()
                self.work += time.perf_counter() - w0
                self.ticks += 1
                time.sleep(max(0.0, t0 + (int(t * FPS) + 1) / FPS - time.perf_counter()))
        finally:
            self.finish(time.perf_counter() - t0)
            if saved:
                termios.tcsetattr(infd, termios.TCSANOW, saved)
            signal.signal(signal.SIGINT, previous)
