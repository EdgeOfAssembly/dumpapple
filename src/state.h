#pragma once
#include <cstdint>
#include <string>

namespace da {
// Processor width state.  Each flag: 1 = set (8-bit / emulation / carry set),
// 0 = clear, -1 = unknown.
struct State {
    int8_t m = 1, x = 1, e = 1, c = -1;
    // zero, negative and overflow flags (1 set, 0 clear, -1 unknown): only for branch decisions
    int8_t z = -1, n = -1, v = -1;
    // decimal flag: 0 = clear (cld/rep), 1 = set, -1 = unknown, 2 = clear only by the
    // assumption that it is clear at the entry point (no sed/plp seen on the way)
    int8_t d = 2;
    // PHP/PLP shadow stack of (m,x) pairs; depth -1 = unknown contents.
    int8_t depth = 0;
    int8_t sm[4] = {0, 0, 0, 0}, sx[4] = {0, 0, 0, 0}, sd[4] = {0, 0, 0, 0};
    bool operator==(const State &o) const {
        if (m != o.m || x != o.x || e != o.e || c != o.c || z != o.z || n != o.n || v != o.v || d != o.d || depth != o.depth) return false;
        for (int i = 0; i < depth; i++) if (sm[i] != o.sm[i] || sx[i] != o.sx[i] || sd[i] != o.sd[i]) return false;
        return true;
    }
    bool operator!=(const State &o) const { return !(*this == o); }
    void normalize() {
        if (e == 1) { m = 1; x = 1; }
        if (depth < 0) depth = -1;
        for (int i = (depth > 0 ? depth : 0); i < 4; i++) sm[i] = sx[i] = sd[i] = 0;
    }
    static int8_t mergeFlag(int8_t a, int8_t b) { return a == b ? a : -1; }
    static int8_t mergeD(int8_t a, int8_t b) { return a == b ? a : ((a == 0 || a == 2) && (b == 0 || b == 2)) ? 2 : -1; }
    static State merge(const State &a, const State &b) {
        State r;
        r.m = mergeFlag(a.m, b.m); r.x = mergeFlag(a.x, b.x);
        r.e = mergeFlag(a.e, b.e); r.c = mergeFlag(a.c, b.c); r.z = mergeFlag(a.z, b.z); r.n = mergeFlag(a.n, b.n); r.v = mergeFlag(a.v, b.v); r.d = mergeD(a.d, b.d);
        if (a.depth == b.depth && a.depth >= 0) {
            r.depth = a.depth;
            for (int i = 0; i < a.depth; i++) { r.sm[i] = mergeFlag(a.sm[i], b.sm[i]); r.sx[i] = mergeFlag(a.sx[i], b.sx[i]); r.sd[i] = mergeD(a.sd[i], b.sd[i]); }
        } else r.depth = -1;
        r.normalize();
        return r;
    }
    std::string str() const {
        auto f = [](int8_t v, const char *one, const char *zero) { return std::string(v < 0 ? "?" : v ? one : zero); };
        if (e == 1) return "e";
        return (e < 0 ? std::string("e?") : std::string("")) + "m" + f(m, "8", "16") + "x" + f(x, "8", "16");
    }
};
// Parse "e", "m8x8", "m16x16", "m8x16", "m16x8" (also "native" == m8x8 native).
bool parseState(const std::string &s, State &out);
}
