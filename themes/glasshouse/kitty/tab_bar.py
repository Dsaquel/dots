from kitty.fast_data_types import Screen
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb, draw_title

LEFT, RIGHT = "", ""

def draw_tab(draw_data: DrawData, screen: Screen, tab: TabBarData, before: int, max_tab_length: int,
             index: int, is_last: bool, extra_data: ExtraData) -> int:
    bar = as_rgb(int(draw_data.default_bg))
    glass = as_rgb(draw_data.tab_bg(tab))
    ink = as_rgb(draw_data.tab_fg(tab))
    screen.cursor.fg, screen.cursor.bg = glass, bar
    screen.draw(LEFT)
    screen.cursor.fg, screen.cursor.bg = ink, glass
    screen.cursor.bold = tab.is_active
    screen.draw(f"{index} ")
    draw_title(draw_data, screen, tab, index, max(1, max_tab_length - 5))
    screen.cursor.bold = False
    screen.cursor.fg, screen.cursor.bg = glass, bar
    screen.draw(RIGHT)
    end = screen.cursor.x
    screen.cursor.fg = 0
    if end < screen.columns:
        screen.draw(" ")
    return end
