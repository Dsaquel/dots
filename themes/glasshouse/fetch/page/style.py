from .term import ESC

SGR = {
    "fg": "39", "dim": "90", "ink": "97", "gold": "33", "jewel": "93", "rose": "91", "her": "3;95",
    "fire": "31", "water": "34", "earth": "32", "air": "36", "aether": "35",
    "mercury": "37", "sulphur": "33", "salt": "97", "athanor": "93", "letters": "95", "awake": "96",
    "sky": "33", "moon": "37", "raw-key": "1;34", "raw": "39", "title": "1;39", "rule": "90",
    "plaque": "1;30", "ribbon": "3;30", "rubric": "3;91", "day": "3;93",
}


def sgr(style):
    return f"{ESC}[0;{SGR.get(style, "39")}m"


def draw(spans):
    big = lambda text, style: sgr(style.partition("|")[2] or "title") + f"{ESC}]66;s=2;{text}\a"
    return "".join(big(text, style) if style.startswith("s2") else sgr(style) + text for text, style in spans) + f"{ESC}[0m"
