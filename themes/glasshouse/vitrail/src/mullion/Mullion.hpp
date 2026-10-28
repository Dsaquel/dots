#pragma once

#include "frame/FramePass.hpp"

#include <hyprland/src/desktop/DesktopTypes.hpp>
#include <hyprland/src/render/Framebuffer.hpp>

#include <optional>
#include <string>

namespace Mullion {
    bool open(const PHLWINDOW& born, const PHLWINDOW& giver, int side, float pace = 1.F);
    bool fits(const PHLWINDOW& born, const PHLWINDOW& giver, int side, const CBox& was);
    bool seat(const PHLWINDOW& born, const PHLWINDOW& giver, int side, const CBox& was, std::optional<CGlassPass::SData> ring, const SP<Render::IFramebuffer>& still, float lead,
              float pace);
    bool late(const PHLWINDOW& born);
    bool holds(const PHLWINDOW& window);
    void hush();
    void drop(const PHLWINDOW& window, bool keep = false);
    void pre(const PHLMONITOR& monitor);
    void stage(const PHLMONITOR& monitor);
    void style(const std::string& name);
    void exit();
    bool warm();
    void destroy();
}
