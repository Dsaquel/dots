#pragma once

#include <hyprland/src/render/Texture.hpp>
#include <hyprland/src/helpers/math/Math.hpp>

#include <array>
#include <string>
#include <utility>
#include <vector>

struct SPlateText {
    SP<Render::ITexture>                  tex;
    Vector2D                              origin;
    Vector2D                              size;
    double                                natural = 0;
    std::vector<std::pair<float, float>> letters;
};

struct SKit {
    SP<Render::ITexture>                glow, glass, lead, trim, parts;
    std::array<std::array<float, 4>, 4> axis   = {};
    std::array<std::array<float, 4>, 4> timing = {};
    std::array<float, 4>                bloom  = {};
};

namespace Assets {
    const SKit&          kit(const char* dir, int kind);
    SP<Render::ITexture> texture(const std::string& rel);
    SP<Render::ITexture> emblem(const std::string& text, bool glyph);
    SP<Render::ITexture> emblemIcon(const std::string& icon);
    std::string          iconPath(const std::string& icon);
    std::vector<std::string> dataRoots();
    const SPlateText&    plate(const std::string& app, const std::string& title, bool dark, double maxWidth, double scale);
    void                 clear();
}
