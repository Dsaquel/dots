LINES = {
    "dark": {
        "rest": ["The moon keeps watch. The glass is quiet.", "Silver hours, and nothing on the fire.",
                 "I polished the flasks while you were away.", "Night is the best time to distil."],
        "thinking": ["{label} is simmering. I am watching the flame.", "Something brews in {label}. Patience."],
        "needs": ["{label} is asking for you.", "A flask in {label} waits for your hand."],
        "done": ["{label} is done. I bottled it for you.", "{label} cooled to silver. Come and see."],
        "sleepy": ["Shh. Do not disturb. I keep the letters."],
    },
    "light": {
        "rest": ["The sun is up, and so are the potions.", "Clear glass, bright fire. Let us begin.",
                 "Morning light makes everything transmute faster.", "The stained glass is warm today."],
        "thinking": ["{label} is on the fire. It smells like progress.", "{label} is bubbling nicely."],
        "needs": ["{label} needs you, before it boils over!", "Quick, {label} is calling for you."],
        "done": ["{label} turned to gold. Come and see.", "{label} is ready, still warm from the fire."],
        "sleepy": ["Do not disturb. I am sunbathing."],
    },
}


def mood(live, settings):
    if settings.get("dnd"):
        return "sleepy", None
    by = {s: [a for a in live if a.get("state") == s] for s in ("needs", "working", "done")}
    return next(((("thinking" if s == "working" else s), by[s][-1].get("label")) for s in ("needs", "working", "done") if by[s]), ("rest", None))


def her_line(w, now, live, settings):
    state, label = mood(live, settings)
    bank = LINES[w][state]
    return bank[now.timetuple().tm_yday % len(bank)].format(label=label or "a brew")
