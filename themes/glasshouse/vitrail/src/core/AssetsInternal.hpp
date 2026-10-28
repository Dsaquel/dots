#pragma once

#include "core/Assets.hpp"

#include <cairo/cairo.h>

#include <string>
#include <unordered_map>

namespace Assets {
    inline std::unordered_map<std::string, SP<Render::ITexture>> emblems;
    inline std::unordered_map<std::string, SPlateText>           plates;
    inline std::unordered_map<std::string, SKit>                 kits;

    std::string          assetDir();
    SP<Render::ITexture> upload(cairo_surface_t* surface);
}
