#include "core/AssetsInternal.hpp"

#include <cairo/cairo.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <deque>
#include <numeric>
#include <vector>

namespace {
    struct SParts {
        SP<Render::ITexture>                tex;
        std::array<std::array<float, 4>, 4> axis   = {};
        std::array<std::array<float, 4>, 4> timing = {};
        std::array<float, 4>                bloom  = {};
    };

    SParts partsOf(const std::string& path, const std::string& leadPath, const Vector2D& pivot) {
        auto* png = cairo_image_surface_create_from_png(path.c_str());
        if (cairo_surface_status(png) != CAIRO_STATUS_SUCCESS) {
            cairo_surface_destroy(png);
            return {};
        }
        const int  W = cairo_image_surface_get_width(png), H = cairo_image_surface_get_height(png), STRIDE = cairo_image_surface_get_stride(png);
        const auto ALPHA = [&](int x, int y) { return reinterpret_cast<const uint32_t*>(cairo_image_surface_get_data(png) + size_t(y) * STRIDE)[x] >> 24; };
        std::vector<int> label(size_t(W) * H, -1);
        std::vector<int> sizes;
        std::deque<int>  queue;
        for (int i = 0; i < W * H; ++i) {
            if (label[i] >= 0 || ALPHA(i % W, i / W) < 128)
                continue;
            const int ID = int(sizes.size());
            sizes.push_back(0);
            label[i] = ID;
            queue.push_back(i);
            while (!queue.empty()) {
                const int P = queue.front();
                queue.pop_front();
                ++sizes[ID];
                for (const auto& [dx, dy] : std::initializer_list<std::pair<int, int>>{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) {
                    const int X = P % W + dx, Y = P / W + dy;
                    if (X >= 0 && Y >= 0 && X < W && Y < H && label[Y * W + X] < 0 && ALPHA(X, Y) >= 128) {
                        label[Y * W + X] = ID;
                        queue.push_back(Y * W + X);
                    }
                }
            }
        }
        const int  PX = std::clamp(int(pivot.x * W), 0, W - 1), PY = std::clamp(int(pivot.y * H), 0, H - 1);
        const int  ROUNDEL = label[PY * W + PX];
        std::vector<int> order(sizes.size());
        std::iota(order.begin(), order.end(), 0);
        std::ranges::sort(order, [&](int a, int b) { return a == ROUNDEL ? b != ROUNDEL : (b == ROUNDEL ? false : sizes[a] > sizes[b]); });
        if (order.size() > 4)
            order.resize(4);
        std::vector<int> part(sizes.size(), -1);
        for (size_t k = 0; k < order.size(); ++k)
            part[order[k]] = int(k);
        std::vector<int> owner(size_t(W) * H, -1);
        for (int i = 0; i < W * H; ++i) {
            if (label[i] >= 0 && part[label[i]] >= 0) {
                owner[i] = part[label[i]];
                queue.push_back(i);
            }
        }
        while (!queue.empty()) {
            const int P = queue.front();
            queue.pop_front();
            for (const auto& [dx, dy] : std::initializer_list<std::pair<int, int>>{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) {
                const int X = P % W + dx, Y = P / W + dy;
                if (X >= 0 && Y >= 0 && X < W && Y < H && owner[Y * W + X] < 0) {
                    owner[Y * W + X] = owner[P];
                    queue.push_back(Y * W + X);
                }
            }
        }
        SParts out;
        const Vector2D CENTRE{PX + 0.5, PY + 0.5};
        for (size_t k = 0; k < order.size(); ++k) {
            Vector2D base = CENTRE, tip = CENTRE;
            double   near = 1e9, far = -1;
            for (int i = 0; i < W * H; ++i) {
                if (label[i] != order[k])
                    continue;
                const Vector2D P{i % W + 0.5, i / W + 0.5};
                if (const double D = P.distance(CENTRE); D < near) {
                    near = D;
                    base = P;
                }
            }
            for (int i = 0; i < W * H; ++i) {
                if (label[i] != order[k])
                    continue;
                const Vector2D P{i % W + 0.5, i / W + 0.5};
                if (const double D = P.distance(base); D > far) {
                    far = D;
                    tip = P;
                }
            }
            if (k == 0)
                base = tip = CENTRE;
            const auto   A     = tip - base;
            const double SWING = A.x * -1.0 - A.y * -1.0 > 0 ? 1.0 : -1.0;
            out.axis[k]        = {float(base.x / W), float(base.y / H), float(tip.x / W), float(tip.y / H)};
            out.timing[k]      = k == 0 ? std::array<float, 4>{0.F, 0.85F, 0.F, 0.F} :
                                          (k + 1 == order.size() && order.size() > 2 ? std::array<float, 4>{0.5F, 0.92F, float(SWING), 0.F} : std::array<float, 4>{0.12F, 0.72F, float(SWING), 0.F});
        }
        double disc = 0;
        for (int i = 0; i < W * H; ++i)
            if (label[i] == ROUNDEL)
                disc = std::max(disc, Vector2D{i % W + 0.5, i / W + 0.5}.distance(CENTRE));
        auto*  lead = cairo_image_surface_create_from_png(leadPath.c_str());
        double re = 0, im = 0;
        if (cairo_surface_status(lead) == CAIRO_STATUS_SUCCESS && cairo_image_surface_get_width(lead) == W && cairo_image_surface_get_height(lead) == H) {
            const auto* DATA = cairo_image_surface_get_data(lead);
            for (int i = 0; i < 720; ++i) {
                const double TH = i * M_PI / 360;
                const int    X = std::clamp(int(CENTRE.x + 0.95 * disc * std::cos(TH)), 0, W - 1), Y = std::clamp(int(CENTRE.y + 0.95 * disc * std::sin(TH)), 0, H - 1);
                const double A = double(reinterpret_cast<const uint32_t*>(DATA + size_t(Y) * cairo_image_surface_get_stride(lead))[X] >> 24);
                re += A * std::cos(5 * TH);
                im -= A * std::sin(5 * TH);
            }
        }
        cairo_surface_destroy(lead);
        out.bloom = {float(CENTRE.x / W), float(CENTRE.y / H), float(disc / W), float(-std::atan2(im, re) / 5)};
        auto* map = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, W, H);
        cairo_surface_flush(map);
        for (int y = 0; y < H; ++y) {
            auto* row = reinterpret_cast<uint32_t*>(cairo_image_surface_get_data(map) + size_t(y) * cairo_image_surface_get_stride(map));
            for (int x = 0; x < W; ++x)
                row[x] = 0xff000000U | (uint32_t(std::max(owner[y * W + x], 0) * 64) << 16);
        }
        cairo_surface_mark_dirty(map);
        cairo_surface_destroy(png);
        out.tex = Assets::upload(map);
        return out;
    }
}

const SKit& Assets::kit(const char* dir, int kind) {
    const auto KEY = std::string{dir} + char('0' + kind);
    if (const auto IT = kits.find(KEY); IT != kits.end())
        return IT->second;
    if (kind > 1)
        return kits[KEY] = SKit{.trim = texture("shared/pearl.png")};
    const auto STEM  = std::string{dir} + (kind == 0 ? "/chrome-corner" : "/chrome-crest");
    const auto PARTS = kind == 0 ? partsOf(assetDir() + "/" + STEM + ".png", assetDir() + "/" + STEM + "-lead.png", {36.0 / 120.0, 36.0 / 120.0}) : SParts{};
    return kits[KEY] = SKit{.glow   = texture(STEM + "-glow.png"),
                            .glass  = texture(STEM + ".png"),
                            .lead   = texture(STEM + "-lead.png"),
                            .trim   = texture(STEM + "-gilt.png"),
                            .parts  = PARTS.tex,
                            .axis   = PARTS.axis,
                            .timing = PARTS.timing,
                            .bloom  = PARTS.bloom};
}
