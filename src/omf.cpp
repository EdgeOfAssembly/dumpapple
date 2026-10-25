// OMF v1/v2 load-file parser, loader and relocator.
// References: Apple IIgs GS/OS Reference appendix F, APW Reference ch.7,
// CiderPress2 OMF-notes.md.  Only load-file records are accepted.
#include "omf.h"
#include <algorithm>
#include <cstdio>

namespace da {

namespace {
struct Pending {
    size_t seg;          // index into img.segs
    uint32_t offset;     // patch offset in segment
    uint8_t size;
    int8_t shift;
    bool inter;
    uint16_t file;
    uint16_t segnum;     // target segnum (inter)
    uint32_t value;      // offset in target (or own) segment
    int superType = -1;  // SUPER subtype, value read from patch site
};

struct Reader {
    const std::vector<uint8_t> &f;
    size_t pos, end;
    bool ok = true;
    bool has(size_t n) const { return ok && pos <= end && end - pos >= n; }
    uint32_t u(int n) {
        if (!has((size_t)n)) { ok = false; return 0; }
        uint32_t v = 0;
        for (int i = 0; i < n; i++) v |= (uint32_t)f[pos + i] << (8 * i);
        pos += n;
        return v;
    }
};

uint32_t rd(const std::vector<uint8_t> &f, size_t at, int n) {
    uint32_t v = 0;
    for (int i = 0; i < n; i++) v |= (uint32_t)f[at + i] << (8 * i);
    return v;
}

std::string hex(uint32_t v) { char b[16]; snprintf(b, sizeof b, "$%X", v); return b; }
} // namespace

bool looksLikeOmf(const std::vector<uint8_t> &f) {
    if (f.size() < 0x30) return false;
    uint8_t ver = f[0x0F];
    if (ver != 1 && ver != 2) return false;
    if (f[0x0E] != 4 || f[0x20] != 0) return false;   // NUMLEN 4, little-endian
    uint32_t dispname = rd(f, 0x28, 2), dispdata = rd(f, 0x2A, 2);
    if (dispname < 0x2C || dispdata <= dispname || dispdata > f.size()) return false;
    uint32_t len = rd(f, 8, 4);
    return len <= 0x1000000;
}

bool loadOmf(const std::vector<uint8_t> &f, const OmfOptions &o, Image &img, std::string &err) {
    img = Image{};
    img.omf = true;
    std::vector<Pending> pend;
    size_t off = 0;
    while (off < f.size()) {
        if (f.size() - off < 0x2C) {
            // trailing padding (v1 files are block padded)
            bool zero = std::all_of(f.begin() + off, f.end(), [](uint8_t b) { return b == 0; });
            if (!zero) img.warnings.push_back("trailing garbage after last segment at " + hex(off));
            break;
        }
        uint8_t ver = f[off + 0x0F];
        uint32_t cnt = rd(f, off, 4);
        if (ver == 0 && cnt == 0) break; // zero padding
        if (ver != 1 && ver != 2) { err = "unsupported OMF version " + std::to_string(ver) + " at " + hex(off); return false; }
        if (f[off + 0x0E] != 4) { err = "NUMLEN != 4 at " + hex(off); return false; }
        if (f[off + 0x20] != 0) { err = "big-endian NUMSEX at " + hex(off); return false; }
        size_t remain = f.size() - off;
        uint64_t bytecnt = cnt;
        if (ver == 1 && (uint64_t)cnt * 512 <= remain) bytecnt = (uint64_t)cnt * 512;  // BLKCNT
        if (bytecnt < 0x2C || bytecnt > remain) { err = "bad segment byte count at " + hex(off); return false; }
        img.omfVersion = std::max(img.omfVersion, (int)ver);
        Segment s;
        uint32_t resspc = rd(f, off + 4, 4), length = rd(f, off + 8, 4);
        uint8_t lablen = f[off + 0x0D];
        if (ver == 1) { uint8_t t = f[off + 0x0C]; s.kind = (t & 0x1F) | ((t & 0xE0) << 8); }
        else s.kind = rd(f, off + 0x14, 2);
        s.org = rd(f, off + 0x18, 4);
        s.segnum = rd(f, off + 0x22, 2);
        s.entry = rd(f, off + 0x24, 4);
        uint32_t dispname = rd(f, off + 0x28, 2), dispdata = rd(f, off + 0x2A, 2);
        if (length > 0x1000000 || resspc > length) { err = "bad LENGTH/RESSPC in segment at " + hex(off); return false; }
        if (dispname + 10 > bytecnt || dispdata > bytecnt) { err = "bad DISPNAME/DISPDATA at " + hex(off); return false; }
        for (int i = 0; i < 10; i++) s.loadName += (char)f[off + dispname + i];
        while (!s.loadName.empty() && (s.loadName.back() == ' ' || s.loadName.back() == 0)) s.loadName.pop_back();
        size_t np = off + dispname + 10;
        size_t nlen = lablen;
        if (lablen == 0 && np < off + bytecnt) nlen = f[np++];
        for (size_t i = 0; i < nlen && np + i < off + dispdata; i++) s.name += (char)f[np + i];
        while (!s.name.empty() && (s.name.back() == ' ' || s.name.back() == 0)) s.name.pop_back();
        s.data.assign(length, 0);
        size_t segIndex = img.segs.size();
        std::vector<Pending> local;
        Reader r{f, off + dispdata, off + (size_t)bytecnt};
        uint32_t pc = 0;
        bool ended = false;
        auto put = [&](size_t from, uint32_t n) -> bool {
            if ((uint64_t)pc + n > length) { err = "data overruns LENGTH in segment " + s.name; return false; }
            std::copy(f.begin() + from, f.begin() + from + n, s.data.begin() + pc);
            pc += n;
            return true;
        };
        while (!ended) {
            uint32_t op = r.u(1);
            if (!r.ok) { err = "segment body truncated (no END) in " + s.name; return false; }
            if (op == 0x00) { ended = true; break; }
            if (op <= 0xDF) {
                if (!r.has(op)) { err = "CONST truncated"; return false; }
                if (!put(r.pos, op)) return false;
                r.pos += op;
                continue;
            }
            switch (op) {
            case 0xF2: { // LCONST
                uint32_t n = r.u(4);
                if (!r.has(n)) { err = "LCONST truncated"; return false; }
                if (!put(r.pos, n)) return false;
                r.pos += n;
                break;
            }
            case 0xF1: { // DS
                uint32_t n = r.u(4);
                if (!r.ok || (uint64_t)pc + n > length) { err = "DS overruns LENGTH"; return false; }
                pc += n; // already zero
                break;
            }
            case 0xE2: { // RELOC
                Pending p{segIndex, 0, 0, 0, false, 1, s.segnum, 0};
                p.size = r.u(1); p.shift = (int8_t)r.u(1); p.offset = r.u(4); p.value = r.u(4);
                if (!r.ok) { err = "RELOC truncated"; return false; }
                local.push_back(p);
                break;
            }
            case 0xF5: { // cRELOC
                Pending p{segIndex, 0, 0, 0, false, 1, s.segnum, 0};
                p.size = r.u(1); p.shift = (int8_t)r.u(1); p.offset = r.u(2); p.value = r.u(2);
                if (!r.ok) { err = "cRELOC truncated"; return false; }
                local.push_back(p);
                break;
            }
            case 0xE3: { // INTERSEG
                Pending p{segIndex, 0, 0, 0, true, 1, 0, 0};
                p.size = r.u(1); p.shift = (int8_t)r.u(1); p.offset = r.u(4);
                p.file = r.u(2); p.segnum = r.u(2); p.value = r.u(4);
                if (!r.ok) { err = "INTERSEG truncated"; return false; }
                local.push_back(p);
                break;
            }
            case 0xF6: { // cINTERSEG
                Pending p{segIndex, 0, 0, 0, true, 1, 0, 0};
                p.size = r.u(1); p.shift = (int8_t)r.u(1); p.offset = r.u(2);
                p.segnum = r.u(1); p.value = r.u(2);
                if (!r.ok) { err = "cINTERSEG truncated"; return false; }
                local.push_back(p);
                break;
            }
            case 0xF7: { // SUPER
                uint32_t n = r.u(4);
                if (!r.ok || n < 1 || !r.has(n)) { err = "SUPER truncated"; return false; }
                size_t q = r.pos, qe = r.pos + n;
                uint8_t type = f[q++];
                uint32_t page = 0;
                while (q < qe) {
                    uint8_t c = f[q++];
                    if (c & 0x80) { page += c & 0x7F; continue; }
                    for (int i = 0; i <= c; i++) {
                        if (q >= qe) { err = "SUPER subrecord truncated"; return false; }
                        uint32_t po = page * 256 + f[q++];
                        Pending p{segIndex, po, 0, 0, false, 1, s.segnum, 0};
                        if (type == 0) p.size = 2;
                        else if (type == 1) p.size = 3;
                        else if (type <= 13) { p.size = 3; p.inter = true; p.file = type - 1; }
                        else if (type <= 25) { p.size = 2; p.inter = true; p.segnum = type - 13; }
                        else if (type <= 37) { p.size = 2; p.inter = true; p.segnum = type - 25; p.shift = -16; }
                        else { err = "unknown SUPER type " + std::to_string(type); return false; }
                        // value is taken from the patch location (resolved below)
                        p.superType = type;
                        local.push_back(p);
                    }
                    page++;
                }
                r.pos = qe;
                break;
            }
            default:
                { char b[16]; snprintf(b, sizeof b, "%02X", op); err = std::string("unsupported OMF record $") + b + " (not a load file?) in segment " + s.name; }
                return false;
            }
        }
        // resolve SUPER values from the unpatched segment bytes
        for (auto &p : local) {
            if (p.superType < 0) continue;
            uint32_t type = (uint32_t)p.superType;
            if ((uint64_t)p.offset + p.size > s.data.size()) { err = "SUPER patch out of range in " + s.name; return false; }
            if (type == 0) p.value = rd(s.data, p.offset, 2);
            else if (type == 1) p.value = rd(s.data, p.offset, 3);
            else if (type <= 13) { p.value = rd(s.data, p.offset, 2); p.segnum = s.data[p.offset + 2]; }
            else p.value = rd(s.data, p.offset, 2);
        }
        pend.insert(pend.end(), local.begin(), local.end());
        img.segs.push_back(std::move(s));
        off += bytecnt;
    }
    if (img.segs.empty()) { err = "no OMF segments"; return false; }
    // choose bases
    uint64_t cursor = o.base;
    for (auto &s : img.segs) {
        auto it = o.segBase.find(s.segnum);
        if (it != o.segBase.end()) s.base = it->second;
        else if (s.org) s.base = s.org;
        else {
            s.base = (uint32_t)cursor;
            uint64_t e = cursor + s.data.size();
            cursor = (e + o.stride - 1) / o.stride * o.stride;
            if (cursor == s.base) cursor += o.stride;
        }
        if ((uint64_t)s.base + s.data.size() > 0x1000000) { err = "segment " + s.name + " does not fit below $1000000 at base " + hex(s.base); return false; }
    }
    auto findSeg = [&](uint16_t n) -> const Segment * {
        for (auto &s : img.segs) if (s.segnum == n) return &s;
        return nullptr;
    };
    for (auto &p : pend) {
        Segment &s = img.segs[p.seg];
        RelocNote note{p.offset, p.size, p.shift, p.inter, p.segnum, p.value, false};
        if (p.size == 0 || p.size > 4 || (uint64_t)p.offset + p.size > s.data.size()) {
            img.warnings.push_back("relocation out of range in segment " + s.name + " at " + hex(p.offset));
            continue;
        }
        const Segment *t = p.inter ? findSeg(p.segnum) : &s;
        if (p.inter && p.file != 1) t = nullptr;
        if (!t) {
            img.warnings.push_back("unresolved interseg reference (file " + std::to_string(p.file) + " seg " + std::to_string(p.segnum) + ") in " + s.name + " at " + hex(p.offset));
            s.relocs.push_back(note);
            continue;
        }
        uint64_t v = (uint64_t)t->base + p.value;
        if (p.shift >= 0) v <<= (p.shift & 31); else v >>= ((-p.shift) & 31);
        for (int i = 0; i < p.size; i++) s.data[p.offset + i] = (uint8_t)(v >> (8 * i));
        note.resolved = true;
        s.relocs.push_back(note);
    }
    return true;
}

} // namespace da
