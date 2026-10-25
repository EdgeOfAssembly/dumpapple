// Recursive-descent control-flow analysis with M/X/E width tracking.
#include "analyze.h"
#include <cstdio>
#include <cstdarg>
#include <algorithm>
#include <deque>
#include <set>
#include <tuple>

namespace da {

const uint8_t *AddrMap::at(uint32_t a, size_t &avail, int *segIndex) const {
    for (size_t i = 0; i < img.segs.size(); i++) {
        const Segment &s = img.segs[i];
        if (a >= s.base && (uint64_t)a < (uint64_t)s.base + s.data.size()) {
            avail = s.base + s.data.size() - a;
            if (segIndex) *segIndex = (int)i;
            return s.data.data() + (a - s.base);
        }
    }
    avail = 0;
    return nullptr;
}

namespace {
using Ranges = std::map<uint32_t, uint32_t>; // merged, non-overlapping: start -> end (exclusive)
Ranges mergeRanges(const std::map<uint32_t, uint32_t> &r) {
    Ranges m;
    uint64_t cs = 0, ce = 0;
    bool open = false;
    for (auto &kv : r) {
        uint64_t s = kv.first, e = (uint64_t)kv.first + kv.second;
        if (open && s <= ce) { if (e > ce) ce = e; continue; }
        if (open) m[(uint32_t)cs] = (uint32_t)std::min<uint64_t>(ce, 0xFFFFFFFFu);
        cs = s; ce = e; open = true;
    }
    if (open) m[(uint32_t)cs] = (uint32_t)std::min<uint64_t>(ce, 0xFFFFFFFFu);
    return m;
}
bool inData(const Ranges &r, uint32_t a, uint32_t len) {
    auto it = r.upper_bound(a + len - 1);
    if (it == r.begin()) return false;
    --it;
    return it->second > a;
}
std::string hex6(uint32_t a) { char b[16]; snprintf(b, sizeof b, "$%06X", a); return b; }

// Apply instruction effects to the width state.
State step(const Insn &in, State s) {
    uint8_t op = in.b[0];
    int8_t oldc = s.c;
    // pure stores, pushes and nop leave every flag alone
    switch (op) {
    case 0x85: case 0x8D: case 0x95: case 0x9D: case 0x99: case 0x81: case 0x91: case 0x92:
    case 0x8F: case 0x9F: case 0x87: case 0x97: case 0x93: case 0x83:
    case 0x86: case 0x8E: case 0x96: case 0x84: case 0x8C: case 0x94:
    case 0x64: case 0x9C: case 0x74: case 0x9E:
    case 0x48: case 0xDA: case 0x5A: case 0x0B: case 0x8B: case 0x4B: case 0xEA:
        return s;
    default: break;
    }
    int8_t oldv = s.v, oldz = s.z, oldn = s.n;
    s.c = s.z = s.n = s.v = -1;
    switch (op) {
    case 0xB8: s.v = 0; s.c = oldc; s.z = oldz; s.n = oldn; break;   // CLV
    case 0xA9: case 0xA2: case 0xA0: {          // LDA/LDX/LDY #imm: Z and N from the value
        int v = in.b[1] | (in.len == 3 ? in.b[2] << 8 : 0);
        s.c = oldc; s.v = oldv;
        s.z = v == 0; s.n = (v >> (in.len == 3 ? 15 : 7)) & 1;
        if ((op == 0xA9 ? s.m : s.x) < 0) s.z = s.n = -1;          // width unknown: value unknown
        break;
    }
    case 0x18: s.c = 0; break;                 // CLC
    case 0x38: s.c = 1; break;                 // SEC
    case 0xD8: s.d = 0; break;                 // CLD
    case 0xF8: s.d = 1; break;                 // SED
    case 0xC2: {                               // REP
        uint8_t v = in.b[1];
        if (v & 0x20) s.m = s.e == 0 ? 0 : (s.e == 1 ? 1 : -1);
        if (v & 0x10) s.x = s.e == 0 ? 0 : (s.e == 1 ? 1 : -1);
        s.c = (v & 1) ? 0 : oldc;
        s.z = (v & 2) ? 0 : oldz; s.v = (v & 0x40) ? 0 : oldv; s.n = (v & 0x80) ? 0 : oldn;
        if (v & 0x08) s.d = 0;
        break;
    }
    case 0xE2: {                               // SEP
        uint8_t v = in.b[1];
        if (v & 0x20) s.m = 1;
        if (v & 0x10) s.x = 1;
        s.c = (v & 1) ? 1 : oldc;
        s.z = (v & 2) ? 1 : oldz; s.v = (v & 0x40) ? 1 : oldv; s.n = (v & 0x80) ? 1 : oldn;
        if (v & 0x08) s.d = 1;
        break;
    }
    case 0xFB: {                               // XCE
        int8_t ne = oldc, oe = s.e;
        s.c = oe;
        s.e = ne;
        if (ne == 1 || oe == 1) { s.m = 1; s.x = 1; }
        else if (ne < 0) { s.m = s.m == 1 ? 1 : -1; s.x = s.x == 1 ? 1 : -1; }
        break;
    }
    case 0x08:                                 // PHP
        if (s.depth >= 0 && s.depth < 4) { s.sm[s.depth] = s.m; s.sx[s.depth] = s.x; s.sd[s.depth] = s.d; s.depth++; }
        else s.depth = -1;
        break;
    case 0x28:                                 // PLP
        if (s.depth > 0) { s.depth--; s.m = s.sm[s.depth]; s.x = s.sx[s.depth]; s.d = s.sd[s.depth]; }
        else { s.m = -1; s.x = -1; s.d = -1; s.depth = s.depth == 0 ? 0 : -1; }
        break;
    default:
        break;
    }
    s.normalize();
    return s;
}
} // namespace

uint32_t tableTarget(const JumpTable &t, const uint8_t *p, int hi) {
    if (t.kind == TK_LONG) return (uint32_t)(p[0] | (p[1] << 8) | (p[2] << 16));
    if (t.kind == TK_RTSLONG) return (uint32_t)(p[2] << 16) | ((p[0] | (p[1] << 8)) + 1) % 0x10000;   // RTL: 16-bit increment
    if (t.kind == TK_SPLIT) return t.bank | ((p[0] | ((hi < 0 ? 0 : hi) << 8)) + 1) % 0x10000;
    uint32_t w = (uint32_t)(p[0] | (p[1] << 8));
    if (t.kind == TK_RTS) w = (w + 1) & 0xFFFF;
    return t.bank | w;
}

static std::string fmt(const char *f, ...) {
    char b[256]; va_list ap; va_start(ap, f); vsnprintf(b, sizeof b, f, ap); va_end(ap); return b;
}
// Addresses an ordinary absolute load reads (lda/ldx/ldy/cmp/adc/... abs) and the
// bases of indexed loads and of indirect jumps; used to bound auto tables.
static void refSets(const std::map<uint32_t, CodeInsn> &code, bool w816, std::set<uint32_t> &loadsAt,
                    std::set<uint32_t> &loadBases, std::set<uint32_t> &dispBases) {
    for (auto &kv : code) {
        const Insn &in = kv.second.in;
        if (in.len != 3) continue;
        uint32_t v16 = in.b[1] | (in.b[2] << 8), v = (kv.first & 0xFF0000) | v16;
        switch (in.b[0]) {
        case 0xAD: case 0xAE: case 0xAC: case 0xCD: case 0x6D: case 0xED: case 0x2D: case 0x0D: case 0x4D: case 0xEC: case 0xCC:
            loadsAt.insert(v); break;
        case 0xBD: case 0xB9: case 0xBE: case 0xBC: case 0xDD: case 0xD9: case 0x7D: case 0x79: case 0xFD: case 0xF9:
        case 0x3D: case 0x39: case 0x1D: case 0x19: case 0x5D: case 0x59:
            loadBases.insert(v); break;
        case 0x7C: dispBases.insert(v); break;
        case 0xFC: if (w816) dispBases.insert(v); break;
        case 0x6C: dispBases.insert(v16); break;
        default: break;
        }
    }
}

// length of a text run (>= 2 bytes of $20-$7E / $0D, bit 7 ignored) ended by $00, 0 = none
static uint32_t textZ(const AddrMap &am, uint32_t x) {
    size_t av; const uint8_t *p = am.at(x, av);
    uint32_t n = 0;
    while (p && n < av && n < 255 && p[n] != 0) {
        uint8_t b = p[n] & 0x7F;
        if (!((b >= 0x20 && b < 0x7F) || b == 0x0D)) break;
        n++;
    }
    return (p && n >= 2 && n < av && p[n] == 0) ? n : 0;
}

// ---- G2/G3: per-call-site emulation of an inline-string helper ----
// The helper is run from its entry with the JSR's return address on a modelled
// stack.  Values are known bytes or unknown (-1).  Only bytes read through a
// pointer that holds a known address come from the image (the inline bytes);
// every other memory read is unknown.  A conditional branch on an unknown flag
// forks; every path must return to the same address (rts with the caller's
// frame popped, or jmp (ind) at the caller's stack level).  Anything not
// modelled fails with a reason, and the caller leaves the bytes undecoded.
// Decimal mode comes from the caller's flow state (d0: 0 clear, 2 clear by the
// entry-point assumption, 1 set, -1 unknown); adc/sbc with D set or unknown fails.
// The Apple II monitor output routines COUT1, CROUT, PRBYTE, PRHEX keep X and Y
// and touch only zero page $20-$4F (A and the flags become unknown).  COUT ($FDED)
// jumps through CSW ($36/$37): it is trusted only when nothing in the image may
// store to $36/$37 (cswRisk finds nothing) and the helper itself has not written them.
// No input routine (KSW $38/$39) is trusted.
struct EmuResult { bool ok = false; uint32_t ret = 0; std::string why; bool ptrRead = false, usedCSW = false, usedD = false; std::set<uint32_t> exits; };
struct Mod { uint32_t lo, n, by; bool u = false; bool d = false; int v = -1; bool operator==(const Mod &o) const { return lo == o.lo && n == o.n && by == o.by && u == o.u && d == o.d && v == o.v; }
    bool operator<(const Mod &o) const { return std::tie(lo, n, by, u, d, v) < std::tie(o.lo, o.n, o.by, o.u, o.d, o.v); } };   // v: the one byte value written (n == 1), -1 unknown   // d: only under the unknown-target assumption   // u: a store with a fully unknown target
typedef std::vector<Mod> Mods;   // code bytes [lo, lo+n) in lo's bank that the store at by may change; n = ~0u: any
// (u mods taint helper emulation, CSW and returns as any other; code and width decoding ignores them unless --strict-smc)
static EmuResult emuInline(const AddrMap &am, Cpu cpu, uint32_t helper, uint32_t site, int d0, const std::string &cswWhy, const std::set<uint32_t> &patched, const Mods &mods) {
    struct M {
        int a = -1, x = -1, y = -1, n = -1, z = -1, c = -1, v = -1, d = 0; bool csw = false, usedCSW = false, usedD = false;
        int sp = 0xEE; uint16_t pc = 0; int depth = 0; int lastRd = -1;   // last inline byte read through a pointer
        std::map<uint16_t, int> mem;      // written (or initial stack) bytes; absent = unknown
    };
    const uint32_t K = site & 0xFF0000;
    const uint16_t R = (uint16_t)((site + 2) & 0xFFFF);
    M m0; m0.pc = (uint16_t)(helper & 0xFFFF); m0.d = d0;
    m0.mem[0x1F0] = R >> 8; m0.mem[0x1EF] = R & 0xFF;
    const bool c02 = cpu != Cpu::C6502;
    std::vector<M> work{m0};
    long steps = 0; int paths = 0; bool have = false, ptrRead = false, usedCSW = false, usedD = false; uint32_t ret = 0;
    std::set<uint32_t> exits;     // the helper's own return instructions reached (pushed-address returns proven here)
    auto fail = [&](std::string w) { EmuResult r; r.why = std::move(w); r.ptrRead = ptrRead; r.exits = exits; return r; };
    auto rd = [&](M &m, uint16_t ad) -> int { auto it = m.mem.find(ad); return it == m.mem.end() ? -1 : it->second; };
    auto wr = [&](M &m, uint16_t ad, int v) { if (v < 0) m.mem.erase(ad); else m.mem[ad] = v; };
    while (!work.empty()) {
        M m = std::move(work.back()); work.pop_back();
        if (++paths > 64) return fail("too many paths through the helper (exit not proven)");
        for (;;) {
            if (++steps > 200000) return fail("step limit reached (exit not proven)");
            size_t av; const uint8_t *p = am.at(K | m.pc, av);
            if (!p) return fail(fmt("helper runs outside the image at $%04X", m.pc));
            int modAt = -1; uint32_t modBy = 0;
            auto fb = [&](int k) -> int {   // a patched immediate operand, or a byte another store may change, is unknown
                if ((size_t)k >= av) return -1;
                uint16_t x = (uint16_t)(m.pc + k);
                auto it = m.mem.find(x);
                if (it != m.mem.end()) return it->second;
                if (patched.count(K | x)) return -1;
                for (auto &r : mods)
                    if (r.n == ~0u || ((r.lo & 0xFF0000) == K && (uint32_t)((x - r.lo) & 0xFFFF) < r.n)) { if (modAt < 0) { modAt = x; modBy = r.by; } return -1; }
                return p[k];
            };
            int op = fb(0);
            if (op < 0 && modAt >= 0) return fail(fmt("helper code at $%04X may be changed by the store at $%04X (self-modifying code)", modAt, modBy & 0xFFFF));
            if (op < 0) return fail("opcode unknown");
            auto b1 = [&]() { return fb(1); };
            auto w16 = [&]() -> int { int l = fb(1), h = fb(2); return l < 0 || h < 0 ? -1 : l | (h << 8); };
            auto setNZ = [&](int v) { if (v < 0) { m.n = m.z = -1; } else { m.n = (v >> 7) & 1; m.z = v == 0; } };
            // effective address for a mode; returns -2 = unknown address, sets len
            int len = 1; bool viaPtr = false;
            auto ea = [&](int mode) -> int {   // 0 imm 1 zp 2 abs 3 zp,x 4 zp,y 5 abs,x 6 abs,y 7 (zp,x) 8 (zp),y 9 (zp)
                int o = b1(), w = w16();
                switch (mode) {
                case 1: len = 2; return o < 0 ? -2 : o;
                case 2: len = 3; return w < 0 ? -2 : w;
                case 3: len = 2; return o < 0 || m.x < 0 ? -2 : (o + m.x) & 0xFF;
                case 4: len = 2; return o < 0 || m.y < 0 ? -2 : (o + m.y) & 0xFF;
                case 5: len = 3; return w < 0 || m.x < 0 ? -2 : (w + m.x) & 0xFFFF;
                case 6: len = 3; return w < 0 || m.y < 0 ? -2 : (w + m.y) & 0xFFFF;
                case 7: { len = 2; if (o < 0 || m.x < 0) return -2; int z = (o + m.x) & 0xFF, l = rd(m, z), h = rd(m, (z + 1) & 0xFF); viaPtr = true; return l < 0 || h < 0 ? -2 : l | (h << 8); }
                case 8: { len = 2; if (o < 0) return -2; int l = rd(m, o), h = rd(m, (o + 1) & 0xFF); viaPtr = true; return l < 0 || h < 0 || m.y < 0 ? -2 : ((l | (h << 8)) + m.y) & 0xFFFF; }
                case 9: { len = 2; if (o < 0) return -2; int l = rd(m, o), h = rd(m, (o + 1) & 0xFF); viaPtr = true; return l < 0 || h < 0 ? -2 : l | (h << 8); }
                }
                len = 2; return -1;
            };
            std::string err;
            auto load = [&](int mode) -> int {
                if (mode == 0) { len = 2; return b1(); }
                int e = ea(mode);
                if (viaPtr) ptrRead = true;
                if (e == -2) { if (viaPtr) err = "read through a pointer that is not known"; return -1; }
                int v = rd(m, (uint16_t)e);
                if ((e == 0x1EF || e == 0x1F0) && (mode == 5 || mode == 6)) ptrRead = true;
                if (v >= 0 || !viaPtr) return v;
                size_t a2; const uint8_t *q = am.at(K | (uint32_t)e, a2);
                if (!q) { err = fmt("string runs past the end of the image (read at $%04X)", e); return -1; }
                m.lastRd = e;
                return *q;
            };
            auto store = [&](int mode, int v) -> bool {
                int e = ea(mode);
                if (e == -2) {   // unknown address: anything could change; refuse if it could hit page 0/1
                    int base = mode == 5 || mode == 6 ? w16() : -1;
                    if (base < 0 || base < 0x200) { err = "store to an unknown address"; return false; }
                    for (int q = 0; q < 0x100; q++)        // could rewrite bytes the helper later reads from the image
                        if (am.contains(K | (uint32_t)((base + q) & 0xFFFF))) { err = "indexed store to an unknown address that may hit the image"; return false; }
                    for (auto it = m.mem.lower_bound((uint16_t)base); it != m.mem.end() && it->first <= base + 0xFF;) it = m.mem.erase(it);
                    return true;
                }
                if (e == 0x36 || e == 0x37) m.csw = true;
                wr(m, (uint16_t)e, v); return true;
            };
            auto push = [&](int v) { wr(m, (uint16_t)(0x100 | m.sp), v); m.sp = (m.sp - 1) & 0xFF; };
            auto pull = [&]() -> int { if (m.sp >= 0xF0) { err = "helper pulls past the caller's frame"; return -1; } m.sp++; return rd(m, (uint16_t)(0x100 | m.sp)); };
            auto adc = [&](int v, bool sub) {
                if (m.d == 1) { err = "adds in decimal mode (sed)"; return; }
                if (m.d != 0 && m.d != 2) { err = "decimal mode not known at an add"; return; }
                if (m.d == 2) m.usedD = true;
                if (sub && v >= 0) v ^= 0xFF;
                if (m.a < 0 || v < 0 || m.c < 0) { m.a = -1; m.c = m.v = -1; setNZ(-1); return; }
                int r = m.a + v + m.c;
                m.v = (~(m.a ^ v) & (m.a ^ r) & 0x80) ? 1 : 0;
                m.c = r > 0xFF; m.a = r & 0xFF; setNZ(m.a);
            };
            auto cmp = [&](int r, int v) {
                if (r < 0 || v < 0) { m.c = -1; setNZ(-1); return; }
                m.c = r >= v; setNZ((r - v) & 0xFF);
            };
            auto shift = [&](int kind, int v) -> int {   // 0 asl 1 rol 2 lsr 3 ror
                int cin = m.c;
                if (v < 0 || ((kind == 1 || kind == 3) && cin < 0)) { m.c = -1; setNZ(-1); return -1; }
                int r;
                if (kind < 2) { m.c = (v >> 7) & 1; r = ((v << 1) | (kind == 1 ? cin : 0)) & 0xFF; }
                else { m.c = v & 1; r = (v >> 1) | (kind == 3 ? cin << 7 : 0); }
                setNZ(r); return r;
            };
            static const int aluMode[8] = {7, 1, 0, 2, 8, 3, 6, 5};
            uint16_t npc = 0; bool jumped = false;
            int cc = op & 3, aaa = op >> 5, bbb = (op >> 2) & 7;
            if (cc == 1 || (c02 && (op & 0x1F) == 0x12)) {          // ora and eor adc sta lda cmp sbc
                int mode = cc == 1 ? aluMode[bbb] : 9;
                if (aaa == 4 && mode == 0) {                                  // 65c02 bit #imm (sta #imm does not exist)
                    if (!c02) return fail("unsupported opcode $89");
                    len = 2; int v = b1(); m.z = m.a < 0 || v < 0 ? -1 : (m.a & v) == 0;
                }
                else if (aaa == 4) { if (!store(mode, m.a)) return fail(err); }
                else {
                    int v = load(mode);
                    if (!err.empty()) return fail(err);
                    switch (aaa) {
                    case 0: m.a = m.a < 0 || v < 0 ? (v == 0xFF ? 0xFF : -1) : (m.a | v); setNZ(m.a); break;
                    case 1: m.a = m.a < 0 || v < 0 ? (v == 0 || m.a == 0 ? 0 : -1) : (m.a & v); setNZ(m.a); break;
                    case 2: m.a = m.a < 0 || v < 0 ? -1 : (m.a ^ v); setNZ(m.a); break;
                    case 3: adc(v, false); break;
                    case 5: m.a = v; setNZ(v); break;
                    case 6: cmp(m.a, v); break;
                    case 7: adc(v, true); break;
                    }
                    if (!err.empty()) return fail(err);
                }
            } else if ((op & 0x1F) == 0x10) {                         // branches
                len = 2;
                int fl = aaa >> 1 == 0 ? m.n : aaa >> 1 == 1 ? m.v : aaa >> 1 == 2 ? m.c : m.z;
                int d = b1();
                if (d < 0) return fail("branch offset unknown");
                uint16_t tgt = (uint16_t)(m.pc + 2 + (int8_t)d);
                if (fl < 0) { M f = m; f.pc = tgt; work.push_back(std::move(f)); }
                else if (fl == (aaa & 1)) { npc = tgt; jumped = true; }
            } else switch (op) {
            case 0x00: return fail("brk in the helper");
            case 0x40: return fail("rti in the helper");
            case 0x20: {
                int t = w16(); if (t < 0) return fail("jsr target unknown");
                if (am.contains(K | (uint32_t)t)) {
                    if (++m.depth > 8) return fail("calls nested too deep");
                    uint16_t r = (uint16_t)(m.pc + 2);
                    push(r >> 8); push(r & 0xFF);
                    npc = (uint16_t)t; jumped = true; break;
                }
                if (t == 0xFDED && (!cswWhy.empty() || m.csw))
                    return fail(m.csw ? "the helper sets CSW ($36/$37) before calling COUT $FDED" :
                                        "COUT $FDED goes through CSW ($36/$37), which the image may change (" + cswWhy + ")");
                if (t == 0xFDED) m.usedCSW = true;
                if (t == 0xFDED || t == 0xFDF0 || t == 0xFD8E || t == 0xFDDA || t == 0xFDE3) {
                    m.a = -1; m.n = m.z = m.c = m.v = -1;
                    for (auto it = m.mem.lower_bound(0x20); it != m.mem.end() && it->first <= 0x4F;) it = m.mem.erase(it);
                    len = 3; break;
                }
                return fail(fmt("calls $%04X, an external routine whose effect is not known", t));
            }
            case 0x60: {
                if (m.sp == 0xEE && m.depth == 0) {
                    exits.insert(K | m.pc);
                    int l = rd(m, 0x1EF), h = rd(m, 0x1F0);
                    if (l < 0 || h < 0) return fail("return address on the stack not known");
                    uint32_t t = K | (uint32_t)(((l | (h << 8)) + 1) & 0xFFFF);
                    if ((t & 0xFFFF) != (((uint32_t)m.lastRd + 1) & 0xFFFF) && (t & 0xFFFF) != ((R + 1u) & 0xFFFF))
                        return fail(m.lastRd < 0 ? std::string("returns past the call without reading through the pointer") :
                                    fmt("return to $%04X does not land right after the last byte read ($%04X)", t & 0xFFFF, m.lastRd));
                    if (have && t != ret) return fail(fmt("paths return to different places ($%04X and $%04X)", ret & 0xFFFF, t & 0xFFFF));
                    have = true; ret = t; usedCSW |= m.usedCSW; usedD |= m.usedD; goto nextPath;
                }
                if (m.sp >= 0xEE) return fail("rts pops the caller's frame");
                int l = pull(), h = pull();
                if (l < 0 || h < 0) return fail("rts to an unknown address");
                if (m.depth > 0) m.depth--;
                npc = (uint16_t)((l | (h << 8)) + 1); jumped = true; break;
            }
            case 0x6C: case 0x7C: {
                int w = w16(); if (w < 0) return fail("jmp operand unknown");
                if (op == 0x7C) { if (!c02) return fail("unsupported opcode"); if (m.x < 0) return fail("unresolved indirect jump"); w = (w + m.x) & 0xFFFF; }
                int l = rd(m, (uint16_t)w), h = rd(m, (uint16_t)(op == 0x6C && !c02 && (w & 0xFF) == 0xFF ? (w & 0xFF00) : (w + 1) & 0xFFFF));
                if (l < 0 || h < 0) return fail("unresolved indirect jump");
                uint32_t t = K | (uint32_t)(l | (h << 8));
                if (m.sp == 0xF0 && m.depth == 0) {   // caller's frame popped: this is the return
                    exits.insert(K | m.pc);
                    if ((t & 0xFFFF) != (((uint32_t)m.lastRd + 1) & 0xFFFF) && (t & 0xFFFF) != ((R + 1u) & 0xFFFF))
                        return fail(m.lastRd < 0 ? std::string("returns past the call without reading through the pointer") :
                                    fmt("return to $%04X does not land right after the last byte read ($%04X)", t & 0xFFFF, m.lastRd));
                    if (have && t != ret) return fail(fmt("paths return to different places ($%04X and $%04X)", ret & 0xFFFF, t & 0xFFFF));
                    have = true; ret = t; usedCSW |= m.usedCSW; usedD |= m.usedD; goto nextPath;
                }
                npc = (uint16_t)t; jumped = true; break;
            }
            case 0x4C: { int w = w16(); if (w < 0) return fail("jmp target unknown"); npc = (uint16_t)w; jumped = true; break; }
            case 0x80: if (!c02) return fail("unsupported opcode"); { int d = b1(); if (d < 0) return fail("branch offset unknown"); npc = (uint16_t)(m.pc + 2 + (int8_t)d); jumped = true; } break;
            case 0x08: push(-1); break;    // flags pushed as unknown; plp makes them unknown
            case 0x28: pull(); if (!err.empty()) return fail(err); m.n = m.z = m.c = m.v = -1; m.d = -1; break;
            case 0x48: push(m.a); break;
            case 0x68: m.a = pull(); if (!err.empty()) return fail(err); setNZ(m.a); break;
            case 0x5A: if (!c02) return fail("unsupported opcode"); push(m.y); break;
            case 0x7A: if (!c02) return fail("unsupported opcode"); m.y = pull(); if (!err.empty()) return fail(err); setNZ(m.y); break;
            case 0xDA: if (!c02) return fail("unsupported opcode"); push(m.x); break;
            case 0xFA: if (!c02) return fail("unsupported opcode"); m.x = pull(); if (!err.empty()) return fail(err); setNZ(m.x); break;
            case 0x18: m.c = 0; break; case 0x38: m.c = 1; break; case 0xB8: m.v = 0; break;
            case 0xD8: m.d = 0; break; case 0xF8: m.d = 1; break; case 0x58: case 0x78: case 0xEA: break;
            case 0xAA: m.x = m.a; setNZ(m.x); break; case 0x8A: m.a = m.x; setNZ(m.a); break;
            case 0xA8: m.y = m.a; setNZ(m.y); break; case 0x98: m.a = m.y; setNZ(m.a); break;
            case 0xBA: m.x = m.sp; setNZ(m.x); break;
            case 0x9A: return fail("txs in the helper");
            case 0xE8: m.x = m.x < 0 ? -1 : (m.x + 1) & 0xFF; setNZ(m.x); break;
            case 0xCA: m.x = m.x < 0 ? -1 : (m.x - 1) & 0xFF; setNZ(m.x); break;
            case 0xC8: m.y = m.y < 0 ? -1 : (m.y + 1) & 0xFF; setNZ(m.y); break;
            case 0x88: m.y = m.y < 0 ? -1 : (m.y - 1) & 0xFF; setNZ(m.y); break;
            case 0x1A: if (!c02) return fail("unsupported opcode"); m.a = m.a < 0 ? -1 : (m.a + 1) & 0xFF; setNZ(m.a); break;
            case 0x3A: if (!c02) return fail("unsupported opcode"); m.a = m.a < 0 ? -1 : (m.a - 1) & 0xFF; setNZ(m.a); break;
            case 0x0A: m.a = shift(0, m.a); break; case 0x2A: m.a = shift(1, m.a); break;
            case 0x4A: m.a = shift(2, m.a); break; case 0x6A: m.a = shift(3, m.a); break;
            default: {
                // remaining cc=0 / cc=2 groups: ldx ldy stx sty cpx cpy bit inc dec asl rol lsr ror stz
                int mode = -1;
                if (cc == 2) mode = bbb == 0 ? 0 : bbb == 1 ? 1 : bbb == 3 ? 2 : bbb == 5 ? ((aaa == 4 || aaa == 5) ? 4 : 3) : bbb == 7 ? (aaa == 5 ? 6 : 5) : -1;
                if (cc == 0) mode = bbb == 0 ? 0 : bbb == 1 ? 1 : bbb == 3 ? 2 : bbb == 5 ? 3 : bbb == 7 ? 5 : -1;
                if (mode < 0 || cc == 3) return fail(fmt("unsupported opcode $%02X", op));
                bool okOp = true;
                if (op == 0x64 || op == 0x74 || op == 0x9C || op == 0x9E) {    // stz
                    if (!c02) return fail(fmt("unsupported opcode $%02X", op));
                    if (!store(op == 0x64 ? 1 : op == 0x74 ? 3 : op == 0x9C ? 2 : 5, 0)) return fail(err);
                } else if (cc == 2 && aaa == 5) { int v = load(mode); if (!err.empty()) return fail(err); m.x = v; setNZ(v); if (mode == 0) okOp = op == 0xA2; }
                else if (cc == 0 && aaa == 5) { int v = load(mode); if (!err.empty()) return fail(err); m.y = v; setNZ(v); }
                else if (cc == 2 && aaa == 4 && mode != 0 && mode != 6 && mode != 5) { if (!store(mode, m.x)) return fail(err); }
                else if (cc == 0 && aaa == 4 && mode != 0 && mode != 5) { if (!store(mode, m.y)) return fail(err); }
                else if (cc == 0 && (aaa == 6 || aaa == 7)) { if (mode == 3 || mode == 5) okOp = false; else { int v = load(mode); if (!err.empty()) return fail(err); cmp(aaa == 6 ? m.y : m.x, v); } }
                else if (cc == 0 && aaa == 1 && (mode == 1 || mode == 2 || (c02 && (mode == 3 || mode == 5)))) {
                    int v = load(mode); if (!err.empty()) return fail(err);
                    if (v < 0) { m.n = m.v = m.z = -1; } else { m.n = (v >> 7) & 1; m.v = (v >> 6) & 1; m.z = m.a < 0 ? -1 : (m.a & v) == 0; }
                } else if (cc == 2 && aaa != 4 && aaa != 5 && mode != 0) {      // rmw: asl rol lsr ror dec inc
                    int e = ea(mode);
                    if (e == -2) return fail("read-modify-write at an unknown address");
                    int v = rd(m, (uint16_t)e), r;
                    if (aaa < 4) r = shift(aaa, v);
                    else { r = v < 0 ? -1 : (v + (aaa == 6 ? -1 : 1)) & 0xFF; setNZ(r); }
                    if (e == 0x36 || e == 0x37) m.csw = true;
                    wr(m, (uint16_t)e, r);
                } else okOp = false;
                if (!okOp) return fail(fmt("unsupported opcode $%02X", op));
                if (mode == 0) len = 2;
            }
            }
            if (!err.empty()) return fail(err);
            m.pc = jumped ? npc : (uint16_t)(m.pc + len);
        }
        nextPath:;
    }
    if (!have) return fail("no path returns");
    EmuResult r; r.ok = true; r.ret = ret; r.ptrRead = ptrRead; r.usedCSW = usedCSW; r.usedD = usedD; r.exits = exits; return r;
}

// Apple II ROM entry points that never return: OLDRST, MON, MONZ, RESET, BASIC cold/warm start
static std::string hex4(uint32_t t) { char b[8]; snprintf(b, sizeof b, "$%04X", t & 0xFFFF); return b; }
static bool romNoReturn(uint32_t t) {
    return t == 0xFF59 || t == 0xFF65 || t == 0xFF69 || t == 0xFA62 || t == 0xE000 || t == 0xE003;
}

static bool analyzeOnce(const Image &img, const Hints &h, const AnalyzeOptions &o, Decoder &dec, Analysis &out, const std::string &cswWhy, const std::set<uint32_t> &patched, const Mods &mods, const TableLimits &limits,
                        const std::set<uint32_t> &revoked, const std::set<uint32_t> &stopAfter, const std::set<uint32_t> &carryRevoked,
                        const std::set<uint32_t> &preStore, const std::set<uint32_t> &domBytes) {
    AddrMap am(img);
    // inline-parameter rules: platform ABI first, hints override
    std::map<uint32_t, std::pair<uint32_t, int>> inl;   // call target -> (bytes, kind)
    if (o.platform == Platform::GSOS) inl[0xE100A8] = {6, 1};        // GS/OS: call number + param block ptr
    if (o.platform == Platform::ProDOS8) inl[0x00BF00] = {3, 2};     // MLI: command + param list ptr
    for (auto &kv : h.inlines) if (kv.second > 0 && kv.second <= 255) inl[kv.first] = {kv.second, 0};   // N=0 would never advance
    // relocation sites (absolute) for the misdecode check
    std::map<uint32_t, uint8_t> relocs;
    for (auto &sg : img.segs) for (auto &r : sg.relocs) relocs[sg.base + r.offset] = r.size;
    const bool w816 = dec.cpu() == Cpu::C65816;
    std::map<uint32_t, uint32_t> dataAll = h.dataRanges;      // hints + tables found so far
    // OMF segments that are never code: the KIND $02 jump table (read below) and ~ExpressLoad
    std::vector<std::pair<uint32_t, uint32_t>> jtEntries;   // (entry addr, target addr)
    for (auto &sg : img.segs) {
        if (sg.data.empty()) continue;
        bool jt = img.omf && (sg.kind & 0x1F) == 0x02;
        if (!jt && !(img.omf && sg.name == "~ExpressLoad")) continue;
        dataAll[sg.base] = std::max(dataAll[sg.base], (uint32_t)sg.data.size());
        if (!jt) continue;
        // GS/OS Reference, OMF: 8 zero bytes, then 14-byte entries {user ID, load-file number,
        // load-segment number (words), segment offset (dword), JSL to the loader (4 bytes)};
        // a load-file number of zero ends the list
        const auto &dd = sg.data;
        auto w = [&](size_t i) { return (uint32_t)(dd[i] | (dd[i + 1] << 8)); };
        if (dd.size() >= 8) out.inlineData[sg.base] = {8, 0, "OMF jump table header"};
        size_t i = 8;
        bool ended = false;
        for (; i + 14 <= dd.size(); i += 14) {
            uint32_t file = w(i + 2), segno = w(i + 4);
            if (file == 0) { ended = true; break; }
            uint32_t off = w(i + 6) | (w(i + 8) << 16), ea = sg.base + (uint32_t)i;
            const Segment *ts = nullptr;
            for (auto &t : img.segs) if (t.segnum == segno) ts = &t;
            InlineBlock b{14, 3, "", 0};
            if (file != 1) b.why = fmt("OMF jump table entry: load file %u (not this file)", file);
            else if (!ts || off >= ts->data.size()) b.why = fmt("OMF jump table entry: segment %u offset $%X does not exist", segno, off);
            else {
                b.target = ts->base + off;
                b.why = fmt("OMF jump table entry -> segment %u (%s) + $%X", segno, ts->name.c_str(), off);
                if (!(ts->kind & 0x1F) && ts->name != "~ExpressLoad") jtEntries.push_back({ea, b.target});
                else b.why += " (target segment is not code; not followed)";
            }
            out.inlineData[ea] = b;
            out.labels[ea] |= LK_JTE;
        }
        // a short remainder is a terminator only if its load-file word is present and zero
        if (!ended && i < dd.size() && i + 4 <= dd.size() && w(i + 2) == 0) ended = true;
        if (i < dd.size()) {
            uint32_t rest = (uint32_t)(dd.size() - i);
            if (ended) out.inlineData[sg.base + (uint32_t)i] = {std::min<uint32_t>(4, rest), 0, "OMF jump table end (load-file number 0)"};
            else out.inlineData[sg.base + (uint32_t)i] = {rest, 0, fmt("OMF jump table truncated entry (%u of 14 bytes)", rest)};
        }
    }
    Ranges dataR = mergeRanges(dataAll);
    std::map<uint32_t, State> in;
    std::map<uint32_t, CodeInsn> decoded;
    std::deque<uint32_t> work;
    auto flow = [&](uint32_t a, const State &s0) {
        if (!am.contains(a)) return;
        if (inData(dataR, a, 1)) { out.refused.insert(a); return; }
        State s = s0;
        auto f = h.forced.find(a);
        if (f != h.forced.end()) { s = f->second; s.depth = s0.depth; s.normalize(); }
        auto it = in.find(a);
        if (it == in.end()) { in[a] = s; work.push_back(a); return; }
        State n = State::merge(it->second, s);
        if (f != h.forced.end()) { State keep = f->second; keep.depth = n.depth; for (int i = 0; i < 4; i++) { keep.sm[i] = n.sm[i]; keep.sx[i] = n.sx[i]; } keep.normalize(); n = keep; }
        if (n != it->second) { it->second = n; work.push_back(a); }
    };
    uint32_t curSrc = ~0u;        // instruction whose targets are being labelled (~0u: entry, table, hint)
    auto label = [&](uint32_t a, int k) {
        if (!am.contains(a)) return;
        out.labels[a] |= k;
        if (k & (LK_CODE | LK_SUB | LK_ENTRY)) out.ctlSrc[a].insert(curSrc);
    };
    // instruction that ends exactly at address a (straight-line predecessor)
    auto pred = [&](uint32_t a) -> const CodeInsn * {
        auto it = decoded.lower_bound(a >= 4 ? a - 4 : 0);
        for (; it != decoded.end() && it->first < a; ++it)
            if (it->first + it->second.in.len == a) return &it->second;
        return nullptr;
    };

    for (auto &e : o.entries) { label(e.addr, LK_ENTRY); flow(e.addr, e.hasState ? e.st : o.entryState); }
    for (auto &je : jtEntries) { label(je.second, LK_ENTRY); flow(je.second, o.entryState); }
    out.omfJumpEntries = (int)jtEntries.size();
    for (auto &e : h.entries) { label(e.addr, LK_ENTRY); flow(e.addr, e.hasState ? e.st : o.entryState); }

    // ---- variable-length inline data: a routine that pulls its return address,
    // steps past the JSR's off-by-one, reads through the pointer until a
    // terminator and returns through the advanced pointer.
    std::map<uint32_t, int> varKind(h.varInlines.begin(), h.varInlines.end());

    std::set<uint32_t> varTried;
    // length-prefixed helpers: bytes skipped for count N = base + max(y0, N) + extra,
    // read from the helper body (cpy N / bcs loop, return through tya / adc P)
    struct LenModel { uint32_t base, y0, extra; };
    std::map<uint32_t, LenModel> lenModel;
    std::map<uint32_t, std::string> carryUnk;   // length-prefixed helpers whose skip is not modelled -> why
    std::map<uint32_t, uint32_t> patchedHelper;   // helpers whose own immediate is patched -> operand address
    std::map<uint32_t, std::set<uint32_t>> helperExits;   // a detected helper's rts/rtl/rti
    auto detectVar = [&](uint32_t t, const State &st0) -> int {
        auto vk = varKind.find(t);
        if (vk != varKind.end()) return vk->second;
        if (!o.autoInline || varTried.count(t) || inl.count(t)) return 0;
        varTried.insert(t);
        if (st0.m == 0) return 0;                          // 16-bit PLA: not the 8-bit pattern
        std::vector<Insn> v;
        uint32_t a = t;
        for (int k = 0; k < 40; k++) {
            size_t av; const uint8_t *p = am.at(a, av);
            if (!p) break;
            Insn in; std::string why;
            if (!dec.decode(p, std::min<size_t>(av, 0x10000 - (a & 0xFFFF)), a, 1, 1, in, why)) break;
            v.push_back(in);
            a += in.len;
            uint8_t op = in.b[0];
            if (op == 0x60 || op == 0x6B || op == 0x40 || op == 0x00 || op == 0x6C || op == 0x7C) break;   // jmp abs: keep scanning (loop back)
        }
        // the helper's own returns: every call site is emulated (or left undecoded), so its
        // pushed-address return is not a dispatch
        auto markExits = [&]() { for (auto &in : v) if (in.b[0] == 0x60 || in.b[0] == 0x6B || in.b[0] == 0x40) { out.varExits.insert(in.addr); helperExits[t].insert(in.addr); } };
        bool takesRet = false;                             // pla / tsx: could be an inline-string helper
        for (auto &in : v) if (in.b[0] == 0x68 || in.b[0] == 0xBA) takesRet = true;
        for (auto &in : v)                                 // an immediate in the helper is rewritten elsewhere: its value is unknown
            for (uint32_t q = 1; takesRet && q < in.len; q++)
                if (patched.count(in.addr + q)) {
                    patchedHelper[t] = in.addr + q;     // its sites stay undecoded with a note
                    varKind[t] = 11; markExits();
                    return 11;
                }
        // other shapes that take the return address (two pla before any exit, or tsx and a
        // read of the stack frame at $0101-$0104,x): proven per site only by emulation
        // (kind 10), and kept only when the helper is seen reading through the return address
        auto loose = [&]() -> int {
            if (st0.x == 0 || revoked.count(t)) return 0;
            int pl = 0; bool tsx = false;
            for (auto &in : v) {
                uint8_t op = in.b[0];
                if (op == 0x68) { if (++pl >= 2) break; continue; }
                if (op == 0xBA) { tsx = true; continue; }
                if (tsx && in.len == 3 && (op == 0xBD || op == 0xBC || op == 0x1D || op == 0x3D || op == 0x5D || op == 0x7D || op == 0xDD) &&
                    in.b[2] == 0x01 && in.b[1] >= 0x01 && in.b[1] <= 0x04) { pl = 2; break; }
                if (op == 0x60 || op == 0x6B || op == 0x40 || op == 0x4C || op == 0x6C || op == 0x20) break;
            }
            if (pl < 2) return 0;
            varKind[t] = 10; markExits();
            return 10;
        };
        // pla / sta P / pla / sta P+1  (stores to zero page or absolute)
        if (v.size() < 6 || v[0].b[0] != 0x68 || v[2].b[0] != 0x68) return loose();
        auto stAddr = [](const Insn &i, uint32_t &x) {
            if (i.b[0] == 0x85) { x = i.b[1]; return true; }
            if (i.b[0] == 0x8D) { x = i.b[1] | (i.b[2] << 8); return true; }
            return false;
        };
        uint32_t P, P1;
        if (!stAddr(v[1], P) || !stAddr(v[3], P1) || P1 != P + 1 || P > 0xFF) return loose();
        bool inc = false, offByOne = false, ret = false, oddBranch = false; int y = -1, yAtRd = -1, kind = 0;
        size_t rd = 0;
        for (size_t i = 4; i < v.size(); i++) {
            const Insn &in = v[i]; uint8_t op = in.b[0];
            if ((op == 0xE6 || op == 0xEE) && in.b[1] == P && !rd) inc = true;
            if (op == 0xA0 && in.len == 2) y = in.b[1];
            if (!rd && (op == 0xB1 || (op == 0xB2 && dec.cpu() != Cpu::C6502)) && in.b[1] == P) {
                rd = i; yAtRd = y; offByOne = inc || (op == 0xB1 && y == 1);
                continue;
            }
            if (rd && !kind && (op == 0xF0 || op == 0xD0 || op == 0x30 || op == 0x10)) {
                uint32_t tg = (in.addr + 2 + (int8_t)in.b[1]) & 0xFFFF;
                bool back = tg <= (v[rd].addr & 0xFFFF);
                if (op == 0xF0 && !back) kind = 4;               // beq exit on zero
                else if (op == 0xD0 && back) kind = 4;           // bne loop while non-zero
                else if ((op == 0x30 && !back) || (op == 0x10 && back)) kind = 5;   // ends at bit 7 set
                else if ((op == 0x10 && !back) || (op == 0x30 && back)) kind = 6;   // ends at bit 7 clear
                else oddBranch = true;
            }
            if (op == 0x6C && (uint32_t)(in.b[1] | (in.b[2] << 8)) == P) ret = true;   // jmp (P)
            if (op == 0x60 && i >= 2 && v[i - 1].b[0] == 0x48) {
                for (size_t j = i - 1; j-- > 4;) if (v[j].b[0] == 0x48) { ret = true; break; }   // pha .. pha rts
            }
        }
        // length-prefixed: the first byte read is kept (sta N / tax) and used as the loop bound
        if (rd && rd + 1 < v.size()) {
            const Insn &k1 = v[rd + 1]; uint32_t N = 0;
            bool lenForm = false;
            const bool haveN = stAddr(k1, N);     // no sta N: the cpy N pattern cannot match
            if (haveN) {
                for (size_t i = rd + 2; i < v.size() && !lenForm; i++) {
                    uint8_t o2 = v[i].b[0];
                    uint32_t opd = v[i].len == 2 ? v[i].b[1] : v[i].len == 3 ? (uint32_t)(v[i].b[1] | (v[i].b[2] << 8)) : 0xFFFFFFFF;
                    if ((o2 == 0xC4 || o2 == 0xCC || o2 == 0xE4 || o2 == 0xEC || o2 == 0xC5 || o2 == 0xCD || o2 == 0xC6 || o2 == 0xCE) && opd == N) lenForm = true;
                }
            } else if (k1.b[0] == 0xAA) {
                for (size_t i = rd + 2; i + 1 < v.size() && !lenForm; i++)
                    if (v[i].b[0] == 0xCA && (v[i + 1].b[0] == 0xD0 || v[i + 1].b[0] == 0x10)) lenForm = true;
            }
            if (lenForm) {
                if (revoked.count(t)) return 0;      // revoked G1 rule: as before, no model and no note
                kind = 7;
                // model the skip: Y starts at the count's offset, the loop raises it to N
                // (cpy N / bcs exit), extra iny's follow, and the return adds Y to P
                size_t lastBack = 0; bool cpyBcs = false, tyaAdc = false; uint32_t extra = 0, cin = 0; std::string carryWhy;
                uint32_t exitAt = 0, exitBr = 0; bool haveExit = false;   // carry is 1 here: bcs taken / bcc not taken after cpy N
                // carry at v[j] when entered straight from the loop exit with carry 1: clc/sec set it,
                // instructions that leave it alone pass it on, anything else makes it unknown
                auto exitCarry = [&](uint32_t from, size_t j) -> int {
                    size_t s0 = v.size();
                    for (size_t q = 0; q < j; q++) if (v[q].addr == from) { s0 = q; break; }
                    if (s0 >= j) return -1;
                    int c = 1;
                    for (size_t q = s0; q < j; q++) {
                        switch (v[q].b[0]) {
                        case 0x18: c = 0; break;
                        case 0x38: c = 1; break;
                        case 0xEA: case 0xC8: case 0x88: case 0xE8: case 0xCA:            // nop iny dey inx dex
                        case 0x98: case 0xA8: case 0x8A: case 0xAA: case 0x9A: case 0xBA: // transfers
                        case 0xA9: case 0xA5: case 0xAD: case 0xA0: case 0xA4: case 0xAC: case 0xA2: case 0xA6: case 0xAE:   // loads
                        case 0xB1: case 0xB2: case 0xB5: case 0xBD: case 0xB9:
                        case 0x85: case 0x8D: case 0x84: case 0x8C: case 0x86: case 0x8E: case 0x64: case 0x9C:   // stores
                        case 0x48: case 0x68: case 0x08: case 0x5A: case 0xDA: case 0x7A: case 0xFA:   // push/pull (not plp)
                        case 0xE6: case 0xEE: case 0xC6: case 0xCE:                       // inc/dec mem
                        case 0x29: case 0x09: case 0x49: case 0x24: case 0x2C: case 0x89:  // and ora eor bit
                            break;
                        default: return -1;                                               // writes carry, branches, or unknown
                        }
                    }
                    return c;
                };
                for (size_t i = rd + 2; i < v.size(); i++) {
                    const Insn &in = v[i]; uint8_t o2 = in.b[0];
                    if (haveN && !haveExit && (o2 == 0xC4 || o2 == 0xCC) && i + 1 < v.size() && (v[i + 1].b[0] == 0xB0 || v[i + 1].b[0] == 0x90) &&
                        (in.len == 2 ? in.b[1] : (uint32_t)(in.b[1] | (in.b[2] << 8))) == N) {
                        const Insn &br = v[i + 1];
                        exitBr = br.addr;
                        if (br.b[0] == 0xB0) { cpyBcs = true; exitAt = (br.addr & 0xFF0000) | ((br.addr + 2 + (int8_t)br.b[1]) & 0xFFFF); }
                        else exitAt = br.addr + 2;
                        haveExit = true;
                    }
                    bool back = (o2 == 0x4C && (uint32_t)(in.b[1] | (in.b[2] << 8)) <= (in.addr & 0xFFFF)) ||
                                (in.len == 2 && (o2 & 0x1F) == 0x10 && (int8_t)in.b[1] < 0);
                    if (back) { lastBack = i; extra = 0; }
                    else if (lastBack && o2 == 0xC8) extra++;
                    if (!lastBack && cpyBcs && o2 == 0x98 && i + 1 < v.size() && v[i + 1].b[0] == 0x65 && v[i + 1].b[1] == P) {
                        // the return-address add sits before any loop back-edge (e.g. on the bcs fall-through):
                        // the loop-exit carry does not reach it
                        carryWhy = "carry unknown at the return-address add"; break;
                    }
                    if (lastBack && o2 == 0x98) {
                        // G1: adc adds the operand plus the carry; track it from clc/sec
                        // (-1 = unknown) through the low add and into the high-byte add
                        int c = -1; size_t j = i + 1, lsd = 0;
                        for (; j < v.size() && j < i + 3; j++) {
                            uint8_t o3 = v[j].b[0];
                            if (o3 == 0x18) { c = 0; lsd = j; }
                            else if (o3 == 0x38) { c = 1; lsd = j; }
                            else if (o3 == 0x65 && v[j].b[1] == P) { tyaAdc = true; break; }
                            else if (o3 != 0xEA) break;
                        }
                        if (!tyaAdc) break;
                        if (c >= 0) {
                            // explicit clc/sec right before the adc: holds only if nothing joins after it
                            // and no unresolved indirect jump could land on the adc (checked after the image is followed)
                            if (carryRevoked.count(t)) c = -1;
                            else out.carryClaims[t] = Analysis::CarryClaim{v[lsd].addr + 1, v[j].addr, 0, false, t, v.back().addr + v.back().len};
                        }
                        if (c < 0 && haveExit) {
                            c = exitCarry(exitAt, j);
                            // the carry holds only on the straight path: record what must not join in
                            // (checked after the whole image is followed); the last clc/sec in the
                            // exit block sets it itself, then only joins after it matter
                            size_t s0 = 0; while (s0 < j && v[s0].addr != exitAt) s0++;
                            size_t ls = j;
                            for (size_t q = s0; q < j; q++) if (v[q].b[0] == 0x18 || v[q].b[0] == 0x38) ls = q;
                            if (c >= 0) {
                                bool br = ls == j;
                                if (carryRevoked.count(t)) c = -1;
                                else out.carryClaims[t] = Analysis::CarryClaim{br ? exitAt : v[ls].addr + 1, v[j].addr, exitBr, br, t, v.back().addr + v.back().len};
                            }
                        }
                        if (c < 0) { carryWhy = "carry unknown at the return-address add"; break; }
                        cin = (uint32_t)c;
                        // high byte: lda P+1 ... adc #k; the low add's carry-out flows in unless clc/sec resets it
                        bool hiLd = false; int hc = -2;      // -2 = propagated from the low add
                        for (size_t k = j + 1; k < v.size(); k++) {
                            const Insn &h2 = v[k]; uint8_t o4 = h2.b[0];
                            if (o4 == 0x60 || o4 == 0x6B || o4 == 0x40) break;
                            if ((o4 == 0xA5 && h2.b[1] == P + 1) || (o4 == 0xAD && (uint32_t)(h2.b[1] | (h2.b[2] << 8)) == P + 1)) { hiLd = true; continue; }
                            if (!hiLd) continue;
                            if (o4 == 0x18) hc = 0;
                            else if (o4 == 0x38) hc = 1;
                            else if (o4 == 0x69) {
                                uint32_t hk = h2.b[1] + (hc == 1 ? 1u : 0u);
                                if (hk) carryWhy = "high-byte add adds " + std::to_string(hk) + " page(s)";
                                else if (hc == 0) carryWhy = "clc before the high-byte add drops the low-byte carry";
                                break;
                            }
                            else if (o4 != 0x85 && o4 != 0x8D && o4 != 0x48 && o4 != 0xEA) break;   // other forms: leave as before
                        }
                        break;
                    }
                }
                if (!carryWhy.empty() && cpyBcs && yAtRd >= 0) {
                    out.notes.push_back("length-prefixed helper " + hex6(t) + ": " + carryWhy + "; inline length not applied");
                    carryUnk[t] = carryWhy.rfind("carry unknown", 0) == 0 ? "depends on the carry" : "depends on the high-byte add";
                    return 0;
                }
                if (cpyBcs && tyaAdc && yAtRd >= 0) lenModel[t] = LenModel{inc ? 1u : 0u, (uint32_t)yAtRd, extra + cin};
            }
        }
        if (kind == 7 || st0.x == 0) {     // G1 length-prefixed (and 16-bit index): the static rules
            if (!rd || !offByOne || !kind || !ret || oddBranch || revoked.count(t)) return 0;
            varKind[t] = kind; markExits();
            return kind;
        }
        // G2/G3: pulls its return address into a zero-page pointer and reads through it:
        // each call site is proven by emulating the helper (kind 8)
        if (!rd) return loose();
        varKind[t] = revoked.count(t) ? 9 : 8; markExits();     // 9: rule revoked, but a site that cannot be proven still stops flow
        return varKind[t];
    };
    auto termLen = [&](uint32_t at, int kind, uint32_t t = 0) -> uint32_t {   // bytes up to and including the terminator, 0 = none
        size_t av; const uint8_t *p = am.at(at, av);
        if (!p) return 0;
        for (uint32_t i = 0; i < std::min<size_t>(av, 256); i++) {
            uint8_t b = p[i];
            if (kind == 7) {
                auto lm = lenModel.find(t);
                uint32_t n = lm == lenModel.end() ? (uint32_t)b + 1 : lm->second.base + std::max<uint32_t>(lm->second.y0, b) + lm->second.extra;
                return n >= 1 && n <= av ? n : 0;
            }
            if ((kind == 4 && b == 0) || (kind == 5 && (b & 0x80)) || (kind == 6 && !(b & 0x80))) return i + 1;
        }
        return 0;
    };

    // RTS/RTL dispatch through an indexed table (lda T+1,y / pha / lda T,y / pha / rts ...);
    // candidates are bounded and added with the other tables below
    struct RtsCand { uint32_t site; int kind; uint32_t lo, hi, bank; State st; uint32_t ld = 0; bool idxY = false; };
    std::vector<RtsCand> rtsCands;
    std::set<uint32_t> rtsSites;
    // instructions allowed between the loads and pushes: they change neither A,
    // the index register nor the stack
    auto neutral = [](uint8_t op, bool idxY) {
        switch (op) {
        case 0x85: case 0x8D: case 0x95: case 0x9D: case 0x99: case 0x81: case 0x91:        // sta
        case 0x86: case 0x8E: case 0x96: case 0x84: case 0x8C: case 0x94:                   // stx sty
        case 0x64: case 0x9C: case 0x74: case 0x9E:                                         // stz
        case 0x18: case 0x38: case 0x58: case 0x78: case 0xD8: case 0xF8: case 0xB8: case 0xEA:
        case 0xE6: case 0xEE: case 0xF6: case 0xFE: case 0xC6: case 0xCE: case 0xD6: case 0xDE:   // inc/dec mem
        case 0xC9: case 0xC5: case 0xCD: case 0xE0: case 0xE4: case 0xEC: case 0xC0: case 0xC4: case 0xCC:
        case 0x24: case 0x2C:
            return true;
        case 0xA2: case 0xA6: case 0xAE: case 0xE8: case 0xCA: return idxY;    // x changes: fine when indexing by y
        case 0xA0: case 0xA4: case 0xAC: case 0xC8: case 0x88: return !idxY;   // y changes: fine when indexing by x
        default: return false;
        }
    };

    // a conditional branch whose flag is known on its (joined) in-state: 1 always taken, 0 never, -1 either
    auto brKnown = [&](const Insn &bi, const State &bs) -> int {
        uint8_t bo = bi.b[0];
        if ((bo & 0x1F) != 0x10) return -1;
        int8_t f = bo < 0x50 ? bs.n : bo < 0x90 ? bs.v : bo < 0xD0 ? bs.c : bs.z;
        return f < 0 ? -1 : f == ((bo >> 5) & 1);
    };
    // ---- self-modifying code: the forms an instruction may run as ----
    // Every byte a store may reach (opcode, operand, branch offset) holds the encoded value and/or the
    // one known value a store writes (only the stored value when that store runs first on every path:
    // domBytes). An unknown value, or several values, stops decoding there when it is the opcode or an
    // operand that decides flow, the stack, D or the widths; a plain data operand (an address or
    // immediate of a load, store or ALU op) only makes that instruction's results unknown.
    struct PB { bool unk = false, wide = false; std::vector<int> v; };
    auto pbAt = [&](uint32_t x, PB &b) -> bool {      // false: no store reaches x
        if (preStore.count(x)) return false;
        bool hit = false;
        if (patched.count(x)) { b.unk = true; hit = true; }
        for (auto &r : mods) {
            if ((r.u || r.d) && !o.strictSmc) continue;       // fully unknown target: assumed not to modify code
            if (!(r.n == ~0u || ((r.lo & 0xFF0000) == (x & 0xFF0000) && (uint32_t)((x - r.lo) & 0xFFFF) < r.n))) continue;
            hit = true;
            if (r.n == 1 && r.v >= 0) { if (std::find(b.v.begin(), b.v.end(), r.v) == b.v.end()) b.v.push_back(r.v); }
            else if (r.n > 4) b.wide = true;     // wide or unbounded range: an unknown value (see opts)
            else b.unk = true;
        }
        return hit;
    };
    auto sensitive = [&](uint8_t op) {    // operand decides flow, the stack, D or the widths
        if ((op & 0x1F) == 0x10 || op == 0x4C || op == 0x20 || op == 0x6C) return true;
        if (dec.cpu() != Cpu::C6502 && (op == 0x80 || op == 0x7C)) return true;
        if (dec.cpu() == Cpu::C65C02 && (op & 0x0F) == 0x0F) return true;     // bbr/bbs offset
        if (w816 && (op == 0x82 || op == 0x5C || op == 0x22 || op == 0xFC || op == 0xDC || op == 0x62 || op == 0xC2 || op == 0xE2 || op == 0xF4 || op == 0xD4)) return true;
        return false;
    };
    auto sameInsn = [](const Insn &x, const Insn &y) { return x.len == y.len && !memcmp(x.b, y.b, x.len); };
    auto patchVariants = [&](uint32_t a, const uint8_t *p, size_t avail, const State &st, const Insn &orig, std::vector<Insn> &vars, bool &unkOpnd, int &wide, std::string &sw) -> bool {
        size_t nb = std::min<size_t>(avail, 4);
        PB pb[4]; bool hit[4] = {false, false, false, false}, any = false;
        for (size_t q = 0; q < nb; q++) { hit[q] = pbAt((a & 0xFF0000) | ((a + q) & 0xFFFF), pb[q]); any = any || hit[q]; }
        if (!any) return true;
        int curOp = -1;
        auto opts = [&](size_t q, std::vector<int> &ov) -> bool {     // false: unknown or several values
            ov.clear();
            if (q >= nb || !hit[q]) { if (q < nb) ov.push_back(p[q]); return true; }
            ov.push_back(p[q]);
            // a wide-range store (an index or pointer not bounded to a few bytes, a long or unknown-length
            // block move) writes an unknown value: the byte is unknown, except a rep/sep operand, whose
            // instruction stays a width setter that leaves e/m/x unknown (the widths are not trusted)
            if (pb[q].wide) { if (q > 0 && (curOp == 0xC2 || curOp == 0xE2) && pb[q].v.empty() && !pb[q].unk) wide |= 2; else return false; }
            if (pb[q].v.empty() && !pb[q].unk) return true;
            if (pb[q].unk || pb[q].v.size() > 1) return false;
            if (domBytes.count((a & 0xFF0000) | ((a + q) & 0xFFFF))) ov.clear();
            if (std::find(ov.begin(), ov.end(), pb[q].v[0]) == ov.end()) ov.push_back(pb[q].v[0]);
            return true;
        };
        std::vector<int> o0;
        if (!opts(0, o0)) { sw = "opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)"; return false; }
        vars.clear();
        for (int c0 : o0) {
            uint8_t buf[4] = {0, 0, 0, 0};
            for (size_t q = 0; q < nb; q++) buf[q] = p[q];
            buf[0] = (uint8_t)c0;
            Insn t; std::string why;
            if (!dec.decode(buf, nb, a, st.m, st.x, t, why)) { sw = "instruction as changed by a store cannot be decoded (" + why + ")"; return false; }
            std::vector<std::vector<int>> oo(t.len); curOp = c0;
            for (int q = 1; q < t.len; q++)
                if (!opts(q, oo[q])) {
                    if (sensitive((uint8_t)c0)) { sw = "operand may be changed by a store to an unknown value or to one of several values (self-modifying code)"; return false; }
                    unkOpnd = true;
                }
            int idx[4] = {0, 0, 0, 0};
            for (;;) {
                for (int q = 1; q < t.len; q++) buf[q] = (uint8_t)oo[q][idx[q]];
                Insn u;
                if (!dec.decode(buf, nb, a, st.m, st.x, u, why)) { sw = "instruction as changed by a store cannot be decoded (" + why + ")"; return false; }
                bool dup = false;
                for (auto &v : vars) if (sameInsn(v, u)) dup = true;
                if (!dup) vars.push_back(u);
                int q = 1;
                for (; q < t.len; q++) { if (++idx[q] < (int)oo[q].size()) break; idx[q] = 0; }
                if (q >= t.len) break;
            }
        }
        std::stable_partition(vars.begin(), vars.end(), [&](const Insn &v) { return sameInsn(v, orig); });   // the encoded form first
        return true;
    };
    long steps = 0;
    auto run = [&]() {
    while (!work.empty()) {
        if (++steps > o.maxSteps) { out.notes.push_back("analysis step limit reached; output may be incomplete"); work.clear(); break; }
        uint32_t a = work.front();
        work.pop_front();
        curSrc = a;
        State st = in[a];
        size_t avail;
        const uint8_t *p = am.at(a, avail);
        size_t inBank = 0x10000 - (a & 0xFFFF);
        // the 65816 (and 6502/65C02 at $FFFF) fetches operand bytes past the bank end from the
        // start of the same bank (PBR never increments): build them in bank order
        uint8_t wrapBuf[4];
        if (p && avail > inBank) avail = inBank;
        if (p && inBank < 4) {
            size_t n = 0;
            for (; n < 4; n++) { size_t av; const uint8_t *q = am.at((a & 0xFF0000) | ((a + n) & 0xFFFF), av); if (!q) break; wrapBuf[n] = *q; }
            p = wrapBuf; avail = n;
        }
        Insn ins;
        std::string why;
        if (!dec.decode(p, avail, a, st.m, st.x, ins, why)) {
            decoded.erase(a);
            out.bad[a] = why;
            continue;
        }
        if (inData(dataR, a, ins.len)) { decoded.erase(a); out.bad[a] = "overlaps data/table"; continue; }
        if (!relocs.empty()) {      // a relocated field must start at the first operand byte
            bool mis = false;
            auto it = relocs.lower_bound(a >= 4 ? a - 4 : 0);
            for (; it != relocs.end() && it->first < a + ins.len; ++it) {
                if (it->first + it->second <= a) continue;
                // accept any field lying wholly inside the operand bytes (e.g. MVN/MVP
                // 1-byte bank fields at +1 and +2); reject one that covers the opcode
                // byte or crosses the instruction's end
                if (it->first < a + 1 || it->first + it->second > a + ins.len) mis = true;
            }
            if (mis) { decoded.erase(a); out.bad[a] = "relocation misaligned with operand (likely data, not code)"; continue; }
        }
        out.bad.erase(a);
        decoded[a] = CodeInsn{ins, st};
        std::vector<Insn> vars{ins};
        bool unkOpnd = false; int wide = 0;    // wide: 1 opcode, 2 operand reached by a wide-range store
        if (!patched.empty() || !mods.empty()) {
            std::string sw;
            if (!patchVariants(a, p, avail, st, ins, vars, unkOpnd, wide, sw)) { decoded.erase(a); out.bad[a] = sw; continue; }
            if (vars.size() != 1 || !sameInsn(vars[0], ins)) {
                std::vector<CodeInsn> cv; std::string pn;
                bool encRuns = sameInsn(vars[0], ins);
                for (auto &v : vars) {
                    cv.push_back(CodeInsn{v, st});
                    if (sameInsn(v, ins)) continue;
                    std::string bs; for (int q = 0; q < v.len; q++) bs += fmt("%s%02X", q ? " " : "", v.b[q]);
                    pn += (pn.empty() ? "" : ", ") + v.mnemonic + " (" + bs + ")";
                }
                out.variants[a] = cv;
                bool perHint = false;     // the proof needs a user noreturn hint: say so, never state it as proven
                if (!encRuns) for (uint32_t q = 0; q < ins.len; q++) if (out.hintDomIn.count(a + q)) perHint = true;
                out.patchNote[a] = std::string(encRuns ? "may also run as " : "changed by a store before it runs: runs as ") + pn + (perHint ? " (per noreturn hint)" : "") + " (self-modifying code)";
            } else { out.variants.erase(a); out.patchNote.erase(a); }
        }
        for (size_t vi = 0; vi < vars.size(); vi++) {
        const Insn ins = vars[vi];
        State ns = step(ins, st);
        if (unkOpnd || wide) ns.c = ns.z = ns.n = ns.v = -1;     // an operand with an unknown value: results unknown
        uint8_t op = ins.b[0];
        // a wide-range store (an index or pointer not bounded to a few bytes) may reach this instruction:
        // decoded as encoded, as before; nothing it leaves is trusted
        if (wide && w816 && ((wide & 1) || op == 0xC2 || op == 0xE2)) { ns.e = ns.m = ns.x = -1; ns.normalize(); }
        if (wide == 2 && ins.len > 1 && ((op & 0x1F) == 0x10 || op == 0x80 || op == 0x82 || op == 0x4C || op == 0x5C || op == 0x20 || op == 0x22 || op == 0xFC || op == 0x62 || op == 0x6C || op == 0x7C || op == 0xDC))
            out.dispatch[a] = "unknown: transfer target may be modified by a store (self-modifying code); encoded target followed";
        uint32_t K = a & 0xFF0000;
        uint32_t next = K | ((a + ins.len) & 0xFFFF);    // the PC wraps inside the program bank
        int32_t d8 = (int8_t)ins.b[1];
        int32_t d16 = (int16_t)(ins.b[1] | (ins.b[2] << 8));
        uint32_t abs16 = K | (uint32_t)(ins.b[1] | (ins.b[2] << 8));
        uint32_t abs24 = (uint32_t)(ins.b[1] | (ins.b[2] << 8) | (ins.b[3] << 16));
        auto rel = [&](int32_t d) { return K | ((next + d) & 0xFFFF); };
        auto call = [&](uint32_t t) {
            label(t, LK_SUB);
            flow(t, ns);
            if (h.noreturn.count(t)) { out.noretSites.insert(a); out.hintNoret.insert(a); return; }
            if (h.noreturn.count(a)) { out.dispatch[a] = "does not return (assumed by noreturn hint)"; out.noreturnCalls++; out.noretSites.insert(a); out.hintNoret.insert(a); return; }
            // Apple II Monitor/BASIC ROM entry points that never return: only when the ROM is
            // provably mapped (no decoded access may switch the language card to RAM)
            if (o.platform == Platform::ProDOS8 && op == 0x20 && romNoReturn(t)) {
                if (!out.lcRiskIn) {
                    out.dispatch[a] = "does not return (Apple II ROM " + hex4(t) + ")";
                    out.noreturnCalls++; out.noretSites.insert(a); out.romNoret = true; return;
                }
                if (out.romCallKept.insert({t, a}).second)
                    out.notes.push_back("call to ROM " + hex4(t) + " at " + hex6(a) + " followed as an ordinary call: decoded code may switch the language card ($C080-$C08F) and map RAM over the ROM");
            }
            // GS/OS _SysFailMgr (ldx #$1503; jsl $E10000) never returns
            if (o.platform == Platform::GSOS && op == 0x22 && t == 0xE10000) {
                const CodeInsn *p = pred(a);
                if (p && p->in.len == 3 && p->in.b[0] == 0xA2 && p->in.b[1] == 0x03 && p->in.b[2] == 0x15 && !out.sysFailBadIn.count(a)) {
                    out.sysFailIn.insert(a);
                    out.dispatch[a] = "does not return (_SysFailMgr)";
                    out.noreturnCalls++; out.noretSites.insert(a); return;
                }
            }
            int vk = detectVar(t, ns);
            if (vk == 11) {
                std::string why = "the helper's immediate operand at " + hex6(patchedHelper[t]) + " is modified by a store elsewhere (self-modifying code)";
                out.dispatch[a] = "unknown: inline string after jsr " + hex6(t) + " not proven (" + why + ")";
                out.notes.push_back("inline-string helper " + hex6(t) + " called at " + hex6(a) + ": " + why + "; bytes after the call left undecoded");
                return;
            }
            if (vk == 9) {
                EmuResult er = emuInline(am, dec.cpu(), t, a, ns.d, cswWhy, patched, mods);
                out.varExits.insert(er.exits.begin(), er.exits.end());
                if (!er.ok) {
                    out.dispatch[a] = "unknown: inline string after jsr " + hex6(t) + " not proven (" + er.why + ")";
                    out.notes.push_back("inline-string helper " + hex6(t) + " called at " + hex6(a) + ": " + er.why + "; bytes after the call left undecoded");
                    return;
                }
                vk = 0;
            }
            if (vk == 8 || vk == 10) {
                EmuResult er = emuInline(am, dec.cpu(), t, a, ns.d, cswWhy, patched, mods);
                if (vk == 10 && !er.ptrRead) {                    // not seen reading inline bytes: an ordinary call,
                    out.looseOrdExits.insert(helperExits[t].begin(), helperExits[t].end());   // its returns get the stack check
                    goto ordinary;                               // unless another site proves the helper
                }
                if (vk == 10) out.looseProvedExits.insert(helperExits[t].begin(), helperExits[t].end());
                out.varExits.insert(er.exits.begin(), er.exits.end());
                std::string why = er.why;
                uint32_t n = 0;
                if (er.ok) {
                    if (er.ret == next) goto ordinary;           // returns to the next instruction: no inline bytes
                    size_t av; const uint8_t *ip = am.at(next, av);
                    if (er.ret < next || !ip || er.ret - next > av) why = fmt("returns to $%06X, not past the call", er.ret);
                    else if (inData(dataR, next, er.ret - next)) why = "inline bytes overlap known data";
                    else if (t >= next && t < er.ret) {        // the "string" runs into the helper itself: not an inline helper
                        out.varMisfit.insert(t); return;
                    }
                    else n = er.ret - next;
                }
                if (!n) {
                    out.dispatch[a] = "unknown: inline string after jsr " + hex6(t) + " not proven (" + why + ")";
                    out.notes.push_back("inline-string helper " + hex6(t) + " called at " + hex6(a) + ": " + why + "; bytes after the call left undecoded");
                    return;
                }
                const uint8_t *ip; { size_t av; ip = am.at(next, av); }
                int sk = 0;                                       // per-site terminator form
                uint8_t last = ip[n - 1];
                if (last == 0) sk = 4;
                else {
                    bool flip = true;
                    for (uint32_t q = 0; q + 1 < n; q++) if ((ip[q] ^ last) & 0x80) {} else { flip = false; break; }
                    if (flip) sk = (last & 0x80) ? 5 : 6;
                }
                static const char *tn8[] = {"zero-terminated", "bit-7-set-terminated", "bit-7-clear-terminated"};
                std::string form = sk ? tn8[sk - 4] : "inline bytes";
                out.inlineData[next] = InlineBlock{n, sk, form + (sk ? " inline string" : "") + " after call to " + hex6(t) + " (routine reads past its return address)"};
                out.varAutoBlocks[t].push_back({next, n});       // flow landing inside revokes the rule (as for G1)
                dataAll[next] = std::max(dataAll[next], n);
                dataR = mergeRanges(dataAll);
                out.dispatch[a] = std::string("returns past ") + std::to_string(n) + " inline byte" + (n == 1 ? "" : "s") + " (" + form + ")";
                out.varInlineSites++;
                if (er.usedCSW) out.g2AssumeCSW = true;
                if (er.usedD) out.g2AssumeD = true;
                out.varInlineRoutines[t] = sk ? sk : 8;
                State back = ns; back.c = -1;
                flow(next + n, back);
                return;
            } else if (vk) {
                uint32_t n = termLen(next, vk, t);
                if (n && !inData(dataR, next, n)) {
                    static const char *tn[] = {"zero-terminated", "bit-7-set-terminated", "bit-7-clear-terminated", "length-prefixed"};
                    out.inlineData[next] = InlineBlock{n, vk, std::string(tn[vk - 4]) + " inline string after call to " + hex6(t) + (h.varInlines.count(t) ? " (hint)" : " (routine reads past its return address)")};
                    if (!h.varInlines.count(t)) out.varAutoBlocks[t].push_back({next, n});
                    dataAll[next] = std::max(dataAll[next], n);
                    dataR = mergeRanges(dataAll);
                    out.dispatch[a] = std::string("returns past ") + std::to_string(n) + " inline byte" + (n == 1 ? "" : "s") + " (" + tn[vk - 4] + ")";
                    out.varInlineSites++;
                    out.varInlineRoutines[t] = vk;
                    State back = ns; back.c = -1;
                    flow(next + n, back);
                }
                if (!n && !h.varInlines.count(t)) out.varMisfit.insert(t);   // this site does not fit the rule
                return;     // no terminator in reach: do not guess a return point
            }
            ordinary:
            if (auto cu = carryUnk.find(t); cu != carryUnk.end()) {   // skip length not modelled: leave the bytes undecoded
                out.dispatch[a] = "unknown: inline length after jsr " + hex6(t) + " " + cu->second;
                return;
            }
            if (stopAfter.count(t)) {
                if (textZ(am, next)) {      // unknown return: leave the bytes undecoded
                    out.dispatch[a] = "unknown: possible inline data after jsr " + hex6(t) + "; see suggested hint";
                    out.unknownStops[t]++;
                    out.heldBack[next] = textZ(am, next) + 1;
                    return;
                }
            }
            if (!am.contains(t) && !textZ(am, next)) out.stopMisfit.insert(t);   // a decoded site that does not look like a string
            auto il = inl.find(t);
            if (il != inl.end()) {
                uint32_t n = il->second.first;
                if (n == 0) return;          // guard: a zero-length inline block is ignored
                size_t av;
                if (!am.at(next, av) || av < n) return;
                static const char *kinds[] = {"inline hint", "GS/OS inline call number + parameter block pointer", "ProDOS 8 MLI command + parameter list pointer"};
                out.inlineData[next] = InlineBlock{n, il->second.second, std::string(kinds[il->second.second]) + " after call to " + hex6(t)};
                dataAll[next] = std::max(dataAll[next], n);
                dataR = mergeRanges(dataAll);
                out.dispatch[a] = std::string("returns past ") + std::to_string(n) + " inline byte" + (n == 1 ? "" : "s");
                const uint8_t *ip = am.at(next, av);
                // the parameter pointer becomes a label when it points into the image
                uint32_t pp = 0;
                if (il->second.second == 2) pp = K | (uint32_t)(ip[1] | (ip[2] << 8));
                if (il->second.second == 1 && ip[5] == 0) pp = (uint32_t)(ip[2] | (ip[3] << 8) | (ip[4] << 16));
                if (pp && am.contains(pp)) label(pp, LK_PARAM);
                // calls that do not return: ProDOS 8 QUIT ($65), GS/OS Quit ($2029, P16 $0029)
                bool quit = (il->second.second == 2 && ip[0] == 0x65) ||
                            (il->second.second == 1 && ((ip[0] | (ip[1] << 8)) == 0x2029 || (ip[0] | (ip[1] << 8)) == 0x0029));
                // QUIT returns only when it fails (C=1): the fall-through is kept with carry set
                if (quit) out.dispatch[a] += "; QUIT returns only on error (C=1)";
                next += n;
            }
            auto r = h.returns.find(t);
            State back = ns;
            if (r != h.returns.end()) { back = r->second; back.d = ns.d; back.depth = ns.depth; for (int i = 0; i < 4; i++) { back.sm[i] = ns.sm[i]; back.sx[i] = ns.sx[i]; } back.normalize(); }
            back.c = -1;
            if (il != inl.end()) {
                const uint8_t *ip; size_t av;
                if ((ip = am.at(K | ((a + ins.len) & 0xFFFF), av)) && av >= 2 &&
                    ((il->second.second == 2 && ip[0] == 0x65) || (il->second.second == 1 && ((ip[0] | (ip[1] << 8)) == 0x2029 || (ip[0] | (ip[1] << 8)) == 0x0029)))) back.c = 1;
            }
            flow(next, back);
        };
        // push-address-minus-1 + RTS/RTL dispatch (straight-line pattern only)
        auto pushDispatch = [&]() {
            if (!o.followTables) return;
            const CodeInsn *p1 = pred(a);
            if (!p1) return;
            if ((op == 0x60 || op == 0x6B) && !rtsSites.count(a)) {
                // walk back: pha, lda T,idx pairs (skipping neutral instructions)
                bool idxY = false; int idxKnown = 0;
                auto skip = [&](const CodeInsn *q) -> const CodeInsn * {
                    for (int k = 0; q && k < 6; k++) {
                        bool nt = idxKnown ? neutral(q->in.b[0], idxY) : (neutral(q->in.b[0], true) && neutral(q->in.b[0], false));
                        if (!nt) break;
                        q = pred(q->in.addr);
                    }
                    return q;
                };
                std::vector<std::pair<uint32_t, int>> loads;   // (base, 1 = 8-bit A / 2 = 16-bit A), innermost first
                // after the last push only the stack matters: register loads/transfers are fine too
                auto tailOk = [&](uint8_t o2) {
                    switch (o2) {
                    case 0xA9: case 0xA5: case 0xAD: case 0xB5: case 0xA2: case 0xA6: case 0xAE: case 0xA0: case 0xA4: case 0xAC:
                    case 0xAA: case 0xA8: case 0x8A: case 0x98: return true;
                    default: return neutral(o2, true) && neutral(o2, false);
                    }
                };
                uint32_t firstLd = 0;
                const CodeInsn *c = p1;
                for (int k = 0; c && k < 6 && tailOk(c->in.b[0]); k++) c = pred(c->in.addr);
                while (c && c->in.b[0] == 0x48 && loads.size() < 3) {
                    const CodeInsn *l = skip(pred(c->in.addr));
                    if (!l || !(l->in.b[0] == 0xB9 || l->in.b[0] == 0xBD)) break;
                    bool y = l->in.b[0] == 0xB9;
                    if (idxKnown && y != idxY) break;
                    idxY = y; idxKnown = 1; firstLd = l->in.addr;
                    loads.push_back({K | (uint32_t)(l->in.b[1] | (l->in.b[2] << 8)), c->st.m == 0 ? 2 : 1});
                    c = skip(pred(l->in.addr));
                }
                if (!loads.empty()) {
                    bool phk = c && c->in.b[0] == 0x4B;
                    RtsCand rc{a, -1, 0, 0, K, ns, firstLd, idxY};
                    bool all8 = true; for (auto &l : loads) all8 = all8 && l.second == 1;
                    if (op == 0x60 && loads.size() == 2 && all8) {
                        if (loads[1].first == loads[0].first + 1) { rc.kind = TK_RTS; rc.lo = loads[0].first; }
                        else { rc.kind = TK_SPLIT; rc.lo = loads[0].first; rc.hi = loads[1].first; }
                    } else if (op == 0x60 && loads.size() == 1 && loads[0].second == 2) {
                        rc.kind = TK_RTS; rc.lo = loads[0].first;                      // 16-bit A: one push
                    } else if (op == 0x6B && w816 && loads.size() == 3 && all8 &&
                               loads[1].first == loads[0].first + 1 && loads[2].first == loads[0].first + 2) {
                        rc.kind = TK_RTSLONG; rc.lo = loads[0].first;                  // three byte pushes
                    } else if (op == 0x6B && w816 && phk && ((loads.size() == 2 && all8) || (loads.size() == 1 && loads[0].second == 2))) {
                        if (loads.size() == 1 || loads[1].first == loads[0].first + 1) { rc.kind = TK_RTS; rc.lo = loads[0].first; }
                        else { rc.kind = TK_SPLIT; rc.lo = loads[0].first; rc.hi = loads[1].first; }
                    }
                    if (rc.kind >= 0 && o.followTables) {
                        rtsSites.insert(a);
                        rtsCands.push_back(rc);
                        out.dispatch[a] = std::string(op == 0x60 ? "rts" : "rtl") + " dispatch through table " + hex6(rc.lo) +
                                          (rc.kind == TK_SPLIT ? " (low bytes) / " + hex6(rc.hi) + " (high bytes)" : "");
                        return;
                    }
                }
            }
            uint32_t t = 0;
            std::string how;
            const Insn &i1 = p1->in;
            if (op == 0x60 && i1.b[0] == 0xF4) {                              // PEA v; RTS
                t = K | ((i1.b[1] | (i1.b[2] << 8)) + 1) % 0x10000; how = "pea+rts";
            } else if (op == 0x6B && i1.b[0] == 0xF4) {                       // PHK; PEA v; RTL
                const CodeInsn *p2 = pred(i1.addr);
                if (!p2 || p2->in.b[0] != 0x4B) return;
                t = K | ((i1.b[1] | (i1.b[2] << 8)) + 1) % 0x10000; how = "phk+pea+rtl";
            } else if (op == 0x60 && i1.b[0] == 0x48) {                       // ...; PHA; RTS
                const CodeInsn *p2 = pred(i1.addr);
                if (!p2 || p2->in.b[0] != 0xA9) return;
                if (p2->in.len == 3) {                                         // lda #v16; pha
                    t = K | ((p2->in.b[1] | (p2->in.b[2] << 8)) + 1) % 0x10000; how = "lda#+pha+rts";
                } else {                                                       // lda #>v; pha; lda #<v; pha
                    const CodeInsn *p3 = pred(p2->in.addr);
                    if (!p3 || p3->in.b[0] != 0x48) return;
                    const CodeInsn *p4 = pred(p3->in.addr);
                    if (!p4 || p4->in.b[0] != 0xA9 || p4->in.len != 2) return;
                    t = K | (((p4->in.b[1] << 8) | p2->in.b[1]) + 1) % 0x10000; how = "lda#hi/pha/lda#lo/pha+rts";
                }
            } else return;
            if (!am.contains(t)) return;
            out.dispatch[a] = how + " dispatch -> " + hex6(t);
            label(t, LK_CODE);
            flow(t, ns);
        };
        if (!w816 && dec.cpu() == Cpu::C65C02 && (op & 0x0F) == 0x0F) {      // BBRn/BBSn zp,rel
            uint32_t t = K | ((next + (int8_t)ins.b[2]) & 0xFFFF);
            label(t, LK_CODE); flow(t, ns); flow(next, ns);
            continue;
        }
        switch (op) {
        case 0x10: case 0x30: case 0x50: case 0x70: case 0x90: case 0xB0: case 0xD0: case 0xF0: {
            // condition known on every incoming path (the in-state is the join): one side only
            int k = wide ? -1 : brKnown(ins, st);
            if (k != 0) { label(rel(d8), LK_CODE); flow(rel(d8), ns); }
            if (k != 1) flow(next, ns);
            break;
        }
        case 0x80: label(rel(d8), LK_CODE); flow(rel(d8), ns); break;            // BRA
        case 0x82: label(rel(d16), LK_CODE); flow(rel(d16), ns); break;          // BRL
        case 0x62: label(rel(d16), LK_DATA); flow(next, ns); break;              // PER
        case 0x4C: label(abs16, LK_CODE); flow(abs16, ns); break;                // JMP abs
        case 0x5C: label(abs24, LK_CODE); flow(abs24, ns); break;                // JML long
        case 0x20: call(abs16); break;                                           // JSR abs
        case 0x22: call(abs24); break;                                           // JSL
        case 0xFC: { out.indSites.insert(a); State b = ns; b.c = -1; flow(next, b); break; }            // JSR (abs,x)
        case 0x60: case 0x6B: pushDispatch(); break;                             // RTS RTL
        case 0x02: if (w816) { State b = ns; b.c = -1; flow(next, b); } break;  // COP returns (RTI) past its signature
        case 0x00:                                                               // BRK: terminal unless `returns` hint
            if (h.returns.count(a)) { State b = h.returns.at(a); b.depth = ns.depth; b.normalize(); flow(next, b); }
            break;
        case 0x6C: case 0x7C: case 0xDC:                                         // indirect jumps (tables below)
            out.indSites.insert(a); break;
        case 0x40: case 0xDB:                                                    // RTI STP
            break;
        default: flow(next, ns); break;
        }
        }   // forms
    }
    curSrc = ~0u;
    };
    run();

    // ---- jump tables: hints first, then the heuristic, iterated to a fixpoint
    auto overlapsTable = [&](uint32_t a, uint32_t n) {
        for (auto &t : out.tables) if (t.covers(a, n)) return true;
        return false;
    };
    auto codeAt = [&](uint32_t a, uint32_t n) {     // any decoded instruction byte in [a,a+n)
        auto it = decoded.lower_bound(a >= 4 ? a - 4 : 0);
        for (; it != decoded.end() && it->first < a + n; ++it)
            if (it->first + it->second.in.len > a) return true;
        return false;
    };
    auto relocAt = [&](uint32_t a) -> int {         // 1 reloc starts here, 0 none, -1 image has no relocs
        int si = -1; size_t av;
        if (!am.at(a, av, &si)) return -1;
        const Segment &sg = img.segs[si];
        if (sg.relocs.empty()) return -1;
        for (auto &r : sg.relocs) if (sg.base + r.offset == a) return 1;
        return 0;
    };
    auto addTable = [&](JumpTable t, const State &st) {
        out.tables.push_back(t);
        std::sort(out.tables.begin(), out.tables.end(), [](const JumpTable &x, const JumpTable &y) { return x.addr < y.addr; });
        dataAll[t.addr] = std::max(dataAll[t.addr], t.end() - t.addr);
        if (t.kind == TK_SPLIT) { dataAll[t.hiAddr] = std::max(dataAll[t.hiAddr], t.count); label(t.hiAddr, LK_DATA); }
        dataR = mergeRanges(dataAll);
        label(t.addr, LK_DATA);
        for (uint32_t i = 0; i < t.count; i++) {
            size_t av;
            const uint8_t *p = am.at(t.addr + i * t.entrySize(), av);
            if (!p || av < t.entrySize()) break;
            int hb = -1;
            if (t.kind == TK_SPLIT) { size_t hv; const uint8_t *q = am.at(t.hiAddr + i, hv); if (!q) break; hb = *q; }
            uint32_t tg = tableTarget(t, p, hb);
            label(tg, LK_CODE);
            flow(tg, st);
        }
    };
    std::set<uint32_t> hinted;
    std::vector<bool> hintDone(h.tables.size(), false);
    // A table hint without STATE takes the state at its jump site (the first
    // decoded jmp/jsr (abs,x) / jmp (abs) whose operand is the table).  The
    // hint is applied once such a site is decoded; if none is ever found, the
    // entry state is used and a note says so.
    auto applyHints = [&](bool final) {
        for (size_t hi = 0; hi < h.tables.size(); hi++) {
            if (hintDone[hi]) continue;
            auto &ht = h.tables[hi];
            JumpTable t;
            t.addr = ht.addr; t.count = ht.count; t.kind = ht.kind; t.bank = ht.addr & 0xFF0000; t.hinted = true; t.why = "hint"; t.hiAddr = ht.hiAddr;
            size_t av, hav;
            if (!am.at(t.addr, av) || av < (uint64_t)t.count * t.entrySize() || (t.kind == TK_SPLIT && (!am.at(t.hiAddr, hav) || hav < t.count))) { out.notes.push_back("table hint at " + hex6(t.addr) + " runs past the image; ignored"); hintDone[hi] = true; continue; }
            if (overlapsTable(t.addr, t.end() - t.addr) || (t.kind == TK_SPLIT && (overlapsTable(t.hiAddr, t.count) || (t.hiAddr < t.addr + t.count && t.addr < t.hiAddr + t.count)))) { out.notes.push_back("warning: table hint at " + hex6(t.addr) + " overlaps another table; ignored"); hintDone[hi] = true; continue; }
            State st = ht.hasState ? ht.st : o.entryState;
            bool haveUser = false;
            for (auto &kv : decoded) {
                uint8_t op = kv.second.in.b[0];
                uint32_t opnd = kv.second.in.b[1] | (kv.second.in.b[2] << 8);
                bool rtsUser = false;
                for (auto &rc : rtsCands) if (rc.site == kv.first && rc.lo == t.addr) rtsUser = true;
                if (rtsUser) {
                    if (!ht.hasState) st = step(kv.second.in, kv.second.st);
                    t.user = kv.first; haveUser = true;
                    break;
                }
                if (((op == 0x7C || op == 0xFC) && ((kv.first & 0xFF0000) | opnd) == t.addr) || (op == 0x6C && opnd == t.addr)) {
                    if (!ht.hasState) st = step(kv.second.in, kv.second.st);
                    t.user = kv.first; haveUser = true;
                    break;
                }
            }
            if (!ht.hasState && !haveUser && !final) continue;   // wait for the jump site
            if (!ht.hasState && !haveUser) out.notes.push_back("table hint at " + hex6(t.addr) + ": no jump site found, entry state used");
            hinted.insert(t.addr);
            hintDone[hi] = true;
            addTable(t, st);
        }
    };
    for (auto &ht : h.tables) { hinted.insert(ht.addr); if (ht.kind == TK_SPLIT) hinted.insert(ht.hiAddr); }    // keep the heuristic off hinted addresses
    applyHints(false);
    run();
    for (int round = 0; round < 64; round++) {
        size_t before = out.tables.size(), candsBefore = rtsCands.size();
        applyHints(false);
        // lda #<x / ldx|ldy #>x (either order): x is code if it decodes cleanly to a
        // terminator; text and zero runs, data and mid-instruction targets are skipped
        size_t immAdded = 0;
        if (o.immPointers) {
            auto isText = [](uint8_t b) { return (b >= 0x20 && b <= 0x7E) || (b >= 0xA0 && b <= 0xFE); };
            auto probe = [&](uint32_t x, State st) {
                for (int k = 0; k < 64; k++) {
                    if (decoded.count(x)) return true;                      // joins known code
                    if (codeAt(x, 1) || inData(dataR, x, 1)) return false;
                    size_t av; const uint8_t *p = am.at(x, av);
                    if (!p) return false;
                    Insn in; std::string why;
                    if (!dec.decode(p, std::min<size_t>(av, 0x10000 - (x & 0xFFFF)), x, st.m, st.x, in, why)) return false;
                    if (inData(dataR, x, in.len) || codeAt(x + 1, in.len - 1)) return false;
                    uint8_t op = in.b[0];
                    if (op == 0x00 || op == 0x02 || op == 0xDB || op == 0x42) return false;
                    if (op == 0x60 || op == 0x6B || op == 0x40 || op == 0x4C || op == 0x5C || op == 0x6C || op == 0x7C || op == 0xDC) return true;
                    st = step(in, st);
                    x += in.len;
                }
                return false;
            };
            std::vector<std::pair<uint32_t, State>> cand;
            for (auto &kv : decoded) {
                const Insn &i1 = kv.second.in;
                if (i1.len != 2) continue;
                auto nx = decoded.find(kv.first + 2);
                if (nx == decoded.end()) continue;
                const Insn &i2 = nx->second.in;
                int lo = -1, hi = -1;
                const Insn *ilast = &i2;
                if (patched.count(kv.first + 1)) continue;   // self-modified immediates
                if (i2.len == 2 && patched.count(kv.first + 3)) continue;
                if (i2.len == 2 && i1.b[0] == 0xA9 && (i2.b[0] == 0xA2 || i2.b[0] == 0xA0)) { lo = i1.b[1]; hi = i2.b[1]; }
                else if (i2.len == 2 && (i1.b[0] == 0xA2 || i1.b[0] == 0xA0) && i2.b[0] == 0xA9) { lo = i2.b[1]; hi = i1.b[1]; }
                else if (i1.b[0] == 0xA9 || i1.b[0] == 0xA2 || i1.b[0] == 0xA0) {
                    // ld? #a / st? p / ld? #b / st? p+-1 (same register): a pointer built byte by byte
                    uint8_t zst = i1.b[0] == 0xA9 ? 0x85 : i1.b[0] == 0xA2 ? 0x86 : 0x84, ast = zst + 8;
                    auto sa = [&](const Insn &q) -> int { return q.b[0] == zst ? q.b[1] : q.b[0] == ast ? (q.b[1] | q.b[2] << 8) : -1; };
                    int p1 = sa(i2);
                    if (p1 < 0) continue;
                    auto n3 = decoded.find(nx->first + i2.len);
                    if (n3 == decoded.end() || n3->second.in.b[0] != i1.b[0] || n3->second.in.len != 2 || patched.count(n3->first + 1)) continue;
                    auto n4 = decoded.find(n3->first + 2);
                    if (n4 == decoded.end()) continue;
                    int p2 = sa(n4->second.in);
                    if (p2 == p1 + 1) { lo = i1.b[1]; hi = n3->second.in.b[1]; }
                    else if (p2 + 1 == p1) { lo = n3->second.in.b[1]; hi = i1.b[1]; }
                    else continue;
                    ilast = &n4->second.in;
                }
                else continue;
                uint32_t x = (kv.first & 0xFF0000) | (uint32_t)(hi << 8 | lo);
                if (!am.contains(x) || in.count(x) || decoded.count(x) || out.immEntries.count(x)) continue;
                size_t av; const uint8_t *p = am.at(x, av);
                if (av >= 2 && p[0] == 0 && p[1] == 0) continue;           // zero run
                int txt = 0;
                for (size_t q = 0; q < std::min<size_t>(av, 4); q++) txt += isText(p[q]);
                if (txt == 4) continue;                                      // text run
                // a routine whose address is taken starts after flow ends: the bytes just
                // before it must be a terminator (rts/rti/rtl, jmp abs/(abs)) or the image start
                {
                    size_t pav; bool okPrev = !am.contains(x - 1);
                    const uint8_t *q1 = am.at(x - 1, pav);
                    if (q1 && (*q1 == 0x60 || *q1 == 0x40 || (*q1 == 0x6B && w816))) okPrev = true;
                    const uint8_t *q3 = x >= 3 ? am.at(x - 3, pav) : nullptr;
                    if (q3 && pav >= 3 && (*q3 == 0x4C || *q3 == 0x6C)) okPrev = true;
                    auto qb = x >= 2 ? decoded.find(x - 2) : decoded.end();   // a branch known to be taken ends flow like jmp
                    if (qb != decoded.end() && qb->second.in.len == 2 && (brKnown(qb->second.in, qb->second.st) == 1 || (qb->second.in.b[0] == 0x80 && dec.cpu() != Cpu::C6502))) okPrev = true;
                    if (!okPrev) continue;
                }
                State st = step(i2, step(i1, kv.second.st));
                if (ilast != &i2) st = step(*ilast, st);
                if (!probe(x, st)) continue;
                cand.push_back({x, st});
            }
            for (auto &c : cand) {
                if (in.count(c.first)) continue;
                out.immEntries.insert(c.first);
                label(c.first, LK_CODE);
                flow(c.first, c.second);
                immAdded++;
            }
        }
        if (!o.followTables) { run(); if (out.tables.size() == before && immAdded == 0) break; continue; }
        std::vector<std::pair<JumpTable, State>> found;
        std::set<uint32_t> starts;     // every table/pointer operand: a table stops at another's start
        for (auto &t : out.tables) { starts.insert(t.addr); if (t.kind == TK_SPLIT) starts.insert(t.hiAddr); }
        for (auto &rc : rtsCands) { starts.insert(rc.lo); if (rc.kind == TK_SPLIT) starts.insert(rc.hi); }
        for (auto &kv : decoded) {
            uint8_t op = kv.second.in.b[0];
            uint32_t v16 = kv.second.in.b[1] | (kv.second.in.b[2] << 8);
            if (op == 0x7C || (op == 0xFC && w816)) starts.insert((kv.first & 0xFF0000) | v16);
            else if (op == 0x6C || (op == 0xDC && w816)) starts.insert(v16);
        }
        // addresses an ordinary absolute load reads (lda/ldx/ldy/cmp/adc/... abs, abs,x, abs,y):
        // a table entry that is read as plain data is not a jump target (dumpexe's rule)
        std::set<uint32_t> loadsAt, loadBases, dispBases;
        refSets(decoded, w816, loadsAt, loadBases, dispBases);
        // index guard on the straight-line path into a dispatch at `site` (the indexed
        // instruction): a constant index (ldx/ldy #k) or a cmp/cpx/cpy #N + bcc/bcs bound.
        // Returns the entry bound, 0 = unguarded.
        auto indexBound = [&](uint32_t site, bool idxY, uint32_t es, bool split) -> uint32_t {
            uint32_t unit = split ? 1 : es;
            bool scaled = false;            // an asl a seen after the compare (the index is A*2)
            const CodeInsn *q = pred(site);
            uint32_t at = site;
            for (int k = 0; q && k < 12; k++) {
                auto lb = out.labels.find(at);
                if (k > 0 && lb != out.labels.end() && (lb->second & (LK_CODE | LK_SUB | LK_ENTRY))) break;   // other paths join here
                uint8_t o2 = q->in.b[0];
                if (o2 == 0x4C || o2 == 0x60 || o2 == 0x6C || o2 == 0x40 || o2 == 0x6B || o2 == 0x5C || o2 == 0x80 || o2 == 0x82) break;
                if (q->in.len >= 2 && patched.count(q->in.addr + 1)) break;     // self-modified immediate: value unknown
                if (q->in.len == 2 && o2 == (idxY ? 0xA0 : 0xA2)) return q->in.b[1] / unit + 1;           // constant index
                if (o2 == 0x0A) scaled = true;
                if (q->in.len == 2 && (o2 == 0xC9 || o2 == (idxY ? 0xC0 : 0xE0))) {
                    const CodeInsn *nx = nullptr;
                    auto it = decoded.find(q->in.addr + 2);
                    if (it != decoded.end()) nx = &it->second;
                    if (nx && (nx->in.b[0] == 0x90 || nx->in.b[0] == 0xB0) && q->in.b[1] > 0) {
                        uint32_t N = q->in.b[1];
                        return (o2 == 0xC9 && scaled) ? N : (N + unit - 1) / unit;
                    }
                }
                at = q->in.addr;
                q = pred(q->in.addr);
            }
            return 0;
        };
        for (auto &kv : decoded) {
            const Insn &ins = kv.second.in;
            uint8_t op = ins.b[0];
            uint32_t K = kv.first & 0xFF0000;
            uint32_t v16 = ins.b[1] | (ins.b[2] << 8);
            JumpTable t;
            t.user = kv.first;
            uint32_t maxN = 256;
            if (op == 0x7C || (op == 0xFC && w816)) { t.addr = K | v16; t.kind = TK_WORD; t.bank = K; }
            else if (op == 0x6C && dec.cpu() == Cpu::C6502 && (v16 & 0xFF) == 0xFF) {
                // NMOS 6502 bug: the high byte comes from the start of the same page
                size_t a1, a2;
                const uint8_t *lo = am.at(v16, a1), *hi = am.at(v16 & 0xFF00, a2);
                if (lo && hi && !out.dispatch.count(kv.first)) {
                    uint32_t tg = (uint32_t)(lo[0] | (hi[0] << 8));
                    out.dispatch[kv.first] = "NMOS jmp ($xxFF) page wrap: pointer bytes " + hex6(v16) + "/" + hex6(v16 & 0xFF00) + " -> " + hex6(tg);
                    label(tg, LK_CODE);
                    flow(tg, step(ins, kv.second.st));
                }
                continue;
            }
            else if (op == 0x6C) { t.addr = v16; t.kind = TK_WORD; t.bank = K; maxN = 1; }           // pointer in bank 0
            else if (op == 0xDC && w816) { t.addr = v16; t.kind = TK_LONG; maxN = 1; }
            else continue;
            if (hinted.count(t.addr) || overlapsTable(t.addr, 1)) continue;
            bool dup = false;
            for (auto &f : found) if (f.first.addr == t.addr) dup = true;
            if (dup) continue;
            State st = step(ins, kv.second.st);
            int seg0 = -1; size_t av0;
            if (!am.at(t.addr, av0, &seg0)) continue;
            int rel0 = relocAt(t.addr);
            uint32_t n = 0;
            std::string why = "limit";
            auto lim = limits.find(t.addr);
            if (lim != limits.end() && lim->second.first < maxN) { maxN = lim->second.first; why = lim->second.second; }
            if (maxN == 0) continue;
            for (; n < maxN; n++) {
                uint32_t e = t.addr + n * t.entrySize();
                size_t av; int si = -1;
                const uint8_t *p = am.at(e, av, &si);
                if (!p || si != seg0 || av < t.entrySize()) { why = "end of segment"; break; }
                if (n > 0 && (out.labels.count(e) || h.names.count(e))) { why = "label"; break; }
                if (n > 0 && starts.count(e)) { why = "another table starts"; break; }
                if (n > 0 && loadBases.count(e)) { why = "indexed load base"; break; }
                if (n > 0) {
                    bool rd = false;
                    for (uint32_t q = 0; q < t.entrySize(); q++) rd = rd || loadsAt.count(e + q);
                    if (rd) { why = "read by a load"; break; }
                }
                if (codeAt(e, t.entrySize())) { why = "code"; break; }
                if (overlapsTable(e, t.entrySize())) { why = "other table"; break; }
                if (inData(dataR, e, t.entrySize())) { why = "data hint"; break; }
                if (n > 0 && rel0 >= 0 && relocAt(e) != rel0) { why = "relocation pattern changed"; break; }
                uint32_t tg = tableTarget(t, p);
                size_t tav; int tsi = -1;
                const uint8_t *tp = am.at(tg, tav, &tsi);
                if (!tp) { why = "target outside image"; break; }
                if (t.kind == TK_WORD && tsi != seg0 && maxN > 1) { why = "target in another segment"; break; }
                if (tg >= t.addr && tg < e + t.entrySize()) { why = "target inside table"; break; }
                if (inData(dataR, tg, 1)) { why = "target is data"; break; }
                Insn probe; std::string pr;
                size_t inBank = 0x10000 - (tg & 0xFFFF);
                if (!dec.decode(tp, std::min(tav, inBank), tg, st.m, st.x, probe, pr)) { why = "target does not decode"; break; }
                if (decoded.find(tg) == decoded.end() && codeAt(tg, 1)) { why = "target inside an instruction"; break; }
            }
            if (n == 0) continue;
            t.count = n; t.why = why;
            found.push_back({t, st});
        }
        // RTS/RTL dispatch tables: same end rules as above, applied to every byte range
        for (auto &rc : rtsCands) {
            JumpTable t;
            t.addr = rc.lo; t.kind = rc.kind; t.bank = rc.bank; t.hiAddr = rc.hi; t.user = rc.site;
            bool split = t.kind == TK_SPLIT;
            if (hinted.count(t.addr) || overlapsTable(t.addr, 1) || (split && (hinted.count(t.hiAddr) || overlapsTable(t.hiAddr, 1)))) continue;
            bool dup = false;
            for (auto &f : found) if (f.first.addr == t.addr || f.first.covers(t.addr, 1)) dup = true;
            if (dup) continue;
            int seg0 = -1, segH = -1; size_t av0;
            if (!am.at(t.addr, av0, &seg0) || (split && !am.at(t.hiAddr, av0, &segH))) continue;
            uint32_t maxN = 256, n = 0;
            std::string why = "limit";
            auto lim = limits.find(t.addr);
            if (lim != limits.end() && lim->second.first < maxN) { maxN = lim->second.first; why = lim->second.second; }
            const uint32_t es = t.entrySize();
            uint32_t guard = rc.ld ? indexBound(rc.ld, rc.idxY, es, split) : 0;
            if (guard && guard < maxN) { maxN = guard; why = "index guard"; }
            auto rangeBad = [&](uint32_t e, uint32_t len, uint32_t n, int seg, std::string &w) {
                size_t av; int si = -1;
                const uint8_t *p = am.at(e, av, &si);
                if (!p || si != seg || av < len) { w = "end of segment"; return true; }
                if (n > 0 && (out.labels.count(e) || h.names.count(e))) { w = "label"; return true; }
                if (n > 0 && starts.count(e)) { w = "another table starts"; return true; }
                if (n > 0 && loadBases.count(e)) { w = "indexed load base"; return true; }
                if (n > 0) for (uint32_t q = 0; q < len; q++) if (loadsAt.count(e + q)) { w = "read by a load"; return true; }
                if (codeAt(e, len)) { w = "code"; return true; }
                if (overlapsTable(e, len)) { w = "other table"; return true; }
                if (inData(dataR, e, len)) { w = "data hint"; return true; }
                return false;
            };
            for (; n < maxN; n++) {
                uint32_t e = t.addr + n * es;
                if (rangeBad(e, es, n, seg0, why)) break;
                int hb = -1;
                if (split) {
                    uint32_t he = t.hiAddr + n;
                    if ((he >= t.addr && he <= e) || (e >= t.hiAddr && e <= he)) { why = "low and high tables meet"; break; }
                    if (rangeBad(he, 1, n, segH, why)) break;
                    size_t hv; hb = *am.at(he, hv);
                }
                size_t av; const uint8_t *p = am.at(e, av);
                uint32_t tg = tableTarget(t, p, hb);
                size_t tav; int tsi = -1;
                const uint8_t *tp = am.at(tg, tav, &tsi);
                if (!tp) { why = "target outside image"; break; }
                if (t.kind != TK_RTSLONG && tsi != seg0) { why = "target in another segment"; break; }
                if ((tg >= t.addr && tg < e + es) || (split && tg >= t.hiAddr && tg <= t.hiAddr + n)) { why = "target inside table"; break; }
                if (inData(dataR, tg, 1)) { why = "target is data"; break; }
                Insn probe; std::string pr;
                size_t inBank = 0x10000 - (tg & 0xFFFF);
                if (!dec.decode(tp, std::min(tav, inBank), tg, rc.st.m, rc.st.x, probe, pr)) { why = "target does not decode"; break; }
                if (decoded.find(tg) == decoded.end() && codeAt(tg, 1)) { why = "target inside an instruction"; break; }
            }
            if (n == 0 || (n < 2 && !guard)) continue;     // a lone unguarded entry is not evidence of a table
            t.count = n; t.why = why;
            found.push_back({t, rc.st});
        }
        for (auto &f : found)
            if (!overlapsTable(f.first.addr, f.first.end() - f.first.addr) && !(f.first.kind == TK_SPLIT && overlapsTable(f.first.hiAddr, f.first.count)))
                addTable(f.first, f.second);
        run();
        if (out.tables.size() == before && immAdded == 0 && rtsCands.size() == candsBefore) break;
    }
    applyHints(true);
    run();
    // A table entry that later code flow decoded over is not possible (tables
    // are data before flow resumes), but code found earlier can never be inside
    // a table either: the heuristic stops at decoded bytes.
    for (auto &t : out.tables) {
        std::string u = t.user ? " used by " + hex6(t.user) : "";
        out.notes.push_back(std::string(t.hinted ? "hinted" : "auto") + " table " + hex6(t.addr) + ": " + std::to_string(t.count) + " entr" + (t.count == 1 ? "y" : "ies") + u + (t.hinted ? "" : " (stopped: " + t.why + ")"));
    }
    // Resolve overlaps: keep the lowest-address instruction, drop later overlaps.
    uint32_t end = 0;
    bool any = false;
    uint32_t prevA = 0;
    // direct branch / jump / call targets (table entries do not count)
    std::set<uint32_t> direct;
    for (auto &kv : decoded) {
        const Insn &di = kv.second.in; uint8_t o2 = di.b[0];
        uint32_t K2 = kv.first & 0xFF0000, nx = kv.first + di.len;
        if (o2 == 0x4C || o2 == 0x20) direct.insert(K2 | (uint32_t)(di.b[1] | (di.b[2] << 8)));
        else if (o2 == 0x5C || o2 == 0x22) direct.insert((uint32_t)(di.b[1] | (di.b[2] << 8) | (di.b[3] << 16)));
        else if (o2 == 0x82) direct.insert(K2 | ((nx + (int16_t)(di.b[1] | (di.b[2] << 8))) & 0xFFFF));
        else if (di.len == 2 && (o2 == 0x80 || (o2 & 0x1F) == 0x10)) direct.insert(K2 | ((nx + (int8_t)di.b[1]) & 0xFFFF));
    }
    for (auto &kv : decoded) {
        uint32_t a = kv.first;
        // single-byte BRK: flow reaches the signature byte of a terminal BRK, so the
        // BRK is only its opcode byte (listed as data) and the later instruction wins
        if (any && a < end && a == prevA + 1 && out.code.count(prevA) && out.code[prevA].in.b[0] == 0x00 &&
            out.code[prevA].in.len == 2 && !h.returns.count(prevA) && direct.count(a)) {
            out.code.erase(prevA);
            out.notes.push_back("single-byte BRK at " + hex6(prevA) + ": flow continues at " + hex6(a));
            any = false;
        }
        if (any && a < end) {
            auto lb = out.labels.find(a);
            if (lb != out.labels.end() && (lb->second & (LK_CODE | LK_SUB | LK_ENTRY))) {
                out.notes.push_back("overlapping entry point at " + hex6(a) + " (BIT-skip style; label emitted as an equate)");
                out.overlapEntries++;
            } else {
                out.notes.push_back("dropped overlapping instruction at " + hex6(a));
                out.bad[a] = "overlaps instruction";
                out.droppedOverlaps++;
            }
            continue;
        }
        out.code.insert(kv);
        end = a + kv.second.in.len;
        prevA = a;
        any = true;
    }
    for (auto it = out.variants.begin(); it != out.variants.end();) if (out.code.count(it->first)) ++it; else { out.patchNote.erase(it->first); it = out.variants.erase(it); }
    for (auto &n : h.names) out.labels[n.first] |= 0;
    return true;
}


// Routines outside the image cannot be inspected: when >= 3 call sites are each
// followed by >= 2 text bytes and a $00 (and no flow target or label lies in those
// bytes), only suggest the hint; nothing is applied.
static std::map<uint32_t, int> qualifyExternal(const Image &img, const Hints &h, const AnalyzeOptions &o, Decoder &dec, const Analysis &a) {
    AddrMap am(img);
    std::map<uint32_t, std::pair<int, bool>> sites;   // routine -> (string sites, any misfit)
    for (auto &kv : a.unknownStops) sites[kv.first].first += kv.second;
    for (uint32_t t : a.stopMisfit) sites[t].second = true;
    for (auto &kv : a.code) {
        const Insn &in = kv.second.in;
        uint32_t t;
        if (in.b[0] == 0x20) t = (kv.first & 0xFF0000) | in.b[1] | (in.b[2] << 8);
        else if (in.b[0] == 0x22 && dec.cpu() == Cpu::C65816) t = in.b[1] | (in.b[2] << 8) | (in.b[3] << 16);
        else continue;
        if (am.contains(t) || h.varInlines.count(t) || h.inlines.count(t) || h.noreturn.count(t)) continue;
        if ((o.platform == Platform::GSOS && (t == 0xE100A8 || t == 0xE100B0 || t == 0xE10000)) || (o.platform == Platform::ProDOS8 && t == 0x00BF00)) continue;
        if (a.dispatch.count(kv.first) && a.dispatch.at(kv.first).rfind("unknown:", 0) == 0) continue;   // counted above
        uint32_t x = kv.first + in.len;
        uint32_t n = textZ(am, x);
        bool flowIn = false;
        for (auto l = a.labels.lower_bound(x); n && l != a.labels.end() && l->first <= x + n; ++l) if (l->second & (LK_CODE | LK_SUB | LK_ENTRY)) flowIn = true;
        auto r = a.refused.lower_bound(x);
        if (n && r != a.refused.end() && *r <= x + n) flowIn = true;
        if (flowIn) continue;               // excluded: real flow reaches these bytes
        auto &s = sites[t];
        if (n) s.first++; else s.second = true;
    }
    std::map<uint32_t, int> q;
    for (auto &kv : sites) if (kv.second.first >= 3 && !kv.second.second) q[kv.first] = kv.second.first;
    return q;
}

// Runs the analysis until no auto table is entered by code, labels or other
// references found later (each such table is truncated before that entry and
// the analysis is redone from scratch).
// COUT ($FDED) jumps through CSW ($36/$37).  Returns why the decoded image may change CSW
// (or code that could), "" when it provably cannot: every store's target is resolved and
// misses $36/$37 and all decoded instruction bytes, and no indirect jump is unresolved.
// Bytes reached only by falling through an unconditional transfer (or a branch on a known
// carry) are not code.  One shape is exempt: the run-once relocation loop
//   ldx #N / ldy #0 / L: lda S,y / sta D,y / iny / bne L / inc L+2 / inc L+5 / dex / beq|bne
// (or the same copy through two zero-page pointers set by lda #/sta zp) at the image start, copying N pages onto the image's own base, which patches its own
// operands.  When the loop copies the image (loaded at S) elsewhere, *relocNote says so.
static bool flowComplete(const Analysis &a, const std::string &why);
static std::string cswRisk(const Image &img, const Analysis &a, Cpu cpu, Platform plat, int entryE, std::string *relocNote,
                           const std::set<uint32_t> &patchedIn, std::set<uint32_t> &patchedOut, Mods &modOut,
                           std::vector<std::string> *all = nullptr, const Mods *modsIn = nullptr, bool strictSmc = false) {
    auto opw0 = [](const CodeInsn &c) -> uint32_t { return c.in.b[1] | (c.in.b[2] << 8); };
    // every reason is collected (the first one is reported); stores that may modify code are kept in modOut
    std::string first; uint32_t curStore = 0;
    int firstPrio = 9;      // 0: a store that may reach CSW itself; 1: everything else (first one found)
    auto why = [&](const std::string &r, int prio = 1) { if (all && std::find(all->begin(), all->end(), r) == all->end()) all->push_back(r); if (prio < firstPrio) { first = r; firstPrio = prio; } };
    auto anyStore = [&](const std::string &r) { why(r); modOut.push_back({0, ~0u, curStore, true}); };   // target unknown: any code
    const bool cmos = cpu != Cpu::C6502, w816 = cpu == Cpu::C65816;
    auto h4 = [](uint32_t v) { char b[16]; snprintf(b, sizeof b, "$%04X", v & 0xFFFF); return std::string(b); };
    auto at = [&](uint32_t x) -> const CodeInsn * { auto it = a.code.find(x); return it == a.code.end() ? nullptr : &it->second; };
    // dead bytes
    std::set<uint32_t> dead, deadNext;    // deadNext: an address only reached by falling through dead flow
    {
        uint32_t pe = ~0u; bool pstop = false, pdead = false;
        for (auto &kv : a.code) {
            const Insn &in = kv.second.in; uint8_t op = in.b[0];
            bool d = kv.first == pe && !a.labels.count(kv.first) && !a.ctlSrc.count(kv.first) && (pstop || pdead);
            if (d) dead.insert(kv.first);
            pstop = op == 0x4C || op == 0x6C || op == 0x7C || op == 0x60 || op == 0x40 || op == 0x00 ||
                    (op == 0x80 && cmos) || (w816 && (op == 0x5C || op == 0xDC || op == 0x6B || op == 0x82)) ||
                    ((op & 0x1F) == 0x10 && [&] { const State &q = kv.second.st;
                        int8_t f = op < 0x50 ? q.n : op < 0x90 ? q.v : op < 0xD0 ? q.c : q.z; return f >= 0 && f == ((op >> 5) & 1); }());
            pdead = d; pe = kv.first + in.len;
            if (pstop || pdead) deadNext.insert(pe);
        }
    }
    // unresolved indirect jumps (a helper's own return through its pointer is proven by emulation)
    for (uint32_t s : a.indSites) {
        if (dead.count(s)) continue;
        bool res = false;
        for (auto &t : a.tables) if (t.user == s) res = true;
        const CodeInsn *ci = at(s);
        if (ci && ci->in.b[0] == 0x6C && ci->in.b[2] == 0)
            for (auto &r : a.varInlineRoutines) if (s >= r.first && s < r.first + 0x100) res = true;
        if (!res) { why("unresolved indirect jump at " + h4(s)); break; }
    }
    // instruction bytes
    // x is an operand byte (not the opcode) of a decoded immediate-mode instruction whose
    // operand width is known (65816: m and x known at it)
    auto immOperand = [&](uint32_t x) {
        auto it = a.code.upper_bound(x);
        if (it == a.code.begin()) return false;
        --it;
        const CodeInsn &ci = it->second;
        if (dead.count(it->first) || x == it->first || x >= it->first + ci.in.len) return false;
        if (w816 && (ci.st.m < 0 || ci.st.x < 0 || ci.st.e < 0)) return false;
        switch (ci.in.b[0]) {
        case 0x09: case 0x29: case 0x49: case 0x69: case 0xA9: case 0xC9: case 0xE9: case 0xA0: case 0xA2: case 0xC0: case 0xE0: return true;
        case 0x89: return cmos;
        default: return false;
        }
    };
    auto isPatched = [&](uint32_t ins, uint32_t len) {
        for (uint32_t q = 1; q < len; q++) if (patchedIn.count(ins + q)) return true;
        return false;
    };
    // relocator
    std::set<uint32_t> exempt;
    std::map<uint32_t, std::pair<uint32_t, uint32_t>> relocPtr;   // run-once pointer copy store -> [D, D + N pages)
    uint32_t base = img.segs.empty() ? 0 : img.segs[0].base;
    // the loop runs once and copies N pages from S onto D; ex: its stores that patch the copy
    auto relocFound = [&](uint32_t L, uint32_t S, uint32_t D, uint32_t N, uint32_t end, std::initializer_list<uint32_t> ex, uint8_t xw, uint32_t ptrStore = 0) {
        // runs once: nothing outside [base, end) transfers into it, only the entry enters at base
        bool once = (xw == 1 || !w816);
        for (auto it = a.ctlSrc.lower_bound(base); once && it != a.ctlSrc.end() && it->first < end; ++it)
            for (uint32_t s : it->second)
                if (s == ~0u ? it->first != base : (s < base || s >= end)) once = false;
        if (!once) return;
        if (ptrStore) relocPtr[ptrStore] = {D, N * 0x100};   // the pointer walks D..D+N*256 exactly once
        // the copy must not come from the listed image itself (else the code after the loop is replaced)
        bool srcOut = true;
        for (auto &sg : img.segs) {
            uint32_t lo = sg.base & 0xFFFF, hi = lo + (uint32_t)sg.data.size();
            if (S < hi && S + N * 0x100 > lo) srcOut = false;
        }
        if ((base & 0xFFFF) == D && srcOut) exempt.insert(ex);
        else if (relocNote && (base & 0xFFFF) == S)
            *relocNote = "relocation loop at " + h4(L) + " copies " + std::to_string(N) + " page(s) from " + h4(S) + " to " + h4(D) +
                         " and continues in the copy; the code is meant to run at " + h4(D) + " (try --org " + h4(D).substr(1) + ")";
    };
    auto pageOk = [&](uint32_t S, uint32_t D, uint32_t N) { return N != 0 && !(S & 0xFF) && !(D & 0xFF) && D + N * 0x100 <= 0x10000 && D >= 0x100; };
    bool relocSeen = false;
    // shape 1: abs,y copy that patches its own operand high bytes
    for (auto &kv : a.code) {
        uint32_t L = kv.first; const Insn &i0 = kv.second.in;
        if (i0.b[0] != 0xB9 || L < base + 4 || L > base + 0x20) continue;
        const CodeInsn *x0 = at(L - 4), *y0 = at(L - 2), *s0 = at(L + 3), *iy = at(L + 6), *bn = at(L + 7), *i1 = at(L + 9), *i2 = at(L + 12), *dx = at(L + 15), *br = at(L + 16);
        if (!x0 || !y0 || !s0 || !iy || !bn || !i1 || !i2 || !dx || !br) break;
        uint32_t S = i0.b[1] | (i0.b[2] << 8), D = s0->in.b[1] | (s0->in.b[2] << 8), N = x0->in.b[1];
        auto opd = [](const Insn &q) { return (uint32_t)(q.b[1] | (q.b[2] << 8)); };
        if (x0->in.b[0] != 0xA2 || y0->in.b[0] != 0xA0 || y0->in.b[1] != 0 || s0->in.b[0] != 0x99 || iy->in.b[0] != 0xC8 ||
            bn->in.b[0] != 0xD0 || (int8_t)bn->in.b[1] != -9 || i1->in.b[0] != 0xEE || opd(i1->in) != ((L - base + D + 2) & 0xFFFF) ||
            i2->in.b[0] != 0xEE || opd(i2->in) != ((L - base + D + 5) & 0xFFFF) || dx->in.b[0] != 0xCA ||
            (br->in.b[0] != 0xF0 && br->in.b[0] != 0xD0) || !pageOk(S, D, N))
            break;
        relocSeen = true;
        relocFound(L, S, D, N, L + 18 + (br->in.b[0] == 0xF0 ? 3 : 0), {L + 3, L + 9, L + 12}, kv.second.st.x);
        break;
    }
    // shape 2: the same copy through two zero-page pointers set up by straight-line lda #/sta zp
    //   ldx #N / ldy #0 / L: lda (p),y / sta (q),y / iny / bne L / inc p+1 / inc q+1 / dex / bne|beq
    for (auto &kv : a.code) {
        if (relocSeen) break;
        uint32_t L = kv.first; const Insn &i0 = kv.second.in;
        if (i0.b[0] != 0xB1 || L < base + 4 || L > base + 0x30) continue;
        const CodeInsn *x0 = at(L - 4), *y0 = at(L - 2), *s0 = at(L + 2), *iy = at(L + 4), *bn = at(L + 5), *i1 = at(L + 7), *i2 = at(L + 9), *dx = at(L + 11), *br = at(L + 12);
        if (!x0 || !y0 || !s0 || !iy || !bn || !i1 || !i2 || !dx || !br) break;
        uint8_t P = i0.b[1], Q = s0->in.b[1];
        if (x0->in.b[0] != 0xA2 || y0->in.b[0] != 0xA0 || y0->in.b[1] != 0 || s0->in.b[0] != 0x91 || iy->in.b[0] != 0xC8 ||
            bn->in.b[0] != 0xD0 || (int8_t)bn->in.b[1] != -7 || i1->in.b[0] != 0xE6 || i1->in.b[1] != (uint8_t)(P + 1) ||
            i2->in.b[0] != 0xE6 || i2->in.b[1] != (uint8_t)(Q + 1) || dx->in.b[0] != 0xCA || P == Q || P == 0xFF || Q == 0xFF ||
            (br->in.b[0] != 0xF0 && br->in.b[0] != 0xD0) || (br->in.b[0] == 0xD0 && (int8_t)br->in.b[1] != -14))
            break;
        // pointer setup: one straight run of lda #imm / sta zp from the image start to the ldx
        int zv[256]; for (int &z : zv) z = -1;
        int A = -1; uint32_t pc = base; bool ok = true;
        while (ok && pc < L - 4) {
            const CodeInsn *c = at(pc);
            if (!c || (pc != base && (a.labels.count(pc) || a.ctlSrc.count(pc)))) { ok = false; break; }
            if (c->in.b[0] == 0xA9) A = c->in.b[1];
            else if (c->in.b[0] == 0x85 && A >= 0) zv[c->in.b[1]] = A;
            else ok = false;
            pc += c->in.len;
        }
        if (!ok || pc != L - 4 || zv[P] < 0 || zv[P + 1] < 0 || zv[Q] < 0 || zv[Q + 1] < 0) break;
        uint32_t S = zv[P] | (zv[P + 1] << 8), D = zv[Q] | (zv[Q + 1] << 8), N = x0->in.b[1];
        if (!pageOk(S, D, N)) break;
        relocFound(L, S, D, N, L + 14 + (br->in.b[0] == 0xF0 ? 3 : 0), {L + 2}, kv.second.st.x, L + 2);
        break;
    }
    // flow reached bytes that could not be decoded (e.g. 65816 width unknown): code there is not seen
    for (auto &b : a.bad)
        if (!(deadNext.count(b.first) && !a.labels.count(b.first) && !a.ctlSrc.count(b.first)))
            { why("decoding stopped at " + h4(b.first) + " (" + b.second + "), code there not checked"); break; }
    // ---- one write classifier ----
    // Every store and read-modify-write (sta/stx/sty/stz, inc/dec/asl/lsr/rol/ror on memory, tsb/trb,
    // Rockwell RMB/SMB, sta n,s / (n,s),y, mvn/mvp) is classified once, from the dataflow state before
    // it, into the 24-bit bytes it may write, or unknown. The stack-slot check (in the dataflow), the
    // CSW check and the self-modifying-code check (after it) all use this one classification.
    // GS/OS, OMF (S16) loads and native-mode entries: D and S are unknown at entry, anywhere in bank 0.
    const bool gsMode = w816 && (plat == Platform::GSOS || img.omf || entryE == 0);
    struct RV { int sym = -1, lo = 0, hi = 0; bool w16 = false;   // sym >= 0: caller frame byte F(sym); -1 unknown; -2: value in lo..hi
        bool known() const { return sym == -2 && lo == hi; }
        bool operator==(const RV &o) const { return sym == o.sym && (sym != -2 || (lo == o.lo && hi == o.hi && w16 == o.w16)); }
        bool operator!=(const RV &o) const { return !(*this == o); } };
    auto rvC = [](int v, bool w = false) { RV r; r.sym = -2; r.lo = r.hi = v; r.w16 = w; return r; };
    struct Rg { uint32_t lo, n; };
    // bytes written: ranges of linear 24-bit addresses (anyBank: 16-bit offsets, data bank unknown)
    struct WSet { bool is = false, full = false, unknown = false, exact = true, anyBank = false, dp = false; std::string why; std::vector<Rg> r;
        std::vector<int> vals; Rg src{0, 0}; };   // vals: known bytes written (exact plain store); src: mvn/mvp source when its bytes may give them
    // stack slots: >= 0 caller frame byte F(k) (k = depth below S at entry), -1 other, <= -16 a known byte (-16 - v)
    struct SymSt { std::vector<int> stk; int pulled = 0; RV ra, rx, ry; bool lost = false, touched = false, jsr = false;   // jsr: entered by jsr (a 2-byte frame)
        int sp = -1, sbase = -1;    // S (16-bit) when known, and S right after the txs/tcs that set it (live stack: (S, sbase])
        bool sp1 = true;            // S is in page 1 (8-bit platform; kept until tcs / a txs outside page 1)
        int dreg = 0, dbr = 0, nf = -1;   // D, data bank (-1 unknown); nf: register that set N last (0 a, 1 x, 2 y)
        std::map<uint32_t, int> zm;  // bank-0 bytes holding known values (pointers)
        bool operator==(const SymSt &o) const { return sp == o.sp && sbase == o.sbase && sp1 == o.sp1 && dreg == o.dreg && dbr == o.dbr && nf == o.nf &&
            ra == o.ra && rx == o.rx && ry == o.ry && zm == o.zm && lost == o.lost && (lost || (stk == o.stk && pulled == o.pulled)); } };
    // D as a small set: >= 0 one value, -1 unknown, <= -2 a set of 2..4 values (dsets[-2 - v])
    std::vector<std::vector<uint32_t>> dsets;
    auto dVals = [&](int d, std::vector<uint32_t> &o) { o.clear(); if (d >= 0) o.push_back((uint32_t)d); else if (d <= -2) o = dsets[-2 - d]; return d != -1; };
    auto dJoin = [&](int x, int y) -> int {
        if (x == y) return x;
        std::vector<uint32_t> u, t;
        if (!dVals(x, u) || !dVals(y, t)) return -1;
        u.insert(u.end(), t.begin(), t.end()); std::sort(u.begin(), u.end()); u.erase(std::unique(u.begin(), u.end()), u.end());
        if (u.size() > 4) return -1;
        if (u.size() == 1) return (int)u[0];
        for (size_t i = 0; i < dsets.size(); i++) if (dsets[i] == u) return -2 - (int)i;
        dsets.push_back(u); return -2 - (int)(dsets.size() - 1);
    };
    // stack slot byte sets: -2 - i (i < 14) is a set of 2..4 known bytes (bsets[i]); a join of two
    // different known bytes keeps both (pld of two pea paths gives D as a set). Read as unknown elsewhere.
    std::vector<std::vector<uint8_t>> bsets;
    auto bVals = [&](int v, std::vector<uint8_t> &o) { o.clear(); if (v <= -16) o.push_back((uint8_t)((-16 - v) & 0xFF)); else if (v <= -2) o = bsets[-2 - v]; return !o.empty(); };
    auto bJoin = [&](int x, int y) -> int {
        if (x == y) return x;
        std::vector<uint8_t> u, t;
        if (!bVals(x, u) || !bVals(y, t)) return -1;
        u.insert(u.end(), t.begin(), t.end()); std::sort(u.begin(), u.end()); u.erase(std::unique(u.begin(), u.end()), u.end());
        if (u.size() > 4) return -1;
        if (u.size() == 1) return -16 - u[0];
        for (size_t i = 0; i < bsets.size(); i++) if (bsets[i] == u) return -2 - (int)i;
        if (bsets.size() >= 14) return -1;
        bsets.push_back(u); return -2 - (int)(bsets.size() - 1);
    };
    // table-bounded loads: ldx/ldy/lda tbl,x|y with a known base and an index bounded to under 256
    // values give min..max of those table bytes, unless a store (this pass's ranges) may reach them
    std::map<uint32_t, Rg> tblUse;          // load -> table bytes read
    std::set<uint32_t> tblOff;              // loads whose table a store may reach: unknown result
    // ProDOS 8 starts a system program with DBR = 0 (as D = 0); subroutines get DBR from their call
    // sites like D (entryDB), so a plb / mvn / mvp on the way is followed
    const int db0 = !w816 ? 0 : (plat == Platform::ProDOS8 && !gsMode) ? 0 : -1;
    auto entry0 = [&]() { SymSt e; e.sp1 = !gsMode; e.dreg = gsMode ? -1 : 0; e.dbr = db0; return e; };
    // index register range: a known value or a range inside the register width, else the whole width
    auto idxR = [&](const RV &r, const State &s, uint32_t &lo, uint32_t &hi) {
        bool i8 = !w816 || s.e == 1 || s.x == 1; uint32_t mask = i8 ? 0xFF : 0xFFFF;
        if (r.sym == -2 && (i8 || r.w16)) {
            if (r.lo == r.hi) { lo = hi = (uint32_t)r.lo & mask; return; }
            if (r.lo >= 0 && (uint32_t)r.hi <= mask) { lo = r.lo; hi = r.hi; return; }
        }
        lo = 0; hi = mask; };
    // counted loop bound for X at a store: ldx #imm; T: ... (dex|inx)^k; bpl|bne T, the body straight-line,
    // entered only by the ldx fall-through and the back branch, no other X write or width change, and no
    // byte of it reachable by a store (recomputed on every pass with that pass's mods)
    bool loopIgnoreU = false;      // code-hit ranges only: unknown-target stores assumed not to patch the loop (default mode)
    auto loopX = [&](uint32_t A, const State &s, uint32_t &lo, uint32_t &hi) -> bool {
        auto isCtl = [](uint8_t o) { return (o & 0x1F) == 0x10 || o == 0x80 || o == 0x82 || o == 0x4C || o == 0x5C || o == 0x6C || o == 0x7C || o == 0xDC ||
                                            o == 0x20 || o == 0x22 || o == 0xFC || o == 0x60 || o == 0x6B || o == 0x40 || o == 0x00 || o == 0x02 || o == 0xCB || o == 0xDB; };
        auto xw = [](uint8_t o) { return o == 0xA2 || o == 0xA6 || o == 0xAE || o == 0xB6 || o == 0xBE || o == 0xAA || o == 0xBA || o == 0xFA || o == 0xE8 || o == 0xCA ||
                                         o == 0x28 || o == 0xC2 || o == 0xE2 || o == 0xFB || o == 0x9B || o == 0xBB; };   // also tyx/plp/rep/sep/xce
        int xs = (!w816 || s.e == 1) ? 1 : s.x;
        if (xs < 0) return false;
        // the back branch: straight-line forward from A
        uint32_t B = A; const CodeInsn *bi = nullptr;
        for (int n = 0; n < 24; n++) {
            const CodeInsn *c = at(B); if (!c) return false;
            uint8_t o = c->in.b[0];
            if (o == 0x10 || o == 0xD0) { bi = c; break; }
            if (isCtl(o)) return false;
            B += c->in.len;
        }
        if (!bi) return false;
        uint32_t T = (B & 0xFF0000) | ((B + 2 + (int8_t)bi->in.b[1]) & 0xFFFF);
        if (T > A || A - T > 64) return false;
        auto cs = a.ctlSrc.find(T);
        if (cs == a.ctlSrc.end() || cs->second.size() != 1 || *cs->second.begin() != B) return false;
        for (auto t = a.ctlSrc.upper_bound(T); t != a.ctlSrc.end() && t->first <= B; ++t) return false;
        // the ldx #imm falling into T
        const CodeInsn *P = nullptr;
        for (auto it = a.code.lower_bound(T >= 4 ? T - 4 : 0); it != a.code.end() && it->first < T; ++it)
            if (it->first + it->second.in.len == T) P = &it->second;
        if (!P || P->in.b[0] != 0xA2) return false;
        int pxs = (!w816 || P->st.e == 1) ? 1 : P->st.x;
        if (pxs != xs || (uint32_t)P->in.len != (xs ? 2u : 3u)) return false;
        auto hitM = [&](uint32_t x0, uint32_t n) {
            for (uint32_t x = x0; x < x0 + n; x++) {
                if (patchedIn.count(x)) return true;
                if (modsIn) for (auto &r : *modsIn) { if ((r.u || r.d) && loopIgnoreU) continue; if (r.n == ~0u || ((r.lo & 0xFF0000) == (x & 0xFF0000) && (uint32_t)((x - r.lo) & 0xFFFF) < r.n)) return true; }
            }
            return false; };
        if (hitM(T - P->in.len, B + 2 - (T - P->in.len))) return false;
        int k = 0, j = 0; uint8_t stepOp = 0; uint32_t lastOp = 0;
        for (uint32_t q = T; q < B;) {
            const CodeInsn *c = at(q); if (!c) return false;
            int cxs = (!w816 || c->st.e == 1) ? 1 : c->st.x;
            if (cxs != xs) return false;
            uint8_t o = c->in.b[0];
            if (o == 0xCA || o == 0xE8) { if (stepOp && o != stepOp) return false; stepOp = o; k++; if (q < A) j++; lastOp = q; }
            else if (xw(o)) return false;
            q += c->in.len;
        }
        if (!k || k > 4 || lastOp + 1 != B) return false;      // the step sets the branch's flags
        int64_t W = xs ? 0x100 : 0x10000, H = W / 2, v0 = (xs ? P->in.b[1] : (P->in.b[1] | P->in.b[2] << 8));
        int64_t mn, mx;
        bool dec = stepOp == 0xCA, bpl = bi->in.b[0] == 0x10;
        if (dec && bpl) { if (v0 >= H) return false; mn = v0 % k; mx = v0; }
        else if (dec) { if (v0 == 0 || v0 % k) return false; mn = k; mx = v0; }
        else if (bpl) { if (v0 >= H) return false; mx = v0 + ((H - 1 - v0) / k) * k; mn = v0; }
        else { if (v0 == 0 || (W - v0) % k) return false; mn = v0; mx = W - k; }
        if (dec) { mn -= j; mx -= j; } else { mn += j; mx += j; }
        if (mn < 0 || mx >= W) return false;
        lo = (uint32_t)mn; hi = (uint32_t)mx; return true;
    };
    auto classify = [&](const CodeInsn &ci, const SymSt &st) -> WSet {
        WSet w; const Insn &in = ci.in; uint8_t op = in.b[0]; const State &s = ci.st;
        uint32_t z = in.len >= 2 ? in.b[1] : 0, ab = in.len >= 3 ? (uint32_t)(in.b[1] | (in.b[2] << 8)) : 0;
        enum { NONE, DP, DPX, DPY, ABS, ABSX, ABSY, IND, INDY, INDX, LIND, LINDY, LONG, LONGX, SR, SRY, BLK } md = NONE;
        switch (op) {
        case 0x85: case 0x86: case 0x84: case 0xE6: case 0xC6: case 0x06: case 0x46: case 0x26: case 0x66: md = DP; break;
        case 0x64: case 0x04: case 0x14: if (cmos) md = DP; break;
        case 0x95: case 0x94: case 0xF6: case 0xD6: case 0x16: case 0x56: case 0x36: case 0x76: md = DPX; break;
        case 0x74: if (cmos) md = DPX; break;
        case 0x96: md = DPY; break;
        case 0x8D: case 0x8E: case 0x8C: case 0xEE: case 0xCE: case 0x0E: case 0x4E: case 0x2E: case 0x6E: md = ABS; break;
        case 0x9C: case 0x0C: case 0x1C: if (cmos) md = ABS; break;
        case 0x9D: case 0xFE: case 0xDE: case 0x1E: case 0x5E: case 0x3E: case 0x7E: md = ABSX; break;
        case 0x9E: if (cmos) md = ABSX; break;
        case 0x99: md = ABSY; break;
        case 0x91: md = INDY; break;
        case 0x92: if (cmos) md = IND; break;
        case 0x81: md = INDX; break;
        default: break;
        }
        if (w816) switch (op) {
            case 0x87: md = LIND; break;  case 0x97: md = LINDY; break;
            case 0x8F: md = LONG; break;  case 0x9F: md = LONGX; break;
            case 0x83: md = SR; break;    case 0x93: md = SRY; break;
            case 0x54: case 0x44: md = BLK; break;
            default: break;
        }
        else if (cmos && (op & 0x0F) == 0x07) md = DP;   // RMB0-7 / SMB0-7 zp
        if (md == NONE) return w;
        w.is = true;
        bool ixOp = op == 0x86 || op == 0x8E || op == 0x96 || op == 0x84 || op == 0x8C || op == 0x94;
        uint32_t wd = 1;      // 65816: 2 bytes when m=0 (x=0 for stx/sty) or the width is unknown
        if (w816 && s.e != 1) { int f = ixOp ? s.x : s.m; if (f != 1) { wd = 2; if (f != 0) w.exact = false; } }
        bool emu = !w816 || s.e == 1;
        auto add = [&](uint32_t lo, uint32_t n) {       // 6502/65C02: 16-bit addresses, wrap at $FFFF
            if (w816) { w.r.push_back({lo & 0xFFFFFF, n}); return; }
            lo &= 0xFFFF; if (n >= 0x10000) { w.r.push_back({0, 0x10000}); return; }
            uint32_t f = std::min(n, 0x10000 - lo); w.r.push_back({lo, f}); if (n > f) w.r.push_back({0, n - f}); };
        auto addMod = [&](uint32_t mb, uint32_t ms, uint32_t off, uint32_t n) {      // n bytes from off, wrapping in [mb, mb+ms)
            if (n >= ms) { add(mb, ms); return; }
            off %= ms; uint32_t f = std::min(n, ms - off); add(mb + off, f); if (n > f) add(mb, n - f); };
        // direct page: bank 0, never crosses a bank; emulation with DL=0 wraps inside the page
        auto dpWrap = [&]() { return emu && (st.dreg & 0xFF) == 0; };
        auto dpAddr = [&](uint32_t off) -> uint32_t { uint32_t D = (uint32_t)st.dreg; return dpWrap() ? ((D & 0xFF00) | (off & 0xFF)) : ((D + off) & 0xFFFF); };
        auto zb = [&](uint32_t x) -> int { auto i = st.zm.find(x); return i == st.zm.end() ? -1 : i->second; };
        // DBR:off, the second byte at the next linear address (crosses into the next bank)
        auto dataSpan = [&](uint32_t off, uint32_t n) {
            if (st.dbr >= 0) add(((uint32_t)st.dbr << 16) + off, n); else { w.anyBank = true; addMod(0, 0x10000, off & 0xFFFF, n); } };
        auto unk = [&](const std::string &r) { w.unknown = true; w.exact = false; w.why = r; return w; };
        auto ptrWhy = [&]() { return "store through an unresolved pointer (" + h4(z).substr(3) + ")"; };
        uint32_t lo = 0, hi = 0;
        switch (md) {
        case DP: case DPX: case DPY: {
            w.dp = true;
            if (md != DP) { idxR(md == DPX ? st.rx : st.ry, s, lo, hi); if (md == DPX && lo != hi) loopX(ci.in.addr, s, lo, hi); if (lo != hi) w.exact = false; }
            std::vector<uint32_t> dv;
            if (!dVals(st.dreg, dv)) { add(0, 0x10000); w.exact = false; w.full = true; break; }   // D unknown: any bank-0 byte
            if (dv.size() > 1) w.exact = false;      // one of a few known D values: each candidate page
            for (uint32_t D : dv) {
                bool wrap = emu && (D & 0xFF) == 0;
                uint32_t off = z + lo, n = hi - lo + wd;
                if (wrap) addMod(D & 0xFF00, 0x100, off, n); else addMod(0, 0x10000, (D + off) & 0xFFFF, n);
            }
            break;
        }
        case ABS: dataSpan(ab, wd); break;
        case ABSX: case ABSY:
            idxR(md == ABSX ? st.rx : st.ry, s, lo, hi); if (md == ABSX && lo != hi) loopX(ci.in.addr, s, lo, hi); if (lo != hi) w.exact = false;
            dataSpan(ab + lo, hi - lo + wd); break;
        case LONG: case LONGX: {
            uint32_t L = in.b[1] | (in.b[2] << 8) | (in.b[3] << 16);
            if (md == LONGX) { idxR(st.rx, s, lo, hi); if (lo != hi) loopX(ci.in.addr, s, lo, hi); if (lo != hi) w.exact = false; }
            add(L + lo, hi - lo + wd); break; }
        case IND: case INDY: case INDX: {
            if (auto rp = relocPtr.find(ci.in.addr); rp != relocPtr.end() && md == INDY) { w.exact = false; add(rp->second.first, rp->second.second); break; }
            uint32_t o0 = z;
            if (md == INDX) { if (!st.rx.known()) return unk("store through an unknown address"); idxR(st.rx, s, lo, hi); o0 = z + lo; lo = hi = 0; }
            if (st.dreg < 0) return unk(ptrWhy());
            int p0 = zb(dpAddr(o0)), p1 = zb(dpAddr(o0 + 1));
            if (p0 < 0 || p1 < 0) return unk(md == INDX ? std::string("store through an unknown address") : ptrWhy());
            uint32_t ptr = (uint32_t)(p0 | (p1 << 8));
            if (md == INDY) { idxR(st.ry, s, lo, hi); if (lo != hi) w.exact = false; }
            dataSpan(ptr + lo, hi - lo + wd); break; }
        case LIND: case LINDY: {
            if (st.dreg < 0) return unk(ptrWhy());
            int p0 = zb(dpAddr(z)), p1 = zb(dpAddr(z + 1)), p2 = zb(dpAddr(z + 2));
            if (p0 < 0 || p1 < 0 || p2 < 0) return unk(ptrWhy());
            if (md == LINDY) { idxR(st.ry, s, lo, hi); if (lo != hi) w.exact = false; }
            add((uint32_t)(p0 | (p1 << 8) | (p2 << 16)) + lo, hi - lo + wd); break; }
        case SR:      // S + n: page 1 in emulation mode
            if (st.sp >= 0) { if (emu) addMod(0x100, 0x100, (st.sp + z) & 0xFF, wd); else addMod(0, 0x10000, (st.sp + z) & 0xFFFF, wd); }
            else { w.exact = false; if (emu || st.sp1) add(0x100, 0x100); else add(0, 0x10000); }
            break;
        case SRY: return unk("store through an unknown address");
        case BLK: {   // mvn/mvp: destination bank (first operand byte):Y, C+1 bytes, 64K wrap inside the bank
            uint32_t B = (uint32_t)in.b[1] << 16; w.exact = false;
            bool yk = st.ry.known() && (emu || s.x == 1 || st.ry.w16), ck = st.ra.known() && st.ra.w16;
            if (yk && ck) {
                uint32_t Y = (uint32_t)st.ry.lo & ((emu || s.x == 1) ? 0xFF : 0xFFFF), C = (uint32_t)st.ra.lo & 0xFFFF;
                addMod(B, 0x10000, op == 0x54 ? Y : ((Y - C) & 0xFFFF), C + 1);
            } else add(B, 0x10000);
            break; }
        default: break;
        }
        // the bytes a plain exact store writes, when the register is known
        if (w.exact && w.r.size() == 1 && w.r[0].n == wd) {
            bool isz = op == 0x64 || op == 0x9C || op == 0x74 || op == 0x9E;
            bool isx = op == 0x86 || op == 0x8E || op == 0x96, isy = op == 0x84 || op == 0x8C || op == 0x94;
            bool isa = op == 0x85 || op == 0x8D || op == 0x8F || op == 0x95 || op == 0x9D || op == 0x9F || op == 0x99 || op == 0x81 || op == 0x91 || op == 0x92 || op == 0x87 || op == 0x97 || op == 0x83 || op == 0x93;
            const RV *rv = isx ? &st.rx : isy ? &st.ry : isa ? &st.ra : nullptr;
            if (isz) w.vals.assign(wd, 0);
            else if (rv && rv->known() && (wd == 1 || rv->w16)) { for (uint32_t q = 0; q < wd; q++) w.vals.push_back((rv->lo >> (8 * q)) & 0xFF); }
        }
        if (md == BLK && w.r.size() == 1) {      // mvn/mvp with known X, Y, C: source bytes (their values are checked by the caller)
            bool xk = st.rx.known() && (emu || s.x == 1 || st.rx.w16), yk = st.ry.known() && (emu || s.x == 1 || st.ry.w16), ck = st.ra.known() && st.ra.w16;
            if (xk && yk && ck && w.r[0].n <= 16) {
                uint32_t X = (uint32_t)st.rx.lo & ((emu || s.x == 1) ? 0xFF : 0xFFFF), C = (uint32_t)st.ra.lo & 0xFFFF;
                uint32_t S = op == 0x54 ? X : ((X - C) & 0xFFFF);
                if (S + C + 1 <= 0x10000) w.src = {((uint32_t)in.b[2] << 16) | S, C + 1};
            }
        }
        return w;
    };
    // a write that may land in the live stack (frames above S): S known -> (S, base of the txs]; S unknown
    // in page 1 -> page 1 except $0100-$013F (8-bit platforms only); S unknown elsewhere -> all of bank 0
    auto harmsStack = [&](const WSet &w, const SymSt &st, const State &s) -> bool {
        if (w.unknown) return true;
        bool p1 = !w816 || st.sp1 || s.e == 1;
        uint32_t L, H;
        if (st.sp >= 0) { L = (uint32_t)st.sp + 1; H = st.sbase >= st.sp ? (uint32_t)st.sbase : (p1 ? 0x1FF : 0xFFFF); }
        else if (p1) { L = gsMode ? 0x100 : 0x140; H = 0x1FF; }
        else { L = 0; H = 0xFFFF; }
        for (auto &g : w.r) {
            uint32_t lo = g.lo, hi = g.lo + g.n - 1;
            if (!w.anyBank) { if (lo > 0xFFFF) continue; if (hi > 0xFFFF) hi = 0xFFFF; }
            else if (hi > 0xFFFF) return true;
            if (lo <= H && hi >= L) return true;
        }
        return false;
    };
    std::map<uint32_t, int> entrySp, callSp, entryD, callD, entryDB, callDB;   // subroutine entry S / D from their call sites (-1: unknown or disagreeing)
    std::map<uint32_t, SymSt> symIn;
    {
        std::vector<uint32_t> work;
        std::map<uint32_t, int> joinCnt;
        // ranges join to their hull; a range still moving after a few joins jumps to the next bound
        // (0 / -$80 / -$100 below, $FF / $FFFF / $1FFFF above), and after many to unknown
        auto joinRV = [](RV &m, const RV &v, int cnt) {
            if (m == v) return;
            if (cnt <= 40 && m.sym == -2 && v.sym == -2) {
                int lo = std::min(m.lo, v.lo), hi = std::max(m.hi, v.hi);
                if (cnt > 2) { if (lo < m.lo) lo = lo >= 0 ? 0 : lo >= -0x80 ? -0x80 : -0x100; if (hi > m.hi) hi = hi <= 0xFF ? 0xFF : hi <= 0xFFFF ? 0xFFFF : 0x1FFFF; }
                m.lo = lo; m.hi = hi; m.w16 = m.w16 && v.w16; }
            else m = RV(); };
        auto feed = [&](uint32_t t, const SymSt &v) {
            if (!a.code.count(t)) return;
            auto f = symIn.find(t);
            if (f == symIn.end()) { symIn[t] = v; work.push_back(t); return; }
            SymSt &m = f->second; SymSt old = m;
            int widen = joinCnt[t];
            m.touched = m.touched || v.touched; m.jsr = m.jsr && v.jsr;
            if (!m.lost) {
                if (v.lost || m.stk.size() != v.stk.size() || m.pulled != v.pulled) { m.lost = true; m.stk.clear(); m.pulled = 0; }
                else for (size_t q = 0; q < m.stk.size(); q++) if (m.stk[q] != v.stk[q]) m.stk[q] = bJoin(m.stk[q], v.stk[q]);
            }
            joinRV(m.ra, v.ra, widen); joinRV(m.rx, v.rx, widen); joinRV(m.ry, v.ry, widen);
            if (m.sp != v.sp) m.sp = -1;
            if (m.sbase != v.sbase) m.sbase = -1;
            m.dreg = dJoin(m.dreg, v.dreg);
            if (m.dbr != v.dbr) m.dbr = -1;
            if (m.nf != v.nf) m.nf = -1;
            m.sp1 = m.sp1 && v.sp1;
            for (auto it = m.zm.begin(); it != m.zm.end();) { auto g = v.zm.find(it->first); if (g == v.zm.end() || g->second != it->second) it = m.zm.erase(it); else ++it; }
            if (!(m == old) || m.touched != old.touched || m.jsr != old.jsr) { joinCnt[t]++; work.push_back(t); }
        };
        auto run = [&]() {
            while (!work.empty()) {
                uint32_t pc = work.back(); work.pop_back();
                const CodeInsn &ci0 = a.code.at(pc);
                auto fv = a.variants.find(pc);
                size_t nForms = fv == a.variants.end() ? 1 : fv->second.size();
                for (size_t fi = 0; fi < nForms; fi++) {      // each form a store may make of it
                const CodeInsn &ci = fv == a.variants.end() ? ci0 : fv->second[fi];
                const State &s = ci.st;
                SymSt st = symIn[pc];
                bool emu = !w816 || s.e == 1;
                if (w816 && s.e == 1 && st.sp >= 0) st.sp = 0x100 | (st.sp & 0xFF);
                auto pop = [&]() { st.touched = true; if (st.sp >= 0) st.sp = emu ? (0x100 | ((st.sp + 1) & 0xFF)) : ((st.sp + 1) & 0xFFFF);
                    if (!st.stk.empty()) { int v = st.stk.back(); st.stk.pop_back(); return v; } return st.pulled++; };
                auto push = [&](int v) { st.touched = true; if (st.sp >= 0) st.sp = emu ? (0x100 | ((st.sp - 1) & 0xFF)) : ((st.sp - 1) & 0xFFFF);
                    st.stk.push_back(v); if (st.stk.size() > 32) st.lost = true; };
                auto slot = [](const RV &r, bool hiB) -> int {   // one pushed byte of a register value
                    if (r.sym >= 0) return hiB ? -1 : r.sym;
                    if (r.known() && (!hiB || r.w16)) return -16 - ((hiB ? (r.lo >> 8) : r.lo) & 0xFF);
                    return -1; };
                auto unslot = [&](int v) { RV r; if (v >= 0) r.sym = v; else if (v <= -16) r = rvC((-16 - v) & 0xFF); return r; };
                auto pushR = [&](const RV &r, int wdt) { if (wdt == 2) { push(slot(r, true)); push(slot(r, false)); } else push(slot(r, false)); };
                auto pullR = [&](RV &r, int wdt) {
                    if (wdt == 2) { int l = pop(), h = pop(); r = (l <= -16 && h <= -16) ? rvC(((-16 - l) & 0xFF) | (((-16 - h) & 0xFF) << 8), true) : RV(); }
                    else r = unslot(pop()); };
                auto aW = [&]() { return emu || s.m == 1 ? 1 : s.m == 0 ? 2 : 0; };
                auto xW = [&]() { return emu || s.x == 1 ? 1 : s.x == 0 ? 2 : 0; };
                uint8_t o = ci.in.b[0];
                // the one write classification: stack slots, then the known bank-0 bytes
                WSet w = classify(ci, st);
                if (w.is) {
                    if (harmsStack(w, st, s)) { st.lost = true; st.touched = true; }
                    if (w.unknown) st.zm.clear();
                    else for (auto &g : w.r) {
                        if (!w.anyBank && g.lo > 0xFFFF) continue;
                        uint32_t lo = g.lo & 0xFFFF, hi = lo + g.n;
                        for (auto it = st.zm.lower_bound(lo); it != st.zm.end() && it->first < hi;) it = st.zm.erase(it);
                        if (hi > 0x10000) for (auto it = st.zm.begin(); it != st.zm.end() && it->first < hi - 0x10000;) it = st.zm.erase(it);
                    }
                    if (!w.unknown && w.exact && !w.anyBank && !(!w816 && (o & 0x0F) == 0x07)) {
                        RV v; bool plain = true;
                        switch (o) {
                        case 0x85: case 0x8D: case 0x95: case 0x9D: case 0x99: case 0x91: case 0x92: case 0x81:
                        case 0x8F: case 0x9F: case 0x87: case 0x97: case 0x83: v = st.ra; break;
                        case 0x86: case 0x8E: case 0x96: v = st.rx; break;
                        case 0x84: case 0x8C: case 0x94: v = st.ry; break;
                        case 0x64: case 0x9C: case 0x74: case 0x9E: v = rvC(0, true); break;
                        default: plain = false; break;
                        }
                        std::vector<uint32_t> bytes;
                        for (auto &g : w.r) for (uint32_t q = 0; q < g.n && bytes.size() < 3; q++) bytes.push_back(g.lo + q);
                        bool b0 = true; for (uint32_t x : bytes) if (x > 0xFFFF) b0 = false;
                        if (plain && v.known() && b0) {
                            if (bytes.size() == 1) st.zm[bytes[0]] = v.lo & 0xFF;
                            else if (bytes.size() == 2 && v.w16) { st.zm[bytes[0]] = v.lo & 0xFF; st.zm[bytes[1]] = (v.lo >> 8) & 0xFF; }
                        }
                    }
                }
                // N flag source survives only stores, branches, flag ops, pushes and jumps
                bool pureStore = w.is && (o == 0x85 || o == 0x8D || o == 0x95 || o == 0x9D || o == 0x99 || o == 0x91 || o == 0x92 || o == 0x81 ||
                    o == 0x86 || o == 0x8E || o == 0x96 || o == 0x84 || o == 0x8C || o == 0x94 || o == 0x64 || o == 0x9C || o == 0x74 || o == 0x9E ||
                    o == 0x8F || o == 0x9F || o == 0x87 || o == 0x97 || o == 0x83 || o == 0x93) && !(!w816 && (o & 0x0F) == 0x07);
                bool keepNf = pureStore || (o & 0x1F) == 0x10 || (cmos && o == 0x80) || (w816 && o == 0x82) || o == 0x4C || o == 0x18 || o == 0x38 || o == 0xD8 || o == 0xF8 ||
                    o == 0x58 || o == 0x78 || o == 0xB8 || o == 0xEA || o == 0x48 || o == 0x08 || o == 0x9A ||
                    (cmos && (o == 0xDA || o == 0x5A)) || (w816 && (o == 0x8B || o == 0x4B || o == 0x0B || o == 0xF4 || o == 0xD4 || o == 0x62 || o == 0x1B || o == 0xFB));
                if (!keepNf) st.nf = -1;
                int aOp = -1;          // ALU / load groups on A: ora and eor adc lda sbc
                if ((o & 0x03) == 0x01) aOp = o >> 5;
                if (w816 && ((o & 0x1F) == 0x03 || (o & 0x1F) == 0x07 || (o & 0x1F) == 0x0F || (o & 0x1F) == 0x13 || (o & 0x1F) == 0x17 || (o & 0x1F) == 0x1F)) aOp = o >> 5;
                if (cmos && (o & 0x1F) == 0x12) aOp = o >> 5;
                if (aOp >= 0 && o != 0xA9 && o != 0x89) {
                    if (aOp == 4) { /* sta forms: no register change */ }
                    else if (aOp == 6) { /* cmp */ }
                    else { st.ra = RV(); st.nf = 0; }
                } else switch (o) {
                case 0x48: { int ww = aW(); if (!ww) st.lost = true; else pushR(st.ra, ww); break; }
                case 0x68: { int ww = aW(); if (!ww) { st.lost = true; st.ra = RV(); } else pullR(st.ra, ww); st.nf = 0; break; }
                case 0x08: push(-1); break;
                case 0x28: pop(); break;
                case 0xDA: case 0x5A: { if (!cmos) { st.ra = st.rx = st.ry = RV(); break; } int ww = xW(); if (!ww) st.lost = true; else pushR(o == 0xDA ? st.rx : st.ry, ww); break; }
                case 0xFA: case 0x7A: { if (!cmos) { st.ra = st.rx = st.ry = RV(); break; } RV &r = o == 0xFA ? st.rx : st.ry; int ww = xW(); if (!ww) { st.lost = true; r = RV(); } else pullR(r, ww); st.nf = o == 0xFA ? 1 : 2; break; }
                case 0xAA: st.rx = st.ra; if (!emu && s.x == 0 && !st.ra.w16) st.rx = RV(); st.nf = 1; break;
                case 0xA8: st.ry = st.ra; if (!emu && s.x == 0 && !st.ra.w16) st.ry = RV(); st.nf = 2; break;
                case 0x8A: st.ra = st.rx; st.nf = 0; break;
                case 0x98: st.ra = st.ry; st.nf = 0; break;
                case 0x9A: {   // txs: frames gone, S known from a constant X
                    st.lost = true; st.touched = true; uint32_t lo, hi; idxR(st.rx, s, lo, hi);
                    if (lo != hi) st.sp = -1;
                    else st.sp = emu ? (0x100 | (lo & 0xFF)) : (int)lo;       // native with x=1: high byte 0
                    st.sbase = st.sp; st.sp1 = st.sp >= 0 ? (st.sp >> 8) == 1 : (!w816 || (s.e == 1 && !gsMode));
                    break; }
                case 0x1B: case 0x3B:
                    st.lost = true; st.touched = true;
                    if (o == 0x1B) { st.sp = (st.ra.known() && st.ra.w16) ? (emu ? (0x100 | (st.ra.lo & 0xFF)) : (st.ra.lo & 0xFFFF)) : -1; st.sbase = st.sp; st.sp1 = st.sp >= 0 ? (st.sp >> 8) == 1 : false; }
                    else { st.ra = st.sp >= 0 ? rvC(st.sp, true) : RV(); st.nf = 0; }
                    break;
                case 0x5B: st.dreg = (st.ra.known() && st.ra.w16) ? (st.ra.lo & 0xFFFF) : -1; break;   // tcd: needs all 16 bits of C
                case 0x7B: if (w816) { st.ra = st.dreg >= 0 ? rvC(st.dreg, true) : RV(); st.nf = 0; } else st.ra = st.rx = st.ry = RV(); break;
                case 0x2B: if (w816) { int l = pop(), h = pop(); std::vector<uint8_t> lv, hv; st.dreg = -1;
                        if (!st.lost && bVals(l, lv) && bVals(h, hv) && lv.size() * hv.size() <= 4) {   // D: every low/high pair
                            int d = -100; for (uint8_t x : lv) for (uint8_t y : hv) { int one = x | (y << 8); d = d == -100 ? one : dJoin(d, one); } st.dreg = d; } } else st.ra = st.rx = st.ry = RV(); break;   // pld: D from two known pushed bytes (pea/phd), else unknown
                case 0xAB: if (w816) { int v = pop(); st.dbr = v <= -16 ? ((-16 - v) & 0xFF) : -1; } else st.ra = st.rx = st.ry = RV(); break;   // plb
                case 0x8B: if (w816) push(st.dbr >= 0 ? -16 - st.dbr : -1); else st.ra = st.rx = st.ry = RV(); break;   // phb
                case 0x4B: if (w816) push(-16 - (int)((pc >> 16) & 0xFF)); else st.ra = st.rx = st.ry = RV(); break;   // phk
                case 0x0B: if (w816) { push(st.dreg >= 0 ? -16 - ((st.dreg >> 8) & 0xFF) : -1); push(st.dreg >= 0 ? -16 - (st.dreg & 0xFF) : -1); } else st.ra = st.rx = st.ry = RV(); break;
                case 0xF4: if (w816) { push(-16 - ci.in.b[2]); push(-16 - ci.in.b[1]); } else st.ra = st.rx = st.ry = RV(); break;   // pea: a known word
                case 0xD4: case 0x62: if (w816) { push(-1); push(-1); } else st.ra = st.rx = st.ry = RV(); break;   // pea / pei / per: pushes
                case 0x54: case 0x44: if (w816) { st.dbr = ci.in.b[1]; st.ra = rvC(0xFFFF, true); st.rx = st.ry = RV(); } else st.ra = st.rx = st.ry = RV(); break;
                case 0x86: case 0x8E: case 0x96: case 0x84: case 0x8C: case 0x94: case 0x64: case 0x9C: case 0x74: case 0x9E:
                case 0x18: case 0x38: case 0xD8: case 0xF8: case 0x58: case 0x78: case 0xB8: case 0xEA:
                case 0xE0: case 0xE4: case 0xEC: case 0xC0: case 0xC4: case 0xCC: case 0x24: case 0x2C:
                case 0xE6: case 0xEE: case 0xF6: case 0xFE: case 0xC6: case 0xCE: case 0xD6: case 0xDE:
                case 0x06: case 0x0E: case 0x16: case 0x1E: case 0x26: case 0x2E: case 0x36: case 0x3E:
                case 0x46: case 0x4E: case 0x56: case 0x5E: case 0x66: case 0x6E: case 0x76: case 0x7E:
                case 0x10: case 0x30: case 0x50: case 0x70: case 0x90: case 0xB0: case 0xD0: case 0xF0: case 0x4C: break;
                case 0x04: case 0x14: case 0x0C: case 0x1C: case 0x34: case 0x3C: case 0x80: case 0x89: if (!cmos) st.ra = st.rx = st.ry = RV(); break;
                case 0xC2: case 0xE2: case 0xFB: case 0x82: if (!w816) st.ra = st.rx = st.ry = RV(); break;
                case 0x0A: case 0x2A: case 0x4A: case 0x6A: st.ra = RV(); st.nf = 0; break;
                case 0xEB: if (w816) { st.ra = RV(); st.nf = 0; } else st.ra = st.rx = st.ry = RV(); break;
                case 0xA6: case 0xAE: case 0xB6: case 0xBE: case 0xA4: case 0xAC: case 0xB4: case 0xBC: case 0xBD: case 0xB9: {
                    bool toX = o == 0xA6 || o == 0xAE || o == 0xB6 || o == 0xBE, toA = o == 0xBD || o == 0xB9;
                    RV &dst = toX ? st.rx : toA ? st.ra : st.ry;
                    RV nv;
                    if ((o == 0xBE || o == 0xBC || o == 0xBD || o == 0xB9) && ci.in.len == 3 && !tblOff.count(pc) && !isPatched(pc, 3)) {
                        const RV &ix = (o == 0xBE || o == 0xB9) ? st.ry : st.rx;
                        bool d8 = toA ? (emu || s.m == 1) : (emu || s.x == 1);
                        bool i8 = emu || s.x == 1;
                        if (d8 && ix.sym == -2 && ix.lo >= 0 && ix.hi >= ix.lo && ix.hi - ix.lo < 0x100 && (i8 || ix.w16) && (uint32_t)ix.hi <= (i8 ? 0xFFu : 0xFFFFu) && st.dbr >= 0) {
                            uint32_t lo = (uint32_t)st.dbr << 16 | (uint32_t)(ci.in.b[1] | (ci.in.b[2] << 8));
                            lo += (uint32_t)ix.lo; uint32_t n = (uint32_t)(ix.hi - ix.lo + 1);
                            AddrMap tm(img); int mn = 256, mx = -1;
                            for (uint32_t q = 0; q < n; q++) { size_t av; const uint8_t *b = tm.at(lo + q, av); if (!b) { mx = -1; break; } mn = std::min(mn, (int)*b); mx = std::max(mx, (int)*b); }
                            if (mx >= 0) {
                                nv.sym = -2; nv.lo = mn; nv.hi = mx;
                                auto &u = tblUse[pc];
                                if (u.n == 0) u = Rg{lo, n}; else { uint32_t e = std::max(u.lo + u.n, lo + n); u.lo = std::min(u.lo, lo); u.n = e - u.lo; }
                            }
                        }
                    }
                    dst = nv; st.nf = toX ? 1 : toA ? 0 : 2; break; }
                case 0xBA: { bool i8 = emu || s.x == 1;
                    st.rx = st.sp >= 0 && (i8 || s.x == 0) ? rvC(i8 ? (st.sp & 0xFF) : st.sp, !i8) : RV(); st.touched = true; st.nf = 1; break; }
                case 0xA2: case 0xA0: case 0xA9: {
                    RV &r = o == 0xA2 ? st.rx : o == 0xA0 ? st.ry : st.ra;
                    if (isPatched(pc, ci.in.len)) r = RV();
                    else if (ci.in.len == 2) r = rvC(ci.in.b[1]);
                    else if (ci.in.len == 3) r = rvC(ci.in.b[1] | (ci.in.b[2] << 8), true);
                    else r = RV();
                    st.nf = o == 0xA2 ? 1 : o == 0xA0 ? 2 : 0;
                    break; }
                case 0xE8: case 0xCA: case 0xC8: case 0x88: {
                    RV &r = (o == 0xE8 || o == 0xCA) ? st.rx : st.ry;
                    int d = (o == 0xE8 || o == 0xC8) ? 1 : -1;
                    if (r.sym == -2 && r.lo + d >= -0x100 && r.hi + d <= 0x1FFFF) { r.lo += d; r.hi += d; } else r = RV();
                    st.nf = (o == 0xE8 || o == 0xCA) ? 1 : 2;
                    break; }
                default: st.ra = st.rx = st.ry = RV(); st.zm.clear(); break;   // jsr and the rest: registers and known bytes unknown
                }
                if (st.lost) { st.stk.clear(); st.pulled = 0; }
                uint32_t nx = pc + ci.in.len, K = pc & 0xFF0000;
                bool rel8 = (o & 0x1F) == 0x10 || (cmos && o == 0x80);
                // bpl / bmi on an 8-bit register range: each edge keeps the values that take it
                SymSt fall = st; bool takenOk = true, fallOk = true;
                if ((o == 0x10 || o == 0x30) && st.nf >= 0) {
                    RV &rt = st.nf == 0 ? st.ra : st.nf == 1 ? st.rx : st.ry;
                    RV &rf = st.nf == 0 ? fall.ra : st.nf == 1 ? fall.rx : fall.ry;
                    bool r8 = st.nf == 0 ? (emu || s.m == 1) : (emu || s.x == 1);
                    if (r8 && rt.sym == -2) {
                        int lo = rt.lo, hi = rt.hi, plo = 1, phi = 0, nlo = 1, nhi = 0; bool ok = true;
                        if (lo >= -128 && hi <= 127) { plo = std::max(lo, 0); phi = hi; nlo = lo; nhi = std::min(hi, -1); }
                        else if (lo >= 0 && hi <= 255) { plo = lo; phi = std::min(hi, 127); nlo = std::max(lo, 128); nhi = hi; }
                        else ok = false;
                        if (ok) {
                            bool posTaken = o == 0x10;
                            int tlo = posTaken ? plo : nlo, thi = posTaken ? phi : nhi, flo = posTaken ? nlo : plo, fhi = posTaken ? nhi : phi;
                            if (tlo > thi) takenOk = false; else { rt.lo = tlo; rt.hi = thi; }
                            if (flo > fhi) fallOk = false; else { rf.lo = flo; rf.hi = fhi; }
                        }
                    }
                }
                // bcc / bcs right after cmp / cpx / cpy #imm (entered only by that fall-through): the
                // register is below the immediate on the carry-clear edge, at or above it on the other
                if ((o == 0x90 || o == 0xB0) && !a.ctlSrc.count(pc) && !a.variants.count(pc) && !isPatched(pc, 2)) {
                    const CodeInsn *P = nullptr;
                    for (uint32_t l = 2; l <= 3 && !P; l++) { auto pi = a.code.find(pc - l); if (pi != a.code.end() && pi->second.in.len == (int)l) P = &pi->second; }
                    uint8_t po = P ? P->in.b[0] : 0;
                    if (P && (po == 0xC9 || po == 0xE0 || po == 0xC0) && !a.variants.count(P->in.addr) && !isPatched(P->in.addr, P->in.len)) {
                        int L = P->in.len; bool r8 = L == 2;
                        bool wOk = po == 0xC9 ? (r8 == (emu || s.m == 1)) : (r8 == (emu || s.x == 1));
                        int mask = r8 ? 0xFF : 0xFFFF, imm = r8 ? P->in.b[1] : (P->in.b[1] | (P->in.b[2] << 8));
                        if (wOk) {
                            RV &rt = po == 0xC9 ? st.ra : po == 0xE0 ? st.rx : st.ry;
                            RV &rf = po == 0xC9 ? fall.ra : po == 0xE0 ? fall.rx : fall.ry;
                            int lo = 0, hi = mask;
                            if (rt.sym == -2 && rt.lo >= 0 && rt.hi <= mask) { lo = rt.lo; hi = rt.hi; }
                            int blo = lo, bhi = std::min(hi, imm - 1), alo = std::max(lo, imm), ahi = hi;   // below / at-or-above
                            bool csTaken = o == 0xB0;
                            int tlo = csTaken ? alo : blo, thi = csTaken ? ahi : bhi, flo = csTaken ? blo : alo, fhi = csTaken ? bhi : ahi;
                            if (tlo > thi) takenOk = false; else { rt.sym = -2; rt.lo = tlo; rt.hi = thi; rt.w16 = !r8; }
                            if (flo > fhi) fallOk = false; else { rf.sym = -2; rf.lo = flo; rf.hi = fhi; rf.w16 = !r8; }
                        }
                    }
                }
                if (rel8 && takenOk) feed(K | ((nx + (int8_t)ci.in.b[1]) & 0xFFFF), st);
                if (w816 && o == 0x82) feed(K | ((nx + (int16_t)(ci.in.b[1] | (ci.in.b[2] << 8))) & 0xFFFF), st);
                if (o == 0x4C) { feed(K | ci.in.b[1] | (ci.in.b[2] << 8), st); continue; }
                if (o == 0x60 || o == 0x40 || o == 0x6B || o == 0x00 || o == 0x6C || o == 0x7C || o == 0xDC || o == 0x5C || (cmos && o == 0x80) || (w816 && o == 0x82)) continue;
                if (!fallOk) continue;
                if (o == 0x20 || o == 0x22) {   // callee entry D and S
                    uint32_t t = o == 0x20 ? (K | opw0(ci)) : (ci.in.b[1] | (ci.in.b[2] << 8) | (ci.in.b[3] << 16));
                    auto f = callD.find(t); if (f == callD.end()) callD[t] = st.dreg; else f->second = dJoin(f->second, st.dreg);
                    { auto fb = callDB.find(t); if (fb == callDB.end()) callDB[t] = st.dbr; else if (fb->second != st.dbr) fb->second = -1; }
                    int v = -1;
                    if (st.sp >= 0) { int d = o == 0x20 ? 2 : 3; v = emu ? (0x100 | ((st.sp - d) & 0xFF)) : ((st.sp - d) & 0xFFFF); }
                    auto g = callSp.find(t); if (g == callSp.end()) callSp[t] = v; else if (g->second != v) g->second = -1;
                    // a routine outside the image (toolbox, MLI) may pull or rewrite what was pushed
                    if (!a.code.count(t)) for (int &q : st.stk) if (q <= -2) q = -1;
                }
                if (deadNext.count(nx)) continue;
                if ((o == 0x20 || o == 0x22 || o == 0xFC) && a.dispatch.count(pc)) {   // past the inline bytes
                    const std::string &d = a.dispatch.at(pc);
                    if (d.rfind("returns past ", 0) == 0) nx += (uint32_t)std::stoul(d.substr(13));
                    else if (d.rfind("unknown:", 0) == 0 || d.find("does not return") != std::string::npos) continue;
                }
                feed(nx, (o == 0x10 || o == 0x30 || o == 0x90 || o == 0xB0) ? fall : st);
                }   // forms
            }
        };
        const int d0 = gsMode ? -1 : 0;
        auto seed = [&](bool unsettled) {
            symIn.clear(); callSp.clear(); callD.clear(); callDB.clear(); joinCnt.clear();
            for (auto &l : a.labels) if (l.second & (LK_SUB | LK_ENTRY)) {
                SymSt e = entry0(); e.jsr = (l.second & LK_SUB) != 0;
                if (!unsettled) { auto f = entrySp.find(l.first); if (f != entrySp.end()) e.sp = f->second; }
                auto g = entryD.find(l.first); if (g != entryD.end()) e.dreg = unsettled ? -1 : g->second;
                auto gb = entryDB.find(l.first); if (gb != entryDB.end()) e.dbr = unsettled ? -1 : gb->second;
                feed(l.first, e);
            }
            run();
            for (auto &kv : a.code) if (!symIn.count(kv.first)) { feed(kv.first, entry0()); run(); }
        };
        for (int round = 0; round < 4; round++) {        // entry S / D of subroutines from their call sites
            seed(false);
            std::map<uint32_t, int> ne, nd;
            for (auto &c : callSp) if (c.second >= 0) ne[c.first] = c.second;
            for (auto &c : callD) if (c.second != d0) nd[c.first] = c.second;   // D other than the entry default at a call
            for (auto &c : entryD) if (!nd.count(c.first)) nd[c.first] = -1;     // keep: a changed entry stays conservative
            std::map<uint32_t, int> nb;
            for (auto &c : callDB) if (c.second != db0) nb[c.first] = c.second;
            for (auto &c : entryDB) if (!nb.count(c.first)) nb[c.first] = -1;
            if (ne == entrySp && nd == entryD && nb == entryDB) break;
            entrySp = ne; entryD = nd; entryDB = nb;
            if (round == 3) { entrySp.clear(); seed(true); }   // not settled: S unknown everywhere
        }
        // a table read by a bounded load must not be reachable by any store of this same pass: drop
        // the narrowing of such loads (only ever more of them) and run the dataflow again
        for (int tp = 0; tp < 16 && !tblUse.empty(); tp++) {
            bool more = false;
            for (auto &kv : a.code) {
                if (dead.count(kv.first)) continue;
                std::vector<CodeInsn> fs{kv.second};
                auto fv = a.variants.find(kv.first); if (fv != a.variants.end()) fs = fv->second;
                for (auto &ci : fs) {
                    auto si = symIn.find(kv.first);
                    loopIgnoreU = !strictSmc;     // as for code-hit ranges
                    WSet w = classify(ci, si != symIn.end() ? si->second : entry0());
                    loopIgnoreU = false;
                    if (!w.is) continue;
                    bool whole = w.unknown || w.full; for (auto &g : w.r) if (g.n >= 0x10000) whole = true;
                    if (whole && !strictSmc) continue;     // default mode: as unknown-target stores for code (assumed not to reach it)
                    for (auto &u : tblUse) {
                        if (tblOff.count(u.first)) continue;
                        bool hit = w.unknown;
                        for (auto &g : w.r) {
                            if (w.anyBank) { uint32_t a0 = g.lo & 0xFFFF, b0 = u.second.lo & 0xFFFF; if (a0 < b0 + u.second.n && b0 < a0 + g.n) hit = true; }
                            else if (g.lo < u.second.lo + u.second.n && u.second.lo < g.lo + g.n) hit = true;
                        }
                        if (hit) { tblOff.insert(u.first); more = true; }
                    }
                }
            }
            if (!more) break;
            tblUse.clear(); seed(false);
        }
    }
    // CSW and self-modifying code, from the same write classification
    std::vector<std::pair<uint32_t, CodeInsn>> allForms;     // every instruction form that may run (see Analysis::variants)
    for (auto &kv : a.code) { auto fv = a.variants.find(kv.first); if (fv == a.variants.end()) allForms.push_back(kv); else for (auto &c : fv->second) allForms.push_back({kv.first, c}); }
    auto hitsCodeR = [&](uint32_t lo, uint32_t n) {      // linear [lo, lo+n)
        auto it = a.code.upper_bound(lo);
        if (it != a.code.begin()) { auto p = std::prev(it); if (lo < p->first + p->second.in.len && !dead.count(p->first)) return true; }
        for (; it != a.code.end() && it->first < lo + n; ++it) if (!dead.count(it->first)) return true;
        return false;
    };
    Mods lateMods;      // operand-patched stores (unknown targets), after every encoded-target range
    // read-modify-write on one exact code byte: a single known result only when it provably runs once
    // (decided after every reason is known, below); otherwise an unknown value
    struct RmwC { uint32_t A, x; uint8_t op; int c; int av; };
    std::vector<RmwC> rmwC;
    // every byte any store may write (for mvn/mvp source values): ranges, and whether any target is unknown
    std::vector<Rg> allW; bool anyUnk = false;
    for (auto &kv : allForms) {
        if (dead.count(kv.first) || exempt.count(kv.first)) continue;
        auto si = symIn.find(kv.first);
        WSet w = classify(kv.second, si != symIn.end() ? si->second : entry0());
        if (!w.is) continue;
        if (w.unknown) { anyUnk = true; continue; }
        for (auto &g : w.r) allW.push_back(w.anyBank ? Rg{0x1000000u | (g.lo & 0xFFFF), g.n} : g);   // bit 24: any bank
    }
    for (auto &kv : allForms) {
        uint32_t A = kv.first;
        if (dead.count(A) || exempt.count(A)) continue;
        auto si = symIn.find(A);
        WSet w = classify(kv.second, si != symIn.end() ? si->second : entry0());   // all stores taint the loop bound (CSW)
        if (!w.is) continue;
        curStore = A;
        {   // a store whose address operand another store may change has an unknown target
            const Insn &in = kv.second.in; bool opnd = false;
            for (uint32_t q = A + 1; q < A + in.len && !opnd; q++) {
                if (patchedIn.count(q)) opnd = true;
                if (modsIn) for (auto &r : *modsIn) if ((strictSmc || !(r.u || r.d)) && r.n != ~0u && !(r.n == 1 && r.v >= 0) && ((   /* a known value: its form is in allForms */ (r.lo & 0xFF0000) == (q & 0xFF0000) && (uint32_t)((q - r.lo) & 0xFFFF) < r.n))) opnd = true;
            }
            if (opnd) { why("store whose address operand may be modified at " + h4(A)); lateMods.push_back({0, ~0u, A, true}); }   // plus its encoded target below
        }
        loopIgnoreU = !strictSmc;
        WSet wc = classify(kv.second, si != symIn.end() ? si->second : entry0());  // code-hit ranges (round-2 scope)
        loopIgnoreU = false;
        curStore = A;
        std::string where = " at " + h4(A);
        if (w.unknown) { anyStore(w.why + where); continue; }
        uint32_t K = A & 0xFF0000, tot = 0;
        bool csw = false;
        for (auto &g : w.r) {
            tot += g.n;
            if (!w.anyBank && g.lo > 0xFFFF) continue;
            uint32_t lo = g.lo, hi = g.lo + g.n;     // [lo, hi)
            if ((lo < 0x38 && hi > 0x36) || (w.anyBank && hi > 0x10036)) csw = true;
        }
        if (csw) why("store that may reach CSW" + where, 0);
        auto hits = [&](const WSet &x) {
            std::vector<Rg> hit;
            for (auto &g : x.r) {
                uint32_t lo = x.anyBank ? (K | g.lo) : g.lo;
                if (x.anyBank && g.lo + g.n > 0x10000) { uint32_t f = 0x10000 - g.lo; if (hitsCodeR(lo, f)) hit.push_back({lo, f}); if (hitsCodeR(K, g.n - f)) hit.push_back({K, g.n - f}); continue; }
                if (hitsCodeR(lo, g.n)) hit.push_back({lo, g.n});
            }
            return hit; };
        std::vector<Rg> hit = hits(w);
        if (hit.empty()) continue;
        // a single exact byte on an immediate operand: allowed, the operand's value becomes unknown
        if (w.exact && tot == 1 && !w.dp && immOperand(hit[0].lo)) { patchedOut.insert(hit[0].lo); continue; }
        why("store that may modify code (self-modifying code)" + where);
        {
            uint8_t op = kv.second.in.b[0]; uint8_t lo4 = op & 0x0F;
            bool rmw = (lo4 == 0x06 || lo4 == 0x0E) && op != 0x86 && op != 0x8E && op != 0xA6 && op != 0xAE && op != 0x96 && op != 0x9E && op != 0xB6 && op != 0xBE;
            bool tsbtrb = op == 0x04 || op == 0x0C || op == 0x14 || op == 0x1C;
            bool rsmb = cpu == Cpu::C65C02 && lo4 == 0x07;
            if (w.exact && tot == 1 && hit.size() == 1 && hit[0].n == 1 && (rmw || tsbtrb || rsmb)) {
                const SymSt &ss = si != symIn.end() ? si->second : entry0();
                int av = (ss.ra.known() && !ss.ra.w16) ? (ss.ra.lo & 0xFF) : -1;
                rmwC.push_back({A, hit[0].lo, op, kv.second.st.c, av});
                continue;
            }
        }
        auto emitR = [&](const std::vector<Rg> &hs, bool u, bool d) {
            for (auto &g : hs) {     // per bank (the emulator's ranges wrap in lo's bank)
                uint32_t lo = g.lo, n = g.n;
                while (n) { uint32_t f = std::min(n, 0x10000 - (lo & 0xFFFF)); Mod m{lo, f, A, u}; m.d = d; modOut.push_back(m); lo = (lo + f) & 0xFFFFFF; n -= f; }
            } };
        // a range covering a whole 64K bank is as unknown as no target at all
        auto wholeOf = [](const WSet &x) { bool r = x.full; for (auto &g : x.r) if (g.n >= 0x10000) r = true; return r; };
        bool same = wc.r.size() == w.r.size();
        for (size_t q = 0; same && q < w.r.size(); q++) same = wc.r[q].lo == w.r[q].lo && wc.r[q].n == w.r[q].n;
        if (same && w.src.n && !anyUnk && w.r.size() == 1 && w.r[0].n == w.src.n) {     // mvn/mvp: source bytes nothing writes
            bool ok = true;
            for (auto &g : allW) {
                uint32_t sl = (g.lo & 0x1000000u) ? (w.src.lo & 0xFFFF) : w.src.lo, gl = g.lo & 0xFFFFFF;
                if ((g.lo & 0x1000000u) ? (gl < sl + w.src.n && sl < gl + g.n) || (gl + g.n > 0x10000 && sl < gl + g.n - 0x10000) : (gl < sl + w.src.n && sl < gl + g.n)) ok = false;
            }
            AddrMap am(img);
            for (uint32_t q = 0; ok && q < w.src.n; q++) { size_t av; const uint8_t *p = am.at(w.src.lo + q, av); if (!p || !av) ok = false; else w.vals.push_back(*p); }
            if (!ok) w.vals.clear();
        }
        if (same && !w.vals.empty() && w.r.size() == 1 && w.vals.size() == w.r[0].n) {   // known bytes: one mod per code byte, with its value
            for (uint32_t q = 0; q < w.r[0].n; q++) {
                uint32_t x = w.anyBank ? (K | ((w.r[0].lo + q) & 0xFFFF)) : ((w.r[0].lo + q) & 0xFFFFFF);   // (any bank: as the range check above)
                if (hitsCodeR(x, 1)) { Mod m{x, 1, A, false}; m.v = w.vals[q]; modOut.push_back(m); }
            }
            continue;
        }
        if (same) { emitR(hit, wholeOf(w), false); continue; }
        // the loop bound holds only if unknown-target stores leave the loop alone: the narrowed range
        // counts for code; the rest is kept for the helper checks only (like an unknown-target store)
        emitR(hits(wc), wholeOf(wc), false);
        emitR(hit, false, true);
    }
    modOut.insert(modOut.end(), lateMods.begin(), lateMods.end());
    // return-address dispatch: rts/rtl/rti after pushes in the same straight-line block goes to a
    // computed target (unresolved transfer) unless a proven RTS table belongs to that block; a
    // helper's own return is proven by emulation. 65816 tcs / native txs: S may leave page 1.
    for (auto &kv : allForms) {
        uint32_t R = kv.first; uint8_t op = kv.second.in.b[0];
        if (dead.count(R)) continue;
        if (w816 && (op == 0x1B || (op == 0x9A && kv.second.st.e != 1))) { why("stack pointer set by " + std::string(op == 0x1B ? "tcs" : "txs") + " at " + h4(R) + " (stack may not be in page 1)"); continue; }
        if (!(op == 0x60 || op == 0x40 || (w816 && op == 0x6B))) continue;
        if (a.varExits.count(R) && (!a.looseOrdExits.count(R) || a.looseProvedExits.count(R))) continue;   // an inline helper's return, emulated at every call site
        SymSt st = symIn.count(R) ? symIn[R] : SymSt();
        bool lost = st.lost;
        auto pop = [&]() { if (!st.stk.empty()) { int v = st.stk.back(); st.stk.pop_back(); return v; } return st.pulled++; };
        if (op != 0x40 && !st.touched && !lost) continue;   // rts/rtl on an untouched stack: a normal return
        // rti: P + 2-byte address (+ bank on 65816 native) -- never a jsr frame; rtl: 3-byte address
        uint32_t frame = op == 0x60 ? 2 : op == 0x6B ? 3 : (w816 && kv.second.st.e != 1 ? 4 : 3);
        bool fine = !lost && !(op == 0x40 && st.jsr);
        int k0 = -2;
        for (uint32_t q = 0; fine && q < frame; q++) {
            int v = pop();
            if (v < 0) { fine = false; break; }
            if (q == 0) { k0 = v; if (k0 % (int)frame) fine = false; }
            else if (v != k0 + (int)q) fine = false;     // bytes of one frame, in order (not swapped)
        }
        if (fine) continue;                             // a caller's frame, untouched or pulled and pushed back as is
        bool tbl = false;
        for (auto &t : a.tables) if ((t.kind == TK_RTS || t.kind == TK_RTSLONG || t.kind == TK_SPLIT) && t.user == R && !lost) tbl = true;   // pushed straight from this site's table loads
        if (!tbl) why("return to an address that is not a caller's frame (rts dispatch) at " + h4(R));
    }
    if (!rmwC.empty()) {
        // runs once: no cycle through it in the decoded CFG (returns go to every call continuation), its
        // code is entered from one place only (at most one jsr/jsl, the image's only entry, no table or
        // computed target, no entry also reached by other flow), flow is fully known and no other store
        // reaches the byte
        std::string allWhy = first; if (all) for (auto &x : *all) allWhy += "\n" + x;
        // flow fully known; a decode stop exactly at an RMW target byte is the stop that byte's own
        // possible values cause (not an unseen path), so it does not count
        bool flowOk = all && a.refused.empty() && a.heldBack.empty() && a.unknownStops.empty() && allWhy.find("rts dispatch") == std::string::npos;
        for (auto &d : a.dispatch) if (d.second.compare(0, 8, "unknown:") == 0) flowOk = false;
        for (auto &bd : a.bad) { bool own = false; for (auto &c : rmwC) if (bd.first == c.x) own = true; if (!own) flowOk = false; }
        int nEntry = 0; for (auto &l : a.labels) if (l.second & LK_ENTRY) nEntry++;
        std::map<uint32_t, std::vector<uint32_t>> succ, pred;      // pred: without return edges
        std::vector<uint32_t> conts;
        auto opAt = [&](uint32_t x) -> int { auto c = a.code.find(x); return c == a.code.end() ? -1 : c->second.in.b[0]; };
        auto noRet = [&](uint32_t X, const CodeInsn &ci) { uint8_t op = ci.in.b[0]; return (op == 0x20 || op == 0x22 || op == 0xFC) && a.noretSites.count(X) && opAt(X) == op; };
        for (auto &kv : allForms) { uint8_t op = kv.second.in.b[0]; if ((op == 0x20 || op == 0x22 || op == 0xFC) && !noRet(kv.first, kv.second)) conts.push_back(kv.first + kv.second.in.len); }
        for (auto &kv : allForms) {
            uint32_t X = kv.first; uint8_t op = kv.second.in.b[0];
            bool term = op == 0x60 || op == 0x40 || op == 0x6B || op == 0x4C || op == 0x5C || op == 0x80 || op == 0x82 || op == 0x6C || op == 0x7C || op == 0xDC || op == 0x00 || op == 0x02 || op == 0xDB;
            if (cpu == Cpu::C6502 && op == 0x80) term = false;
            if (noRet(X, kv.second)) term = true;
            if (!term && a.code.count(X + kv.second.in.len)) { succ[X].push_back(X + kv.second.in.len); pred[X + kv.second.in.len].push_back(X); }
            if (op == 0x60 || op == 0x40 || op == 0x6B) for (uint32_t c : conts) succ[X].push_back(c);
        }
        for (auto &kv : a.ctlSrc) for (uint32_t s0 : kv.second) if (s0 != ~0u) { succ[s0].push_back(kv.first); pred[kv.first].push_back(s0); }
        AddrMap amR(img);
        for (auto &c : rmwC) {
            bool once = flowOk && nEntry == 1 && !patchedIn.count(c.x) && !(strictSmc && anyUnk);
            int cover = 0;
            for (auto &g : allW) { uint32_t gl = g.lo & 0xFFFFFF; bool hitg = (g.lo & 0x1000000u) ? ((c.x & 0xFFFF) >= gl && (c.x & 0xFFFF) < gl + g.n) : (c.x >= gl && c.x < gl + g.n); if (hitg) cover++; }
            if (cover != 1) once = false;
            if (once) {     // no cycle through A
                std::set<uint32_t> seen; std::vector<uint32_t> st(succ[c.A].begin(), succ[c.A].end());
                while (!st.empty() && once) { uint32_t y = st.back(); st.pop_back(); if (y == c.A) { once = false; break; } if (!seen.insert(y).second) continue; if (seen.size() > 50000) { once = false; break; } for (uint32_t z : succ[y]) st.push_back(z); }
            }
            if (once) {     // callers
                std::set<uint32_t> seen; std::vector<uint32_t> st{c.A}; int calls = 0, entries = 0;
                while (!st.empty() && once) {
                    uint32_t y = st.back(); st.pop_back();
                    if (!seen.insert(y).second) continue;
                    if (seen.size() > 50000) { once = false; break; }
                    auto cs = a.ctlSrc.find(y);
                    bool ent = cs != a.ctlSrc.end() && cs->second.count(~0u);
                    if (ent) { entries++; if (!(a.labels.count(y) && (a.labels.at(y) & LK_ENTRY))) once = false; if (pred.count(y)) once = false; }
                    if (cs != a.ctlSrc.end()) for (uint32_t s0 : cs->second) if (s0 != ~0u) {
                        int po = opAt(s0);
                        if (po == 0x20 || po == 0x22) calls++;
                        else if (po < 0 || po == 0x6C || po == 0x7C || po == 0xDC || po == 0xFC || a.dispatch.count(s0)) once = false;
                    }
                    for (uint32_t z : pred[y]) st.push_back(z);
                }
                if (calls > 1 || entries != 1) once = false;
            }
            int v = -1;
            if (once) {
                size_t avl; const uint8_t *pp = amR.at(c.x, avl);
                if (pp && avl) {
                    int o0 = *pp; uint8_t op = c.op;
                    switch (op) {
                    case 0x06: case 0x0E: case 0x16: case 0x1E: v = (o0 << 1) & 0xFF; break;
                    case 0x46: case 0x4E: case 0x56: case 0x5E: v = o0 >> 1; break;
                    case 0x26: case 0x2E: case 0x36: case 0x3E: if (c.c >= 0) v = ((o0 << 1) | c.c) & 0xFF; break;
                    case 0x66: case 0x6E: case 0x76: case 0x7E: if (c.c >= 0) v = (o0 >> 1) | (c.c << 7); break;
                    case 0xE6: case 0xEE: case 0xF6: case 0xFE: v = (o0 + 1) & 0xFF; break;
                    case 0xC6: case 0xCE: case 0xD6: case 0xDE: v = (o0 - 1) & 0xFF; break;
                    case 0x04: case 0x0C: if (c.av >= 0) v = o0 | c.av; break;
                    case 0x14: case 0x1C: if (c.av >= 0) v = o0 & ~c.av & 0xFF; break;
                    default:
                        if ((op & 0x0F) == 0x07) v = (op & 0x80) ? (o0 | (1 << ((op >> 4) & 7))) : (o0 & ~(1 << ((op >> 4) & 7)) & 0xFF);
                    }
                }
            }
            Mod m{c.x, 1, c.A, false}; m.v = v; modOut.push_back(m);
        }
    }
    return first;
}

// Bytes of instructions that run only before any store can have run: from the single entry point
// (reached by nothing else), straight-line flow through instructions that write no memory, along
// fall-through (no other flow lands there) or jmp/bra/brl (their only source). The first
// instruction that may write (or that branches, calls or returns) is included and ends the walk.
// Valid only when flow is fully known (flowComplete): an unresolved indirect jump, a refused target, bytes left
// undecoded after a call, or any place where decoding stopped -- code there could jump back in.
static bool flowComplete(const Analysis &a, const std::string &cswWhy) {
    if (!a.bad.empty() || !a.refused.empty() || !a.heldBack.empty() || !a.unknownStops.empty()) return false;
    for (auto &d : a.dispatch) if (d.second.compare(0, 8, "unknown:") == 0) return false;   // flow after a call left undecoded
    return cswWhy.find("rts dispatch") == std::string::npos;                        // a return to a computed address
}
static std::set<uint32_t> preStoreBytes(const Analysis &a) {      // flowComplete(a) is checked by the caller
    std::set<uint32_t> out;
    for (uint32_t s : a.indSites) {
        bool res = false;
        for (auto &t : a.tables) if (t.user == s) res = true;
        if (!res) return out;
    }
    uint32_t E = ~0u; int ne = 0;
    for (auto &l : a.labels) if (l.second & LK_ENTRY) { E = l.first; ne++; }
    if (ne != 1) return out;
    auto src = [&](uint32_t x) -> const std::set<uint32_t> * { auto f = a.ctlSrc.find(x); return f == a.ctlSrc.end() ? nullptr : &f->second; };
    const auto *se = src(E);
    if (!se || se->size() != 1 || *se->begin() != ~0u) return out;
    static const char *safe[] = {"lda","ldx","ldy","tax","tay","txa","tya","tsx","txs","tcd","tdc","tcs","tsc","txy","tyx","xba",
        "clc","sec","cli","sei","cld","sed","clv","rep","sep","xce","inx","iny","dex","dey","cmp","cpx","cpy","and","ora","eor",
        "adc","sbc","bit","nop","pla","plx","ply","plp","pld","plb"};
    std::set<uint32_t> seen;
    uint32_t x = E;
    for (int n = 0; n < 4096; n++) {
        auto c = a.code.find(x);
        if (c == a.code.end() || !seen.insert(x).second) break;
        const Insn &in = c->second.in;
        for (uint32_t q = 0; q < in.len; q++) out.insert(x + q);
        std::string m = in.mnemonic.substr(0, 3);
        for (auto &ch : m) ch = (char)tolower((unsigned char)ch);
        uint8_t op = in.b[0];
        if (op == 0x54 || op == 0x44) { for (uint32_t q = 0; q < in.len; q++) out.erase(x + q); break; }   // mvn/mvp re-run themselves
        bool acc = (op == 0x1A || op == 0x3A);          // inc a / dec a
        bool ok = acc;
        for (auto *k : safe) if (m == k) ok = true;
        uint32_t nx;
        if (op == 0x4C) nx = (x & 0xFF0000) | in.b[1] | in.b[2] << 8;
        else if (op == 0x80) nx = (x & 0xFF0000) | ((x + 2 + (int8_t)in.b[1]) & 0xFFFF);
        else if (op == 0x82) nx = (x & 0xFF0000) | ((x + 3 + (int16_t)(in.b[1] | in.b[2] << 8)) & 0xFFFF);
        else if (ok) nx = x + in.len;
        else break;
        const auto *sn = src(nx);
        if (op == 0x4C || op == 0x80 || op == 0x82) {
            if (!sn || sn->size() != 1 || *sn->begin() != x) break;
            auto p = a.code.lower_bound(nx >= 4 ? nx - 4 : 0);     // nothing falls into (or overlaps) the target
            bool fall = false;
            for (; p != a.code.end() && p->first < nx; ++p) {
                uint32_t e = p->first + p->second.in.len;
                uint8_t po = p->second.in.b[0];
                bool term = po == 0x60 || po == 0x6B || po == 0x40 || po == 0x4C || po == 0x5C || po == 0x80 || po == 0x82 || po == 0x6C || po == 0x7C || po == 0xDC;
                if (e > nx || (e == nx && !term)) fall = true;
            }
            if (fall) break;
        } else if (sn) break;
        x = nx;
    }
    return out;
}

// Bytes a store with a known value writes before the instruction holding them can run, on every path:
// the store is reached from that instruction by walking straight back along fall-through edges no
// other flow enters (no transfer target, entry or label on the way). Only the stored form runs there.
// Needs fully known flow (an unresolved jump could enter the walk) and no other store reaching the byte.
// Dominance of known-value patches over the decoded flow graph (a must-store dataflow).
// A byte x that one known value is stored to is "dominated" when every store to it runs on every
// path from an entry point to the instruction holding x. A jsr continues after the call with the
// callee's must-store summary (the stores that run on every path from the callee's entry to each of
// its returns); a callee with no summary (no return found, an unresolved call) that may contain the
// store makes the order unknown. Result per byte: dominated (out: only the stored form runs), order
// unknown (stopOut: an unknown-value Mod, decoding stops there), or neither (the union: the original
// form also runs on a path that misses the store). Dominance needs fully known flow; without it a
// byte that would be dominated has an unknown order as well.
static std::set<uint32_t> dominatedBytes(const Analysis &a, const Mods &mods, bool strict, const std::string &cswWhy, bool optimistic, Mods *stopOut = nullptr, bool keepHinted = false) {
    std::set<uint32_t> out;
    bool complete = optimistic || flowComplete(a, cswWhy);   // optimistic: checked on the pass that used the result
    bool hardInc = false;    // an unresolved indirect jump or a refused entry: unknown edges from anywhere
    for (uint32_t s : a.indSites) { bool res = false; for (auto &t : a.tables) if (t.user == s) res = true; if (!res) { complete = false; hardInc = true; } }
    // where flow leaves the known graph (an unproven call continuation, a computed return, a decode stop):
    // when every such point runs only after the stores of a byte, the unknown edges cannot reach the
    // byte with the original form still in place
    std::vector<uint32_t> leaks;
    if (!a.refused.empty()) hardInc = true;
    for (auto &d : a.dispatch) if (d.second.compare(0, 8, "unknown:") == 0) leaks.push_back(d.first);   // held-back bytes and unknown stops follow such a site
    for (auto &kv : a.bad) leaks.push_back(kv.first);
    for (size_t p = 0; (p = cswWhy.find("(rts dispatch) at $", p)) != std::string::npos; p += 19) {
        uint32_t v = (uint32_t)strtoul(cswWhy.c_str() + p + 19, nullptr, 16); bool f = false;
        for (auto &kv : a.code) if ((kv.first & 0xFFFF) == v) { leaks.push_back(kv.first); f = true; }
        if (!f) hardInc = true;
    }
    std::map<uint32_t, std::set<uint32_t>> by; std::set<uint32_t> other;
    for (auto &r : mods) {
        if ((r.u || r.d) && !strict) continue;
        if (r.n == ~0u) return out;
        if (r.n == 1 && r.v >= 0) by[r.lo].insert(r.by);
        else for (uint32_t q = 0; q < r.n && q < 0x10000; q++) other.insert((r.lo & 0xFF0000) | ((r.lo + q) & 0xFFFF));
    }
    if (by.empty()) return out;
    // stores of interest -> bit index
    std::map<uint32_t, int> sIdx;
    for (auto &kv : by) for (uint32_t S : kv.second) if (!sIdx.count(S)) { int k = (int)sIdx.size(); sIdx[S] = k; }
    const int NS = (int)sIdx.size(), NW = (NS + 63) / 64;
    typedef std::vector<uint64_t> BS;
    auto top = [&]() { BS b(NW, ~0ull); return b; };
    auto bot = [&]() { BS b(NW, 0); return b; };
    auto andI = [&](BS &x, const BS &y) { for (int i = 0; i < NW; i++) x[i] &= y[i]; };
    auto orI = [&](BS &x, const BS &y) { for (int i = 0; i < NW; i++) x[i] |= y[i]; };
    auto has = [&](const BS &x, int k) { return (x[k / 64] >> (k % 64)) & 1; };
    // nodes: decoded instructions, plus each undecoded patched byte
    std::vector<uint32_t> nodes; std::map<uint32_t, int> nIdx;
    for (auto &kv : a.code) { nIdx[kv.first] = (int)nodes.size(); nodes.push_back(kv.first); }
    auto holder = [&](uint32_t x) -> uint32_t {
        auto it = a.code.upper_bound(x);
        if (it != a.code.begin() && x < std::prev(it)->first + std::prev(it)->second.in.len) return std::prev(it)->first;
        return x;
    };
    for (auto &kv : by) { uint32_t h = holder(kv.first); if (!nIdx.count(h)) { nIdx[h] = (int)nodes.size(); nodes.push_back(h); } }
    const int N = (int)nodes.size();
    auto formsAt = [&](uint32_t x, std::vector<std::pair<uint8_t, int>> &f) {
        f.clear();
        auto c = a.code.find(x); if (c == a.code.end()) return;
        f.push_back({c->second.in.b[0], c->second.in.len});
        auto v = a.variants.find(x); if (v != a.variants.end()) for (auto &ci : v->second) f.push_back({ci.in.b[0], ci.in.len});
    };
    auto isTerm = [](uint8_t op) { return op == 0x60 || op == 0x40 || op == 0x6B || op == 0x4C || op == 0x5C || op == 0x80 || op == 0x82 || op == 0x6C ||
                                          op == 0x7C || op == 0xDC || op == 0x00 || op == 0x02 || op == 0xDB; };
    auto isCall = [](uint8_t op) { return op == 0x20 || op == 0x22 || op == 0xFC; };
    auto isRet = [](uint8_t op) { return op == 0x60 || op == 0x40 || op == 0x6B; };
    // edges: plain (fall, branch, jump, call into a callee) and call continuations (jsr -> after it)
    std::vector<std::vector<int>> pl(N);                   // plain predecessors
    std::vector<std::vector<std::pair<int, std::vector<int>>>> cont(N);   // (jsr node, callee nodes) predecessors
    std::vector<std::vector<int>> plSucc(N);               // plain successors without call edges (callee-local walk)
    std::vector<std::vector<std::pair<int, std::vector<int>>>> contSucc(N);
    std::vector<bool> isEntry(N, false), ret(N, false), callN(N, false);
    std::map<uint32_t, std::vector<uint32_t>> calleesOf;   // jsr -> targets
    for (auto &kv : a.ctlSrc) for (uint32_t s : kv.second) if (s != ~0u) {
        auto c = a.code.find(s); if (c != a.code.end() && isCall(c->second.in.b[0])) calleesOf[s].push_back(kv.first);
    }
    bool unresolvedCall = false;
    for (int i = 0; i < N; i++) {
        uint32_t X = nodes[i];
        std::vector<std::pair<uint8_t, int>> f; formsAt(X, f);
        auto cs = a.ctlSrc.find(X);
        if (cs != a.ctlSrc.end() && cs->second.count(~0u)) isEntry[i] = true;
        auto lb = a.labels.find(X); if (lb != a.labels.end() && (lb->second & LK_ENTRY)) isEntry[i] = true;
        for (auto &fo : f) {
            if (isRet(fo.first)) ret[i] = true;
            uint32_t nx = X + fo.second; auto ni = nIdx.find(nx);
            if (isCall(fo.first)) {
                callN[i] = true;
                std::vector<int> cl; bool ok = true;
                auto co = calleesOf.find(X);
                // a direct call outside the decoded code (ROM, another file) runs none of these stores;
                // an unresolved indirect call may run any
                if (co == calleesOf.end()) ok = fo.first != 0xFC; else for (uint32_t t : co->second) { auto ti = nIdx.find(t); if (ti != nIdx.end()) cl.push_back(ti->second); }
                if (!ok) { unresolvedCall = true; cl.clear(); cl.push_back(-1); }
                if (ni != nIdx.end() && (!a.noretSites.count(X) || (keepHinted && a.hintNoret.count(X)))) { cont[ni->second].push_back({i, cl}); contSucc[i].push_back({ni->second, cl}); }   // a call that never returns: no continuation
            } else if (!isTerm(fo.first) && ni != nIdx.end()) { pl[ni->second].push_back(i); plSucc[i].push_back(ni->second); }
        }
    }
    for (auto &kv : a.ctlSrc) {
        auto ti = nIdx.find(kv.first); if (ti == nIdx.end()) continue;
        for (uint32_t s : kv.second) {
            if (s == ~0u) continue;
            auto si = nIdx.find(s); if (si == nIdx.end()) { isEntry[ti->second] = true; continue; }
            pl[ti->second].push_back(si->second);
            auto c = a.code.find(s); if (c != a.code.end() && isCall(c->second.in.b[0])) continue;
            plSucc[si->second].push_back(ti->second);
        }
    }
    std::vector<int> sBit(N, -1);
    for (auto &kv : sIdx) { auto ni = nIdx.find(kv.first); if (ni != nIdx.end()) sBit[ni->second] = kv.second; }
    // which stores each callee may run (reachable through its own code and nested callees)
    std::map<int, BS> mayC; std::set<int> callees;
    for (int i = 0; i < N; i++) for (auto &e : contSucc[i]) for (int c : e.second) if (c >= 0) callees.insert(c);
    for (int c : callees) {
        BS m = bot(); std::vector<int> st{c}; std::vector<bool> seen(N, false);
        while (!st.empty()) {
            int y = st.back(); st.pop_back(); if (seen[y]) continue; seen[y] = true;
            if (sBit[y] >= 0) m[sBit[y] / 64] |= 1ull << (sBit[y] % 64);
            for (int z : plSucc[y]) st.push_back(z);
            for (auto &e : contSucc[y]) { st.push_back(e.first); for (int cc : e.second) if (cc >= 0) st.push_back(cc); }
        }
        mayC[c] = m;
    }
    // callee summaries (greatest fixpoint, nested calls use the current summaries); none: no return
    std::map<int, BS> sum; std::map<int, bool> hasSum;
    for (int c : callees) { sum[c] = top(); hasSum[c] = true; }
    auto contIn = [&](const std::vector<int> &cl, const BS &o, bool &unk) {   // OUT(jsr) plus what every callee surely stores
        BS r = top(); bool any = false;
        for (int c : cl) { if (c < 0 || !hasSum[c]) { unk = true; r = bot(); any = true; break; } andI(r, sum[c]); any = true; }
        if (!any) r = bot();
        orI(r, o); return r;
    };
    for (int round = 0; round < 30; round++) {
        bool ch = false;
        for (int c : callees) {
            bool needed = false; for (int w = 0; w < NW; w++) if (mayC[c][w]) needed = true;
            if (!needed) { if (!hasSum[c] || sum[c] != bot()) { sum[c] = bot(); hasSum[c] = true; ch = true; } continue; }
            // local reach from c (no call edges; continuations instead)
            std::vector<int> reach; std::vector<bool> seen(N, false); std::vector<int> st{c};
            while (!st.empty()) { int y = st.back(); st.pop_back(); if (seen[y]) continue; seen[y] = true; reach.push_back(y);
                for (int z : plSucc[y]) st.push_back(z);
                for (auto &e : contSucc[y]) st.push_back(e.first); }
            std::map<int, BS> IN; for (int y : reach) IN[y] = top(); IN[c] = bot();
            auto outOf = [&](int y) { BS o = IN[y]; if (sBit[y] >= 0) o[sBit[y] / 64] |= 1ull << (sBit[y] % 64); return o; };
            for (int it = 0; it < 200; it++) {
                bool c2 = false;
                for (int y : reach) {
                    if (y == c) continue;
                    BS n = top();
                    for (int p : pl[y]) if (seen[p]) { auto cc = a.code.find(nodes[p]); if (cc != a.code.end() && isCall(cc->second.in.b[0])) continue; andI(n, outOf(p)); }
                    for (auto &e : cont[y]) if (seen[e.first]) { bool u = false; andI(n, contIn(e.second, outOf(e.first), u)); }
                    if (n != IN[y]) { IN[y] = n; c2 = true; }
                }
                if (!c2) break;
            }
            BS s = top(); bool anyR = false;
            for (int y : reach) if (ret[y]) { andI(s, outOf(y)); anyR = true; }
            bool hs = anyR;
            if (!hs) s = bot();
            if (hs != hasSum[c] || s != sum[c]) { sum[c] = s; hasSum[c] = hs; ch = true; }
        }
        if (!ch) break;
        if (round == 29) for (int c : callees) { hasSum[c] = false; sum[c] = bot(); }
    }
    // whole-image must-store sets
    std::vector<BS> IN(N, top()); std::vector<bool> unkOrd(N, false);
    auto outN = [&](int y) { BS o = IN[y]; if (sBit[y] >= 0) o[sBit[y] / 64] |= 1ull << (sBit[y] % 64); return o; };
    for (int i = 0; i < N; i++) if (isEntry[i]) IN[i] = bot();
    for (int it = 0; it < 400; it++) {
        bool ch = false;
        for (int y = 0; y < N; y++) {
            if (isEntry[y]) continue;
            BS n = top(); bool u = unkOrd[y];
            for (int p : pl[y]) { andI(n, outN(p)); if (unkOrd[p]) u = true; }
            for (auto &e : cont[y]) { bool uu = false; andI(n, contIn(e.second, outN(e.first), uu)); if (uu || unkOrd[e.first]) u = true; }
            if (n != IN[y] || u != unkOrd[y]) { IN[y] = n; unkOrd[y] = u; ch = true; }
        }
        if (!ch) break;
        if (it == 399) complete = false;
    }
    for (auto &kv : by) {
        uint32_t x = kv.first;
        if (other.count(x)) continue;
        int h = nIdx[holder(x)];
        bool dom = true;
        for (uint32_t S : kv.second) if (!has(IN[h], sIdx[S])) dom = false;
        bool inUnk = false;      // a store of x may run inside a callee with no summary on the way
        if (!dom && (unkOrd[h] || unresolvedCall)) for (uint32_t S : kv.second) {
            if (unresolvedCall) inUnk = true;
            for (int c : callees) if (!hasSum[c] && has(mayC[c], sIdx[S])) inUnk = true;
        }
        // the union is harmless when every form of the instruction has the same length and none
        // changes flow, the stack or the widths: the original form then makes no other byte code
        bool benign = false;
        {
            auto c = a.code.find(holder(x));
            if (c != a.code.end()) {
                auto ok = [](uint8_t op) {
                    if ((op & 0x1F) == 0x10) return false;      // conditional branches
                    static const uint8_t bad[] = {0x4C,0x5C,0x6C,0x7C,0xDC,0x20,0x22,0xFC,0x60,0x40,0x6B,0x00,0x02,0xDB,0xCB,0x80,0x82,
                        0xC2,0xE2,0xFB,0x28,0x08,0x48,0x68,0xDA,0xFA,0x5A,0x7A,0x8B,0xAB,0x0B,0x2B,0x4B,0x62,0xF4,0xD4,0x9A,0x1B,0xBA,0x3B,0x5B,0x7B,0x42,0xEB};
                    for (uint8_t b : bad) if (op == b) return false;
                    if ((op & 0x0F) == 0x0F) return false;      // bbr/bbs (65C02), long ops
                    return true;
                };
                benign = ok(c->second.in.b[0]);
                auto v = a.variants.find(c->first);
                if (v != a.variants.end()) for (auto &ci : v->second) if (ci.in.len != c->second.in.len || !ok(ci.in.b[0])) benign = false;
            }
        }
        bool leakOk = false;     // flow incomplete, but every unknown edge starts after the stores of x
        if (dom && !complete && !hardInc && !unresolvedCall) {
            leakOk = true;
            for (uint32_t L : leaks) {
                auto li = nIdx.find(L);
                if (li == nIdx.end()) { auto hl = nIdx.find(holder(L)); if (hl == nIdx.end()) { leakOk = false; break; } li = hl; }
                BS o = outN(li->second);
                if (unkOrd[li->second]) { leakOk = false; break; }
                for (uint32_t S : kv.second) if (!has(o, sIdx[S])) leakOk = false;
                if (!leakOk) break;
            }
        }
        // a shorter patched form that falls through would run code inside the original instruction,
        // which the listing cannot show: no proof (decoding stops there instead)
        bool shortFall = false;
        if (auto c = a.code.find(holder(x)); c != a.code.end()) if (auto v = a.variants.find(c->first); v != a.variants.end())
            for (auto &ci : v->second) if (ci.in.len < c->second.in.len && !isTerm(ci.in.b[0])) shortFall = true;
        if (dom && !shortFall && (complete || leakOk)) out.insert(x);
        else if ((dom || inUnk) && !benign && stopOut) for (uint32_t S : kv.second) { Mod m{x, 1, S}; m.v = -1; stopOut->push_back(m); }
    }
    return out;
}


// may a decoded instruction touch the language-card switches $C080-$C08F (and so map RAM over the
// ROM)? Any constant address in the range, an indexed base whose reach covers it, and every access
// through a pointer, a stack-relative or long-indexed address or a block move count.
static bool lcAccess(const Analysis &a, Cpu cpu) {
    auto hit = [](uint32_t lo, uint32_t hi) { return lo <= 0xC08F && hi >= 0xC080; };
    auto one = [&](const Insn &in, int8_t xw) -> bool {
        uint8_t op = in.b[0], lo = op & 0x1F;
        if (op == 0x20 || op == 0x4C || op == 0x22 || op == 0x5C) return false;       // direct transfers: target, not data
        if (op == 0x6C || op == 0xDC || op == 0x7C || op == 0xFC) {                   // indirect jumps read their pointer
            uint32_t ab = in.b[1] | (in.b[2] << 8);
            uint32_t hi = ab + (op == 0xDC ? 2 : 1) + ((op == 0x7C || op == 0xFC) ? (xw == 1 ? 0xFF : 0xFFFF) : 0);
            return hit(ab, hi);
        }
        if (op == 0x44 || op == 0x54) return true;                                     // mvp/mvn
        if (lo == 0x01 || lo == 0x11 || lo == 0x12) return true;                       // (dp,x) (dp),y (dp)
        if (cpu == Cpu::C65816 && (lo == 0x07 || lo == 0x17 || lo == 0x03 || lo == 0x13)) return true;   // [dp] [dp],y sr,s (sr,s),y
        if (in.len == 3) {
            uint32_t ab = in.b[1] | (in.b[2] << 8);
            if ((op & 0x1F) == 0x10 || op == 0x80 || op == 0x82 || op == 0x62 || op == 0xF4) return false;   // branches, per, pea
            if (op == 0x0F || (cpu != Cpu::C65816 && (op & 0x0F) == 0x0F)) return false;   // bbr/bbs: zero page
            bool idx = lo == 0x19 || lo == 0x1D || lo == 0x1E || op == 0x3C || op == 0xBC;   // abs,x / abs,y
            uint32_t reach = xw == 1 ? 0xFF : 0xFFFF;
            return idx ? hit(ab, ab + reach) : hit(ab, ab);
        }
        if (in.len == 4 && cpu == Cpu::C65816) {
            uint32_t ab = in.b[1] | (in.b[2] << 8) | (in.b[3] << 16);
            if (lo == 0x1F) return true;                                               // long,x
            uint32_t bk = ab >> 16;
            return (bk == 0 || bk == 0xE0 || bk == 0xE1) && hit(ab & 0xFFFF, ab & 0xFFFF);
        }
        return false;
    };
    // the direct page is at $0000 unless code moves it (tcd/pld): then every direct-page access counts
    bool dMoved = false;
    if (cpu == Cpu::C65816) for (auto &kv : a.code) if (kv.second.in.b[0] == 0x5B || kv.second.in.b[0] == 0x2B) dMoved = true;
    if (dMoved) for (auto &kv : a.code) { const Insn &in = kv.second.in; uint8_t lo = in.b[0] & 0x1F;
        if (in.len == 2 && (lo == 0x05 || lo == 0x06 || lo == 0x04 || lo == 0x15 || lo == 0x16 || lo == 0x14 || in.b[0] == 0xB6 || in.b[0] == 0x96) &&
            in.b[0] != 0x44 && in.b[0] != 0x54 && in.b[0] != 0xD4 && in.b[0] != 0xF4) return true; }
    for (auto &kv : a.code) if (one(kv.second.in, cpu == Cpu::C65816 ? -1 : 1)) return true;
    for (auto &kv : a.variants) for (auto &ci : kv.second) if (one(ci.in, cpu == Cpu::C65816 ? -1 : 1)) return true;
    return false;
}

static bool analyzeCore(const Image &img, const Hints &h, const AnalyzeOptions &o, Decoder &dec, Analysis &out) {
    TableLimits limits;
    std::set<uint32_t> revoked;         // auto inline routines disproved by a call site or by flow
    std::set<uint32_t> stopAfter, stopRevoked;   // outside routines whose string-like call sites end flow
    std::set<uint32_t> carryRevoked;    // G1: helpers whose loop-exit carry is joined by another path
    std::map<uint32_t, std::string> lenDropped;   // length-prefixed auto rules dropped by a misfit -> why
    AddrMap am(img);
    std::string cswWhy, relocNote;      // non-empty: COUT $FDED is not trusted (why)
    std::set<uint32_t> patched;         // immediate operand bytes written by exact stores (values unknown)
    int patchRuns = 0;
    Mods mods;                          // code bytes other stores may change (the helper emulation refuses them)
    std::set<uint32_t> preStore;        // bytes that run before any store (see preStoreBytes); must hold on the final pass
    bool preFailed = false; int preRuns = 0;
    std::vector<std::string> lastWhy;   // every reason the last cswRisk run found
    bool unionMode = false; int fixRuns = 0;
    bool domOpt = true;                 // dominance tried before flow is known complete; dropped if the settled pass is not
    std::set<uint32_t> domBytes;        // bytes only the stored form of reaches (see dominatedBytes); part of the fixpoint
    std::set<uint32_t> notDom;          // bytes once found not dominated (never trusted again)
    std::set<uint32_t> sysFailBad;      // _SysFailMgr sites also entered by a jump (sticky)
    std::set<uint32_t> hintDom;         // dominated bytes that rest on a noreturn hint (tagged in the listing)
    bool lcRisk = false;                // decoded code may switch the language card (ROM no-return list off)
    for (int iter = 0; iter < 64; iter++) {
        Analysis a;
        a.lcRiskIn = lcRisk;
        a.hintDomIn = hintDom;
        a.sysFailBadIn = sysFailBad;
        analyzeOnce(img, h, o, dec, a, cswWhy, patched, mods, limits, revoked, stopAfter, carryRevoked, preStore, domBytes);
        bool changed = false;
        // _SysFailMgr needs X = $1503 from the ldx right before it: a site also entered by a jump is an ordinary call
        { bool nb = false; for (uint32_t x : a.sysFailIn) { auto cs = a.ctlSrc.find(x); auto lb = a.labels.find(x);
              if ((cs != a.ctlSrc.end() && !cs->second.empty()) || lb != a.labels.end()) nb |= sysFailBad.insert(x).second; }
          if (nb) continue; }
        // sticky: once decoded code may switch the language card, ROM calls are ordinary calls
        if (!lcRisk && o.platform == Platform::ProDOS8 && a.romNoret && lcAccess(a, dec.cpu())) { lcRisk = true; continue; }
        // COUT $FDED is trusted only when nothing decoded may change CSW or code (cswRisk); recomputed
        // after every pass, the patched operands and changed-code ranges only grow (so this settles)
        // greatest fixpoint: every byte starts trusted; each pass recomputes all store ranges (index
        // ranges, D sets, pointers, loop bounds) from its own widths and values and replaces the
        // previous mods/patched/CSW verdict; done when a pass reproduces exactly what it used, so no
        // store under the final widths reaches a byte (opcode, operand or branch offset) treated as
        // trusted. Not settled within the cap: fall back to the round-2 accumulation.
        if (!unionMode) {
            std::string rn;
            std::set<uint32_t> pt; Mods md;
            std::vector<std::string> wh;
            std::string w = cswRisk(img, a, dec.cpu(), o.platform, o.entryState.e, &rn, patched, pt, md, &wh, &mods, o.strictSmc);
            { Mods u; for (auto &r : md) if (std::find(u.begin(), u.end(), r) == u.end()) u.push_back(r); md.swap(u); }   // discovery order (names the first store)
            auto sortedEq = [](Mods x, Mods y) { std::sort(x.begin(), x.end()); std::sort(y.begin(), y.end()); return x == y; };
            // a stop may hide the very store that caused it (the pass flips between two answers): after a
            // few passes the stores found only grow, which settles and keeps every store seen
            { for (auto &r : mods) if (std::find(md.begin(), md.end(), r) == md.end()) md.push_back(r); pt.insert(patched.begin(), patched.end()); }
            // flow checks see every reason, not only the first (an rts-trick return is a computed edge
            // even when another reason is named first)
            std::string allW; for (auto &x : wh) allW += x + "\n";
            Mods stopM;
            std::set<uint32_t> dm = dominatedBytes(a, md, o.strictSmc, allW, domOpt, &stopM);
            std::set<uint32_t> hd;     // dominated only because a hinted call is taken not to return
            if (!a.hintNoret.empty()) { Mods tm; std::set<uint32_t> d2 = dominatedBytes(a, md, o.strictSmc, allW, domOpt, &tm, true); for (uint32_t x : dm) if (!d2.count(x)) hd.insert(x); }
            hd.insert(hintDom.begin(), hintDom.end());     // grows only
            for (auto &r : stopM) if (std::find(md.begin(), md.end(), r) == md.end()) md.push_back(r);   // order unknown: sticky
            // sticky verdicts: once a pass finds COUT/CSW at risk it stays at risk (trusting it again
            // could hide the very store that caused it)
            if (w.empty() && !cswWhy.empty()) w = cswWhy;
            // a byte found not dominated stays so (trust only shrinks)
            for (uint32_t x : domBytes) if (!dm.count(x)) notDom.insert(x);
            for (uint32_t x : notDom) dm.erase(x);
            if (!sortedEq(md, mods) || pt != patched || w != cswWhy || dm != domBytes || hd != hintDom) {
                mods = md; patched = pt; cswWhy = w; domBytes = dm; hintDom = hd;
                if (getenv("DUMPAPPLE_PASSES") && fixRuns + 1 > 40) fprintf(stderr, "dumpapple: fixpoint pass cap hit\n");
                if (++fixRuns > 40) { unionMode = true; mods.clear(); patched.clear(); cswWhy.clear(); domBytes.clear(); patchRuns = 0; preStore.clear(); preRuns = 0; preFailed = false; }
                iter--; continue;
            }
            if (domOpt && !domBytes.empty() && !flowComplete(a, allW)) { domOpt = false; domBytes.clear(); iter--; continue; }
            if (getenv("DUMPAPPLE_PASSES")) fprintf(stderr, "dumpapple: fixpoint passes %d\n", fixRuns);
            relocNote = rn; lastWhy = wh;
        } else if (patchRuns <= 8) {
            std::string rn;
            std::set<uint32_t> pt; Mods md;
            lastWhy.clear();
            std::string w = cswRisk(img, a, dec.cpu(), o.platform, o.entryState.e, &rn, patched, pt, md, &lastWhy, &mods, o.strictSmc);
            relocNote = rn;
            bool grow = false;
            if (cswWhy.empty() && !w.empty()) { cswWhy = w; grow = true; }
            for (uint32_t x : pt) if (patched.insert(x).second) grow = true;
            for (auto &r : md) if (std::find(mods.begin(), mods.end(), r) == mods.end()) { mods.push_back(r); grow = true; }
            if (grow) {
                if (++patchRuns > 8) { mods.assign(1, Mod{0, ~0u, 0}); if (cswWhy.empty()) cswWhy = "self-modified code did not settle"; }
                iter--; continue;
            }
            patchRuns = 9;      // settled
        }
        // the pre-store region the pass used must still hold on its own result; else shrink and redo
        if ((!mods.empty() || !patched.empty()) && !preFailed) {
            // tried on the code it lets through (growing, then only shrinking); kept only if the
            // pass that used it has fully known flow
            std::set<uint32_t> p = preStoreBytes(a), np;
            if (preRuns < 16) np = p;
            else for (uint32_t x : preStore) if (p.count(x)) np.insert(x);
            if (iter >= 40) np.clear();
            if (np != preStore) { preStore = np; preRuns++; patchRuns = 0; continue; }
            std::string allW; for (auto &x : lastWhy) allW += x + "\n";
            if (!preStore.empty() && !flowComplete(a, allW + cswWhy)) { preFailed = true; preStore.clear(); patchRuns = 0; continue; }
        }
        // G1: a carry taken from the loop exit holds only if X is entered by the exit branch alone:
        // (a) nothing falls into X, (b) no other control transfer lands in [X, adc],
        // (c) no unresolved indirect jump exists anywhere in the image; a clc/sec in the exit
        // block or right before the adc only needs (b) for the range after it, plus (c)
        for (auto &cc : a.carryClaims) {
            const auto &c = cc.second;
            std::string why;
            if (c.branch) {
                for (auto it = a.code.lower_bound(c.from >= 4 ? c.from - 4 : 0); it != a.code.end() && it->first < c.from; ++it) {
                    uint32_t e = it->first + it->second.in.len;
                    if (e < c.from) continue;
                    uint8_t op = it->second.in.b[0];
                    bool stop = op == 0x60 || op == 0x6B || op == 0x40 || op == 0x4C || op == 0x5C || op == 0x80 || op == 0x82 || op == 0x00 ||
                                op == 0x6C || op == 0x7C || op == 0xDC || op == 0xDB;
                    if (e > c.from || !stop) { why = "fall-through"; break; }
                }
            }
            // any unresolved indirect jump/call could land on the adc itself: no exception,
            // not even for a clc/sec right before it
            for (uint32_t s : a.indSites) {
                if (s > c.adc && s < c.hi) continue;           // the helper's own return through the pointer
                bool res = false;
                for (auto &t : a.tables) if (t.user == s) res = true;
                if (!res) { why = "indirect"; break; }
            }
            for (auto t = a.ctlSrc.lower_bound(c.from); why.empty() && t != a.ctlSrc.end() && t->first <= c.adc; ++t)
                for (uint32_t s : t->second)
                    if (!(c.branch && t->first == c.from && s == c.exitBr)) { why = "join"; break; }
            if (!why.empty() && carryRevoked.insert(cc.first).second) changed = true;
        }
        if (changed) continue;
        // tentative auto inline rule: drop it for a routine when any call site does not
        // fit, or when flow (a refused target or a code label) lands inside one of its blocks
        for (auto &rb : a.varAutoBlocks) {
            bool bad = a.varMisfit.count(rb.first) > 0;
            for (auto &b : rb.second) {
                if (bad) break;
                auto r = a.refused.lower_bound(b.first);
                if (r != a.refused.end() && *r < b.first + b.second) bad = true;
                for (auto l = a.labels.lower_bound(b.first); !bad && l != a.labels.end() && l->first < b.first + b.second; ++l)
                    if (l->second & (LK_CODE | LK_SUB | LK_ENTRY)) bad = true;
            }
            if (bad) {
                revoked.insert(rb.first); changed = true;
                auto k = a.varInlineRoutines.find(rb.first);
                if (k != a.varInlineRoutines.end() && k->second == 7)
                    lenDropped[rb.first] = a.varMisfit.count(rb.first) ? "a call site does not fit the length rule" : "flow lands inside an inline block";
            }
        }
        for (uint32_t t : a.varMisfit) if (!a.varAutoBlocks.count(t) && !revoked.count(t)) { revoked.insert(t); changed = true; }
        if (changed) continue;
        if (o.autoInline) {
            for (uint32_t t : a.stopMisfit) if (stopAfter.erase(t)) { stopRevoked.insert(t); changed = true; }
            if (!changed)
                for (auto &kv : qualifyExternal(img, h, o, dec, a))
                    if (!stopAfter.count(kv.first) && !stopRevoked.count(kv.first)) { stopAfter.insert(kv.first); changed = true; }
            if (changed) continue;
        }
        std::set<uint32_t> loadsAt, loadBases, dispBases;
        refSets(a.code, dec.cpu() == Cpu::C65816, loadsAt, loadBases, dispBases);
        for (auto &t : a.tables) {
            if (t.hinted) continue;
            for (uint32_t i = 0; i < t.count && !changed; i++) {
                uint32_t e = t.addr + i * t.entrySize(), ee = e + t.entrySize();
                std::string why;
                if (t.kind == TK_SPLIT) {                       // the high-byte entry
                    uint32_t he = t.hiAddr + i;
                    if (a.refused.count(he)) why = "code reached later at " + hex6(he);
                    auto l = a.labels.find(he);
                    if (why.empty() && l != a.labels.end() && !(he == t.hiAddr && !(l->second & (LK_CODE | LK_SUB | LK_ENTRY)))) why = "reference into table at " + hex6(he);
                    if (why.empty() && i > 0 && (dispBases.count(he) || loadBases.count(he) || loadsAt.count(he))) why = "read by a load at " + hex6(he);
                }
                auto r = a.refused.lower_bound(e);
                if (r != a.refused.end() && *r < ee) why = "code reached later at " + hex6(*r);
                if (i > 0 && why.empty()) {
                    // a later-found dispatch site whose table starts here splits the table;
                    // an indexed load based here, or a plain load of any entry byte, ends it
                    if (dispBases.count(e)) why = "another dispatch site's table starts at " + hex6(e);
                    else if (loadBases.count(e)) why = "indexed load base at " + hex6(e);
                    else for (uint32_t q = e; q < ee && why.empty(); q++) if (loadsAt.count(q)) why = "read by a load at " + hex6(q);
                }
                if (why.empty() && t.kind != TK_SPLIT) {
                    size_t av; const uint8_t *p = am.at(e, av);
                    if (p && av >= t.entrySize()) {
                        uint32_t tg = tableTarget(t, p);
                        auto c = a.code.upper_bound(tg);
                        if (c != a.code.begin()) { --c; if (c->first != tg && tg < c->first + c->second.in.len && (c->second.in.b[0] == 0x00 || c->second.in.b[0] == 0x02)) why = "target inside the instruction at " + hex6(c->first); }
                    }
                }
                for (auto l = a.labels.lower_bound(e); why.empty() && l != a.labels.end() && l->first < ee; ++l) {
                    if (l->first == t.addr && !(l->second & (LK_CODE | LK_SUB | LK_ENTRY))) continue;   // its own label
                    why = "reference into table at " + hex6(l->first);
                }
                if (why.empty()) continue;
                limits[t.addr] = {i, why};
                changed = true;
            }
            if (changed) break;      // one truncation per pass keeps the result order-independent
        }
        if (!changed) {
            for (auto &kv : a.refused)
                if (a.notes.size() < 1000) {
                    bool inTable = false;
                    for (auto &t : a.tables) if (kv >= t.addr && kv < t.end()) inTable = true;
                    a.notes.push_back(std::string("flow into ") + (inTable ? "hinted table" : "data") + " at " + hex6(kv) + " not followed");
                }
            for (auto &kv : lenDropped)
                a.notes.push_back("length-prefixed helper " + hex6(kv.first) + ": " + kv.second + "; inline length not applied");
            for (auto &kv : limits)
                if (kv.second.first == 0) a.notes.push_back("auto table candidate at " + hex6(kv.first) + " rejected: " + kv.second.second);
            // a relocated field pointing into held-back bytes is usually a data pointer:
            // note it, but do not decode (code use comes in as jsr/jsl/jmp/jml, tables or callback pairs)
            for (auto &sg : img.segs) for (auto &r : sg.relocs) {
                if (r.size < 2 || r.shift != 0) continue;
                uint32_t f = sg.base + r.offset;
                if (a.code.count(f) || f + r.size > sg.base + sg.data.size()) continue;
                bool inInsn = false;
                auto c = a.code.upper_bound(f);
                if (c != a.code.begin()) { --c; inInsn = f < c->first + c->second.in.len; }
                if (inInsn) continue;           // an instruction operand: its use is already followed
                const uint8_t *q = &sg.data[r.offset];
                uint32_t v = q[0] | (q[1] << 8) | (r.size >= 3 ? q[2] << 16 : (f & 0xFF0000));
                auto hb = a.heldBack.upper_bound(v);
                if (hb == a.heldBack.begin()) continue;
                --hb;
                if (v < hb->first + hb->second && !a.code.count(v))
                    a.notes.push_back("relocated pointer at " + hex6(f) + " -> " + hex6(v) + " points into held-back bytes after a call; data pointer, not decoded");
            }
            if (o.autoInline) for (auto &kv : qualifyExternal(img, h, o, dec, a))
                a.notes.push_back("suggested hint: inline " + hex6(kv.first) + " z (" + std::to_string(kv.second) + " call sites look like strings)");
            if (!relocNote.empty() && o.autoInline) a.notes.push_back(relocNote);
            for (auto &r : mods) if (r.u && r.by && a.code.count(r.by)) a.unkStores.insert(r.by);
            a.unkAssumed = !o.strictSmc && !a.unkStores.empty();
            if (a.unkAssumed && !cswWhy.empty()) {     // the assumption covers code and widths only
                std::string j;
                for (auto &r : lastWhy) j += (j.empty() ? "" : "; ") + r;
                a.notes.push_back("unknown-target stores still count for return frames, CSW and inline helpers: COUT $FDED is not trusted (" + (j.empty() ? cswWhy : j) + ")");
            }
            out = std::move(a);
            return true;
        }
    }
    out.notes.push_back("table truncation did not converge");
    return true;
}


// A `noreturn` hint is a user claim, never proof. Rerun the whole analysis with every hinted call
// taken as an ordinary returning call (decode past it, callee summaries and must-stores recomputed;
// platform ROM no-return entries are not hints and stay as they are) and tag each "runs as" result
// that the hint changed.
bool analyze(const Image &img, const Hints &h, const AnalyzeOptions &o, Decoder &dec, Analysis &out) {
    bool ok = analyzeCore(img, h, o, dec, out);
    if (!ok || h.noreturn.empty()) return ok;
    Hints h2 = h; h2.noreturn.clear();
    Analysis alt;
    bool altOk = analyzeCore(img, h2, o, dec, alt);
    static const std::string tag = " (per noreturn hint)", smc = " (self-modifying code)";
    auto plain = [&](std::string t) { if (auto p = t.find(tag); p != std::string::npos) t.erase(p, tag.size()); return t; };
    for (auto &[a, note] : out.patchNote) {
        if (note.find("runs as") == std::string::npos || note.find(tag) != std::string::npos) continue;
        auto it = alt.patchNote.find(a);
        if (altOk && it != alt.patchNote.end() && plain(it->second) == note) continue;
        if (auto p = note.rfind(smc); p != std::string::npos) note.insert(p, tag); else note += tag;
    }
    return ok;
}

}  // namespace da
