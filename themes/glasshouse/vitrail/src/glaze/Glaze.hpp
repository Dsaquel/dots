#pragma once

#include <hyprland/src/desktop/DesktopTypes.hpp>

namespace Glaze {
    void toggle(const PHLWORKSPACE& shown, const PHLMONITOR& monitor);
    void swipe(bool on);
    void pre(const PHLMONITOR& monitor);
    void stage(const PHLMONITOR& monitor);
    void exit();
    bool warm();
    void destroy();
}
