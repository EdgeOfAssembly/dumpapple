// mkomf: builds the small synthetic OMF load-file fixtures used by the tests,
// together with the expected relocated image.  Written from scratch; contains
// no third-party data.
//   mkomf v2 OUT.omf OUT.expected [BASE]
//   mkomf v1 OUT.omf OUT.expected [BASE]
#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

using B = std::vector<uint8_t>;
static void le(B &v, uint32_t x, int n) { for (int i = 0; i < n; i++) v.push_back((uint8_t)(x >> (8 * i))); }

enum Enc { E_RELOC, E_CRELOC, E_INTERSEG, E_CINTERSEG, E_SUPER };
struct Patch { uint32_t site; int size; int shift; int seg; uint32_t off; Enc enc; int superType; };
struct Seg {
    std::string name; int num; uint16_t kind; uint32_t entry;
    B code;            // bytes laid down by LCONST/CONST
    std::vector<std::pair<uint32_t,uint32_t>> ds;  // (at, len) DS records interleaved: at = position in output stream
    uint32_t resspc;
    std::vector<Patch> patches;
    uint32_t length() const { uint32_t n = code.size(); for (auto &d : ds) n += d.second; return n + resspc; }
};

int main(int argc, char **argv) {
    if (argc < 4) { printf("usage: mkomf v1|v2 OUT.omf OUT.expected [BASE]\n"); return 0; }
    bool v1 = std::string(argv[1]) == "v1";
    uint32_t base = argc > 4 ? strtoul(argv[4], nullptr, 16) : 0x020000;
    // ---- segment 1: main code
    Seg s1{"MAIN", 1, 0x0000, 0, {}, {}, 16, {}};
    uint8_t c1[] = {
        0xC2, 0x30,                   // 0000 rep #$30
        0xA9, 0x34, 0x12,             // 0002 lda #$1234
        0x22, 0x00, 0x00, 0x00,       // 0005 jsl SUB+0          (INTERSEG)
        0xAD, 0x00, 0x00,             // 0009 lda MAIN+$30 abs   (cRELOC)
        0xAF, 0x00, 0x00, 0x00,       // 000C lda MAIN+$30 long  (RELOC)
        0xA2, 0x00, 0x00,             // 0010 ldx #^DATA         (cINTERSEG >>16)
        0xA0, 0x04, 0x00,             // 0013 ldy #DATA+4        (SUPER INTERSEG13+2)
        0xF4, 0x00, 0x00,             // 0016 pea ^DATA          (SUPER INTERSEG25+2)
        0x5C, 0x20, 0x00, 0x00,       // 0019 jml MAIN+$20       (SUPER RELOC3)
        0xEA, 0xEA, 0xEA,             // 001D
        0xAD, 0x30, 0x00,             // 0020 lda MAIN+$30       (SUPER RELOC2)
        0x22, 0x04, 0x00, 0x02,       // 0023 jsl SUB+4          (SUPER INTERSEG1: seg in 3rd byte)
        0x6B,                         // 0027 rtl
        0xC1, 0xD0, 0xD0, 0xCC, 0xC5, 0xA0, 0xC9, 0xC9, // 0028 hi-ascii "APPLE II" (CONST)
        0x11, 0x11, 0x22, 0x22,       // 0030 data
    };
    s1.code.assign(c1, c1 + sizeof c1);
    s1.ds.push_back({(uint32_t)s1.code.size(), 12});
    s1.patches = {
        {0x0006, 3, 0, 2, 0x0000, E_INTERSEG, 0},
        {0x000A, 2, 0, 1, 0x0030, E_CRELOC, 0},
        {0x000D, 3, 0, 1, 0x0030, E_RELOC, 0},
        {0x0011, 2, -16, 3, 0x0000, E_CINTERSEG, 0},
        {0x0014, 2, 0, 3, 0x0004, E_SUPER, 13 + 3},
        {0x0017, 2, -16, 3, 0x0000, E_SUPER, 25 + 3},
        {0x001A, 3, 0, 1, 0x0020, E_SUPER, 1},
        {0x0021, 2, 0, 1, 0x0030, E_SUPER, 0},
        {0x0024, 3, 0, 2, 0x0004, E_SUPER, 2},
    };
    // ---- segment 2: sub code
    Seg s2{"SUB", 2, 0x0000, 0, {0xE2, 0x20, 0xA9, 0x12, 0xC2, 0x20, 0x6B}, {}, 0, {}};
    // ---- segment 3: data
    Seg s3{"DATA", 3, 0x0001, 0, {'H', 'e', 'l', 'l', 'o', '!', 0}, {{7, 0x20}}, 0, {}};
    std::vector<Seg> segs = {s1, s2, s3};
    if (v1) {
        for (auto &p : segs[0].patches) {
            if (p.enc == E_SUPER) {
                // v1 has no SUPER: use long records; zero the in-file value bytes
                bool inter = p.superType >= 2;
                p.enc = inter ? E_INTERSEG : E_RELOC;
            }
        }
        // in v1, value bytes at SUPER sites must not carry data (RELOC supplies it)
        for (uint32_t s : {0x14u, 0x15u, 0x17u, 0x18u, 0x1Au, 0x1Bu, 0x1Cu, 0x21u, 0x22u, 0x24u, 0x25u, 0x26u}) segs[0].code[s] = 0;
    }
    // ---- expected image
    uint32_t bases[4] = {0, 0, 0, 0}, cur = base;
    for (auto &s : segs) { bases[s.num] = cur; cur = (cur + s.length() + 0xFFFF) & ~0xFFFFu; }
    B expected;
    for (auto &s : segs) {
        B img = s.code;
        for (auto &d : s.ds) img.insert(img.begin() + d.first, d.second, 0);
        img.resize(s.length(), 0);
        for (auto &p : s.patches) {
            uint64_t v = (uint64_t)bases[p.seg] + p.off;
            v = p.shift < 0 ? v >> -p.shift : v << p.shift;
            for (int i = 0; i < p.size; i++) img[p.site + i] = (uint8_t)(v >> (8 * i));
        }
        expected.insert(expected.end(), img.begin(), img.end());
    }
    // ---- write OMF
    B file;
    for (auto &s : segs) {
        B body;
        // code: LCONST for all but the 8 hi-ascii bytes of MAIN, which use CONST
        if (s.num == 1) {
            body.push_back(0xF2); le(body, 0x28, 4); body.insert(body.end(), s.code.begin(), s.code.begin() + 0x28);
            body.push_back(8); body.insert(body.end(), s.code.begin() + 0x28, s.code.begin() + 0x30);
            body.push_back(0xF2); le(body, s.code.size() - 0x30, 4); body.insert(body.end(), s.code.begin() + 0x30, s.code.end());
        } else {
            body.push_back(0xF2); le(body, s.code.size(), 4); body.insert(body.end(), s.code.begin(), s.code.end());
        }
        for (auto &d : s.ds) { body.push_back(0xF1); le(body, d.second, 4); }
        std::vector<Patch> supers;
        for (auto &p : s.patches) {
            switch (p.enc) {
            case E_RELOC: body.push_back(0xE2); body.push_back(p.size); body.push_back((uint8_t)p.shift); le(body, p.site, 4); le(body, p.off, 4); break;
            case E_CRELOC: body.push_back(0xF5); body.push_back(p.size); body.push_back((uint8_t)p.shift); le(body, p.site, 2); le(body, p.off, 2); break;
            case E_INTERSEG: body.push_back(0xE3); body.push_back(p.size); body.push_back((uint8_t)p.shift); le(body, p.site, 4); le(body, 1, 2); le(body, p.seg, 2); le(body, p.off, 4); break;
            case E_CINTERSEG: body.push_back(0xF6); body.push_back(p.size); body.push_back((uint8_t)p.shift); le(body, p.site, 2); body.push_back(p.seg); le(body, p.off, 2); break;
            case E_SUPER: supers.push_back(p); break;
            }
        }
        for (auto &p : supers) {   // one SUPER record per patch (all in page 0)
            B sr = {(uint8_t)p.superType, 0x00, (uint8_t)p.site};
            body.push_back(0xF7); le(body, sr.size(), 4); body.insert(body.end(), sr.begin(), sr.end());
        }
        body.push_back(0x00);
        B hdr;
        std::string load = "          ";
        B names(load.begin(), load.end());
        if (v1) { names.insert(names.end(), s.name.begin(), s.name.end()); names.resize(10 + 10, ' '); }  // LABLEN 10
        else { names.push_back((uint8_t)s.name.size()); names.insert(names.end(), s.name.begin(), s.name.end()); }
        uint32_t dispname = 0x2C, dispdata = dispname + names.size();
        uint32_t total = dispdata + body.size();
        uint32_t padded = v1 ? (total + 511) / 512 * 512 : total;
        le(hdr, v1 ? padded / 512 : total, 4);
        le(hdr, s.resspc, 4);
        le(hdr, s.length(), 4);
        hdr.push_back(v1 ? (uint8_t)s.kind : 0);
        hdr.push_back(v1 ? 10 : 0);  // LABLEN
        hdr.push_back(4);            // NUMLEN
        hdr.push_back(v1 ? 1 : 2);   // VERSION
        le(hdr, 0x10000, 4);         // BANKSIZE
        if (v1) le(hdr, 0, 4); else { le(hdr, s.kind, 2); le(hdr, 0, 2); }
        le(hdr, 0, 4);               // ORG
        le(hdr, 0, 4);               // ALIGN
        hdr.push_back(0); hdr.push_back(0);
        le(hdr, s.num, 2);
        le(hdr, s.entry, 4);
        le(hdr, dispname, 2);
        le(hdr, dispdata, 2);
        file.insert(file.end(), hdr.begin(), hdr.end());
        file.insert(file.end(), names.begin(), names.end());
        file.insert(file.end(), body.begin(), body.end());
        file.resize(file.size() + (padded - total), 0);
    }
    auto save = [](const char *path, const B &v) {
        FILE *f = fopen(path, "wb");
        if (!f) { fprintf(stderr, "mkomf: cannot create %s: %s\n", path, strerror(errno)); return false; }
        bool ok = fwrite(v.data(), 1, v.size(), f) == v.size();
        if (fclose(f) != 0) ok = false;
        if (!ok) fprintf(stderr, "mkomf: write error on %s\n", path);
        return ok;
    };
    if (!save(argv[2], file) || !save(argv[3], expected)) return 1;
    return 0;
}
