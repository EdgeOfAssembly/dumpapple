// dumpapple - Apple IIgs reverse-engineering tool
// image.h: loaded memory image (raw binary or relocated OMF load segments)
#pragma once
#include <cstdint>
#include <string>
#include <vector>

namespace da {

struct RelocNote {           // a patched location, kept for listing comments
    uint32_t offset;         // offset within segment
    uint8_t size;            // bytes patched
    int8_t shift;            // bit shift applied
    bool inter;              // interseg
    uint16_t targetSeg;      // segment number (interseg) or own
    uint32_t targetOff;      // offset in target segment
    bool resolved;
};

struct Segment {
    std::string name;        // SEGNAME (or "RAW")
    std::string loadName;
    uint16_t segnum = 1;
    uint16_t kind = 0;       // v2 KIND (v1 TYPE converted)
    uint32_t base = 0;       // load address chosen
    uint32_t entry = 0;      // ENTRY offset
    uint32_t org = 0;        // ORG field from header
    std::vector<uint8_t> data;   // loaded, relocated bytes (LENGTH bytes)
    std::vector<RelocNote> relocs;
    bool isCode() const { return (kind & 0x1F) == 0x00; }
};

struct Image {
    bool omf = false;
    int omfVersion = 0;
    std::vector<Segment> segs;
    std::vector<std::string> warnings;
    // flattened bytes in segment order (what --dump-image writes and --verify compares)
    std::vector<uint8_t> flat() const {
        std::vector<uint8_t> v;
        for (auto &s : segs) v.insert(v.end(), s.data.begin(), s.data.end());
        return v;
    }
};

} // namespace da
