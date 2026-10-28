#include "core/AssetsInternal.hpp"
#include "core/globals.hpp"

#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/debug/log/Logger.hpp>

#include <cstdlib>
#include <unordered_map>

namespace {
    std::unordered_map<std::string, SP<Render::ITexture>> textures;
}

namespace Assets {
    std::string assetDir() {
        const std::string DIR{g_glass->assets->value()};
        const char*       home = std::getenv("HOME");
        return DIR.starts_with("~/") && home ? std::string{home} + DIR.substr(1) : DIR;
    }

    SP<Render::ITexture> upload(cairo_surface_t* surface) {
        cairo_surface_flush(surface);
        auto tex = g_pHyprRenderer->createTexture(surface);
        cairo_surface_destroy(surface);
        return tex;
    }
}

SP<Render::ITexture> Assets::texture(const std::string& rel) {
    if (const auto IT = textures.find(rel); IT != textures.end())
        return IT->second;

    const auto PATH    = assetDir() + "/" + rel;
    auto*      surface = cairo_image_surface_create_from_png(PATH.c_str());
    if (cairo_surface_status(surface) != CAIRO_STATUS_SUCCESS) {
        LOG(Log::ERR, "[vitrail] cannot read {}", PATH);
        cairo_surface_destroy(surface);
        return textures[rel] = nullptr;
    }
    return textures[rel] = upload(surface);
}

void Assets::clear() {
    kits.clear();
    textures.clear();
    emblems.clear();
    plates.clear();
}
