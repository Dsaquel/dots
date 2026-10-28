import os
import struct
import sys
import termios

ESC = "\x1b"


def size():
    try:
        rows, cols, xp, yp = struct.unpack("HHHH", __import__("fcntl").ioctl(sys.stdout.fileno(), termios.TIOCGWINSZ, b"\0" * 8))
    except OSError:
        return 80, 24, 0, 0
    return cols, rows, (xp // cols if cols and xp else 0), (yp // rows if rows and yp else 0)


def at(row, col):
    return f"{ESC}8" + (f"{ESC}[{row}B" if row > 0 else "") + (f"{ESC}[{col}C" if col > 0 else "")


def reserve(height):
    return f"{ESC}[?25l" + "\n" * height + f"{ESC}[{height}A\r{ESC}7"


def release(height):
    return f"{ESC}8{ESC}[{height}B\r{ESC}[0m{ESC}[?25h"


def graphics_ok():
    kitty = os.environ.get("TERM") == "xterm-kitty" or "KITTY_WINDOW_ID" in os.environ
    remote = any(os.environ.get(k) for k in ("TMUX", "SSH_CONNECTION", "SSH_TTY", "STY"))
    return kitty and not remote and sys.stdout.isatty()


def write(text):
    data = text.encode()
    while data:
        n = os.write(sys.stdout.fileno(), data)
        data = data[n:]
