#include "core/AssetsInternal.hpp"

#include <cairo/cairo.h>
#include <pango/pangocairo.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <format>
#include <numeric>
#include <ranges>
#include <vector>

namespace {
    constexpr double PAD    = 12;
    constexpr double HEIGHT = 22;

    struct SSpan {
        std::string text;
        std::string family;
        int         weight   = 400;
        unsigned    color    = 0xffffff;
        double      dy       = 0;
        double      padLeft  = 0;
        double      padRight = 0;
        double      maxWidth = -1;
    };

    std::array<double, 3> hexToRGB(unsigned v) {
        return {double((v >> 16) & 0xff) / 255.0, double((v >> 8) & 0xff) / 255.0, double(v & 0xff) / 255.0};
    }

    cairo_t* context(cairo_surface_t* surface) {
        auto* cr = cairo_create(surface);
        auto* fo = cairo_font_options_create();
        cairo_font_options_set_antialias(fo, CAIRO_ANTIALIAS_GRAY);
        cairo_font_options_set_hint_style(fo, CAIRO_HINT_STYLE_SLIGHT);
        cairo_font_options_set_hint_metrics(fo, CAIRO_HINT_METRICS_ON);
        cairo_set_font_options(cr, fo);
        cairo_font_options_destroy(fo);
        return cr;
    }

    PangoLayout* layoutOf(cairo_t* cr, const SSpan& s, double px, double scale) {
        auto* layout = pango_cairo_create_layout(cr);
        auto* desc   = pango_font_description_new();
        pango_font_description_set_family(desc, s.family.c_str());
        pango_font_description_set_absolute_size(desc, px * scale * PANGO_SCALE);
        pango_font_description_set_weight(desc, PangoWeight(s.weight));
        const auto VARIATIONS = std::format("wght={}", s.weight);
        pango_font_description_set_variations(desc, VARIATIONS.c_str());
        pango_layout_set_font_description(layout, desc);
        pango_font_description_free(desc);
        pango_layout_set_text(layout, s.text.c_str(), -1);
        if (s.maxWidth >= 0) {
            pango_layout_set_width(layout, int(std::max(s.maxWidth, 0.0) * scale * PANGO_SCALE));
            pango_layout_set_ellipsize(layout, PANGO_ELLIPSIZE_MIDDLE);
        }
        return layout;
    }

    Vector2D extent(PangoLayout* layout, double scale) {
        int w = 0, h = 0;
        pango_layout_get_pixel_size(layout, &w, &h);
        return Vector2D{double(w), double(h)} / scale;
    }

    void clustersOf(PangoLayout* layout, double x0, double scale, std::vector<std::pair<float, float>>& out) {
        auto* iter = pango_layout_get_iter(layout);
        do {
            PangoRectangle ink, logical;
            pango_layout_iter_get_cluster_extents(iter, &ink, &logical);
            if (ink.width > 0)
                out.emplace_back(float(x0 + double(logical.x) / PANGO_SCALE / scale), float(x0 + double(logical.x + logical.width) / PANGO_SCALE / scale));
        } while (pango_layout_iter_next_cluster(iter));
        pango_layout_iter_free(iter);
    }

    double widthOf(cairo_t* cr, const SSpan& s, double scale) {
        auto*      layout = layoutOf(cr, s, 12, scale);
        const auto SIZE   = extent(layout, scale);
        g_object_unref(layout);
        return SIZE.x + s.padLeft + s.padRight;
    }

