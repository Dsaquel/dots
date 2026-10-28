#include "core/AssetsInternal.hpp"
#include "core/globals.hpp"

#include <hyprland/src/debug/log/Logger.hpp>

#include <cairo/cairo.h>
#include <librsvg/rsvg.h>

#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <ranges>
#include <unordered_map>
#include <vector>

namespace {
    std::unordered_map<std::string, std::string> icons;
}

std::vector<std::string> Assets::dataRoots() {
    const char*              home  = std::getenv("HOME");
    const char*              local = std::getenv("XDG_DATA_HOME");
    const char*              dirs  = std::getenv("XDG_DATA_DIRS");
    std::vector<std::string> roots;
    roots.push_back(local && *local ? std::string{local} : std::string{home ? home : ""} + "/.local/share");
    const std::string ALL = dirs && *dirs ? dirs : "/usr/local/share:/usr/share";
    for (const auto PART : std::views::split(ALL, ':'))
        roots.emplace_back(PART.begin(), PART.end());
    return roots;
}

static std::string iconTheme() {
    const char*   home   = std::getenv("HOME");
    const char*   config = std::getenv("XDG_CONFIG_HOME");
    std::ifstream file((config && *config ? std::string{config} : std::string{home ? home : ""} + "/.config") + "/gtk-3.0/settings.ini");
    std::string   theme;
    for (std::string line; std::getline(file, line);) {
        if (line.starts_with("gtk-icon-theme-name="))
            theme = line.substr(20);
    }
    return theme.empty() ? "hicolor" : theme;
}

static std::vector<std::string> themeChain(const std::vector<std::string>& roots) {
    std::vector<std::string> chain{iconTheme()};
    for (size_t i = 0; i < chain.size() && chain.size() < 8; ++i) {
        for (const auto& root : roots) {
            std::ifstream index(root + "/icons/" + chain[i] + "/index.theme");
            for (std::string line; index && std::getline(index, line);) {
                if (!line.starts_with("Inherits="))
                    continue;
                for (const auto PART : std::views::split(line.substr(9), ',')) {
                    const std::string NAME{PART.begin(), PART.end()};
                    if (!NAME.empty() && std::ranges::find(chain, NAME) == chain.end())
                        chain.push_back(NAME);
                }
            }
        }
    }
    if (std::ranges::find(chain, "hicolor") == chain.end())
        chain.emplace_back("hicolor");
    return chain;
}

std::string Assets::iconPath(const std::string& icon) {
    if (const auto IT = icons.find(icon); IT != icons.end())
        return IT->second;
    if (icon.starts_with("/"))
        return icons[icon] = std::filesystem::exists(icon) ? icon : "";

    const auto ROOTS = dataRoots();
    for (const auto& theme : themeChain(ROOTS)) {
        for (const auto& root : ROOTS) {
            for (const auto* sub : {"48x48/apps", "64x64/apps", "scalable/apps", "96x96/apps", "128x128/apps", "256x256/apps", "32x32/apps"}) {
                for (const auto* ext : {".svg", ".png"}) {
                    const auto PATH = root + "/icons/" + theme + "/" + sub + "/" + icon + ext;
                    if (std::filesystem::exists(PATH))
                        return icons[icon] = PATH;
                }
            }
        }
    }
    for (const auto* ext : {".svg", ".png"}) {
        const auto PATH = std::string{"/usr/share/pixmaps/"} + icon + ext;
        if (std::filesystem::exists(PATH))
            return icons[icon] = PATH;
    }
    return icons[icon] = "";
}

SP<Render::ITexture> Assets::emblemIcon(const std::string& icon) {
    const auto KEY = "icon|" + icon;
    if (const auto IT = emblems.find(KEY); IT != emblems.end())
        return IT->second;

    const auto START = std::chrono::steady_clock::now();
    const auto PATH  = iconPath(icon);
    if (PATH.empty())
        return emblems[KEY] = nullptr;

    auto* surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 44, 44);
    auto* cr      = cairo_create(surface);
    bool  drawn   = false;
    if (PATH.ends_with(".svg")) {
        GError* error  = nullptr;
        auto*   handle = rsvg_handle_new_from_file(PATH.c_str(), &error);
        if (handle) {
            const RsvgRectangle VIEW{2, 2, 40, 40};
            drawn = rsvg_handle_render_document(handle, cr, &VIEW, &error);
            g_object_unref(handle);
        }
        if (error)
            g_error_free(error);
    } else {
        auto* png = cairo_image_surface_create_from_png(PATH.c_str());
        if (cairo_surface_status(png) == CAIRO_STATUS_SUCCESS && cairo_image_surface_get_width(png) > 0) {
            cairo_translate(cr, 2, 2);
            cairo_scale(cr, 40.0 / cairo_image_surface_get_width(png), 40.0 / cairo_image_surface_get_height(png));
            cairo_set_source_surface(cr, png, 0, 0);
            cairo_paint(cr);
            drawn = true;
        }
        cairo_surface_destroy(png);
    }
    cairo_destroy(cr);
    if (!drawn) {
        cairo_surface_destroy(surface);
        return emblems[KEY] = nullptr;
    }
    auto tex = upload(surface);
    if (g_glass->debug->value() > 0)
        LOG(Log::DEBUG, "[vitrail] crest icon {} from {} in {} us", icon, PATH,
                         std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::steady_clock::now() - START).count());
    return emblems[KEY] = tex;
}
