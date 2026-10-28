#pragma once

#include <hyprland/src/desktop/DesktopTypes.hpp>
#include <hyprland/src/render/Framebuffer.hpp>
#include "core/Ring.hpp"

#include <optional>
#include <vector>

namespace Translation {
    inline constexpr float HASTE = 1;

    void take(const PHLWINDOW& window, const PHLWORKSPACE& to);
    void watch(const PHLMONITOR& monitor);
    void hush();
    void settle(const PHLMONITOR& monitor);
    bool carries(const PHLWINDOW& window);
    bool blaze(const PHLMONITOR& monitor);
    bool bound(const PHLWORKSPACE& workspace);
    std::optional<WORKSPACEID> holds(const PHLWORKSPACE& to);
    std::optional<WORKSPACEID> aims(const PHLWORKSPACE& to);
    Vector2D                   kick(const PHLMONITOR& monitor);
    void recue();
    bool reserves(const PHLWINDOW& window);
    std::vector<SP<Render::IFramebuffer>> before(const PHLWORKSPACE& workspace);
    void pre(const PHLMONITOR& monitor);
    void stage(const PHLMONITOR& monitor);
    void exit();
    bool warm();
    void destroy();
}