    std::vector<SSpan> spansOf(cairo_t* cr, const std::string& app, const std::string& title, bool dark, double maxWidth, double scale) {
        if (dark) {
            SSpan appSpan{.text = app, .family = "Outfit", .weight = 600, .color = 0xd9d6f4, .dy = 0.5};
            const double APPW  = widthOf(cr, appSpan, scale);
            std::vector<SSpan> out{appSpan};
            if (!app.empty() && !title.empty())
                out.push_back({.text = "  ·  ", .family = "Outfit", .weight = 400, .color = 0x8a92b8, .dy = 0.5, .padLeft = 2, .padRight = 2});
            SSpan titleSpan{.text = title, .family = "Outfit", .weight = 420, .color = 0xf1e8dc, .dy = 0.5};
            titleSpan.maxWidth = std::min(widthOf(cr, titleSpan, scale), maxWidth - 2 * PAD - APPW - 24);
            out.push_back(titleSpan);
            return out;
        }
        SSpan appSpan{.text = app, .family = "Dela Gothic One", .weight = 400, .color = 0xfff8ec, .dy = -0.5};
        const double APPW = widthOf(cr, appSpan, scale);
        std::vector<SSpan> out{
            {.text = "【", .family = "Dela Gothic One", .weight = 400, .color = 0xff5fae},
            appSpan,
            {.text = "】", .family = "Dela Gothic One", .weight = 400, .color = 0xff5fae},
        };
        if (!title.empty()) {
            SSpan titleSpan{.text = title, .family = "Manrope", .weight = 560, .color = 0xefe4ff, .dy = 0.5, .padLeft = 2};
            titleSpan.maxWidth = std::min(widthOf(cr, titleSpan, scale), maxWidth - 2 * PAD - APPW - 30);
            out.push_back(titleSpan);
        }
        return out;
    }
}

SP<Render::ITexture> Assets::emblem(const std::string& text, bool glyph) {
    const auto KEY = text + (glyph ? "|g" : "|m");
    if (const auto IT = emblems.find(KEY); IT != emblems.end())
        return IT->second;

    auto*      surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 44, 44);
    auto*      cr      = context(surface);
    auto*      layout  = layoutOf(cr, {.text = text, .family = glyph ? "Symbols Nerd Font Mono" : "Cinzel", .weight = 700}, 30, 1);
    const auto SIZE    = extent(layout, 1);
    cairo_set_source_rgba(cr, 1, 1, 1, 1);
    cairo_move_to(cr, (44 - SIZE.x) / 2, (44 - SIZE.y) / 2);
    pango_cairo_show_layout(cr, layout);
    g_object_unref(layout);
    cairo_destroy(cr);
    return emblems[KEY] = upload(surface);
}

const SPlateText& Assets::plate(const std::string& app, const std::string& title, bool dark, double maxWidth, double scale) {
    const auto KEY = std::format("{}|{}|{}|{:.0f}|{:.2f}", app, title, dark, maxWidth, scale);
    if (const auto IT = plates.find(KEY); IT != plates.end())
        return IT->second;
    if (plates.size() > 24)
        plates.clear();

    auto*      scratch = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 1, 1);
    auto*      measure = context(scratch);
    const auto SPANS   = spansOf(measure, app, title, dark, maxWidth, scale);
    const auto WIDTHS  = SPANS | std::views::transform([&](const SSpan& s) {
                            auto*      layout = layoutOf(measure, s, 12, scale);
                            const auto SIZE   = extent(layout, scale);
                            g_object_unref(layout);
                            return SIZE.x + s.padLeft + s.padRight;
                        });
    const double ROW   = std::accumulate(WIDTHS.begin(), WIDTHS.end(), 0.0);
    cairo_destroy(measure);
    cairo_surface_destroy(scratch);

    const double X0      = dark ? PAD : PAD - 4;
    const int    W       = int(std::ceil((X0 + ROW + 2) * scale));
    const int    H       = int(std::ceil(HEIGHT * scale));
    auto*        surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, std::max(W, 1), std::max(H, 1));
    auto*        cr      = context(surface);
    double       x       = X0;
    std::vector<std::pair<float, float>> letters;
    for (const auto& s : SPANS) {
        auto*      layout = layoutOf(cr, s, 12, scale);
        const auto SIZE   = extent(layout, scale);
        const auto C      = hexToRGB(s.color);
        cairo_set_source_rgba(cr, C[0], C[1], C[2], 1);
        cairo_move_to(cr, (x + s.padLeft) * scale, ((HEIGHT - SIZE.y) / 2 + s.dy) * scale);
        pango_cairo_show_layout(cr, layout);
        clustersOf(layout, x + s.padLeft, scale, letters);
        g_object_unref(layout);
        x += SIZE.x + s.padLeft + s.padRight;
    }
    cairo_destroy(cr);

    return plates[KEY] = SPlateText{.tex = upload(surface), .origin = {0, 0}, .size = {W / scale, H / scale}, .natural = ROW + 2 * PAD, .letters = letters};
}
