#pragma once
#include "image.h"
#include <map>

namespace da {
struct OmfOptions {
    uint32_t base = 0x020000;            // base of first non-absolute segment
    uint32_t stride = 0x010000;          // spacing between segment bases
    std::map<uint16_t, uint32_t> segBase; // explicit per-segnum bases
};
// Returns true if bytes look like an OMF v1/v2 file.
bool looksLikeOmf(const std::vector<uint8_t> &f);
// Parse + load + relocate. On failure returns false and fills err.
bool loadOmf(const std::vector<uint8_t> &f, const OmfOptions &o, Image &img, std::string &err);
}
