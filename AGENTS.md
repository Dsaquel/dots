# AGENTS.md

Arch + Hyprland dotfiles, stowed in layers: a theme-agnostic base, then one theme laid over it. The default theme, Glasshouse, is a whole desktop: a Quickshell shell of stained glass, a Hyprland plugin for window frames, a terminal page, and generators for its art, sounds and shaders. It lives in two worlds, dark and light.

- Layers stay apart: base never knows which theme sits on it, and machine-specific settings live outside the repo in local files the configs load when present.
- The shell runs live: editing it changes the running desktop. Risky work goes to a test instance first.
- Generated output is never committed or hand-edited: change the source or generator, then rebuild. The same holds for world switching: edit the dark/light sources, never the active outputs.
- World switching must be safe: every step that changes a file can roll back, and failures are never swallowed.
- The tty1 login starts Hyprland: keep that path working.
- Style: no comments except workarounds, dark/light naming, sizes relative to the screen, never literals.
