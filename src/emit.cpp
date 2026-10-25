// ca65 listing writer.  Every byte of the image is emitted exactly once, either
// as an instruction whose encoding ca65 reproduces exactly, or as data.
#include "emit.h"
#include "version.h"
#include <capstone/mos65xx.h>
#include <cstdarg>
#include <cstdio>
#include <set>
#include <sstream>

namespace da {

namespace {
std::string fmt(const char *f, ...) __attribute__((format(printf, 1, 2)));
std::string fmt(const char *f, ...) {
    char b[512];
    va_list ap;
    va_start(ap, f);
    vsnprintf(b, sizeof b, f, ap);
    va_end(ap);
    return b;
}

struct Ctx {
    const Image &img;
    const Hints &h;
    const Analysis &an;
    std::map<uint32_t, std::string> names;
    std::set<uint32_t> definedInline;
};

std::string labelName(const Ctx &c, uint32_t a, int kind) {
    auto n = c.h.names.find(a);
    if (n != c.h.names.end()) return n->second;
    if (kind & LK_JTE) return fmt("jt_%06X", a);
    if (kind & LK_PARAM) return fmt("params_%06X", a);
    if (kind & LK_ENTRY) return fmt("entry_%06X", a);
    if (kind & LK_SUB) return fmt("sub_%06X", a);
    if (kind & LK_CODE) return fmt("L%06X", a);
    return fmt("D%06X", a);
}

const std::string *nameAt(const Ctx &c, uint32_t a) {
    auto it = c.names.find(a);
    return it == c.names.end() ? nullptr : &it->second;
}

// Branch-style target: returns operand text or "" when ca65 cannot express it.
std::string relOperand(const Ctx &c, uint32_t pc, uint32_t next, int32_t d, int32_t lo, int32_t hi) {
    int64_t lin = (int64_t)(next & 0xFFFF) + d;      // linear target within bank
    if (lin < 0 || lin > 0xFFFF) return "";          // wraps inside the bank
    if ((next & 0xFF0000) != (pc & 0xFF0000)) return "";   // ends at the bank end: the assembler's PC runs on into the next bank
    if (d < lo || d > hi) return "";
    uint32_t t = (pc & 0xFF0000) | (uint32_t)lin;
    if (auto n = nameAt(c, t)) return *n;
    return fmt("$%06X", t);
}

std::string formatInsn(const Ctx &c, const Insn &in) {
    const uint8_t *b = in.b;
    uint8_t op = b[0];
    uint32_t v8 = b[1], v16 = b[1] | (b[2] << 8), v24 = v16 | (b[3] << 16);
    uint32_t K = in.addr & 0xFF0000, next = in.addr + in.len;
    std::string mn = in.mnemonic;
    std::string imm = in.len == 3 ? fmt("#$%04X", v16) : fmt("#$%02X", v8);
    switch (op) {
    case 0x00: case 0x42: return "";                                    // BRK/WDM as data
    case 0x02: return fmt("cop $%02X", v8);
    case 0x10: case 0x30: case 0x50: case 0x70: case 0x90: case 0xB0: case 0xD0: case 0xF0: case 0x80: {
        std::string t = relOperand(c, in.addr, next, (int8_t)b[1], -128, 127);
        return t.empty() ? "" : mn + " " + t;
    }
    case 0x82: case 0x62: {
        std::string t = relOperand(c, in.addr, next, (int16_t)v16, -32768, 32767);
        return t.empty() ? "" : mn + " " + t;
    }
    case 0x20: case 0x4C: {
        uint32_t t = K | v16;
        if (auto n = nameAt(c, t)) return mn + " .loword(" + *n + ")";
        return mn + fmt(" $%04X", v16);
    }
    case 0x22: case 0x5C: {
        if (auto n = nameAt(c, v24)) return mn + " " + *n;
        return mn + fmt(" f:$%06X", v24);
    }
    case 0x44: case 0x54: return mn + fmt(" #$%02X,#$%02X", b[2], b[1]);  // MVP/MVN src,dst
    case 0xDC: return fmt("jml [$%04X]", v16);
    case 0xF4: return fmt("pea $%04X", v16);
    default: break;
    }
    switch (in.am) {
    case MOS65XX_AM_IMP: return mn;
    case MOS65XX_AM_ACC: return mn + " a";
    case MOS65XX_AM_IMM: return mn + " " + imm;
    case MOS65XX_AM_ZP: return mn + fmt(" z:$%02X", v8);
    case MOS65XX_AM_ZP_REL: {                                          // 65C02 BBRn/BBSn zp,rel
        std::string t = relOperand(c, in.addr, next, (int8_t)b[2], -128, 127);
        return t.empty() ? "" : mn + fmt(" $%02X,", v8) + t;
    }
    case MOS65XX_AM_ZP_X: return mn + fmt(" z:$%02X,x", v8);
    case MOS65XX_AM_ZP_Y: return mn + fmt(" z:$%02X,y", v8);
    case MOS65XX_AM_ZP_IND: return mn + fmt(" ($%02X)", v8);
    case MOS65XX_AM_ZP_X_IND: return mn + fmt(" ($%02X,x)", v8);
    case MOS65XX_AM_ZP_IND_Y: return mn + fmt(" ($%02X),y", v8);
    case MOS65XX_AM_ZP_IND_LONG: return mn + fmt(" [$%02X]", v8);
    case MOS65XX_AM_ZP_IND_LONG_Y: return mn + fmt(" [$%02X],y", v8);
    case MOS65XX_AM_SR: return mn + fmt(" $%02X,s", v8);
    case MOS65XX_AM_SR_IND_Y: return mn + fmt(" ($%02X,s),y", v8);
    case MOS65XX_AM_ABS: return mn + fmt(" a:$%04X", v16);
    case MOS65XX_AM_ABS_X: return mn + fmt(" a:$%04X,x", v16);
    case MOS65XX_AM_ABS_Y: return mn + fmt(" a:$%04X,y", v16);
    case MOS65XX_AM_ABS_IND: return mn + fmt(" ($%04X)", v16);
    case MOS65XX_AM_ABS_X_IND: return mn + fmt(" ($%04X,x)", v16);
    case MOS65XX_AM_ABS_LONG: return mn + fmt(" f:$%06X", v24);
    case MOS65XX_AM_ABS_LONG_X: return mn + fmt(" f:$%06X,x", v24);
    default: return "";
    }
}

std::string bytesComment(uint32_t a, const uint8_t *p, size_t n) {
    std::string s = fmt("; %02X/%04X:", a >> 16, a & 0xFFFF);
    for (size_t i = 0; i < n; i++) s += fmt(" %02X", p[i]);
    return s;
}

std::string pad(std::string s, size_t w) { if (s.size() < w) s.append(w - s.size(), ' '); else s += ' '; return s; }

bool hiText(uint8_t b) { return b >= 0xA0 && b <= 0xFE; }
bool loText(uint8_t b) { return b >= 0x20 && b <= 0x7E && b != '"' && b != '\\'; }
bool loPrint(uint8_t b) { return b >= 0x20 && b <= 0x7E; }
} // namespace

bool emitListing(const Image &img, const Hints &h, const Analysis &an, const EmitOptions &o,
                 std::string &asmOut, std::string &cfgOut, std::string &err) {
    Ctx c{img, h, an, {}, {}};
    std::set<std::string> used;
    for (auto &kv : an.labels) {
        std::string n = labelName(c, kv.first, kv.second);
        if (used.count(n)) { err = "duplicate label name '" + n + "'"; return false; }
        used.insert(n);
        c.names[kv.first] = n;
    }
    std::ostringstream os, cfg;
    os << "; dumpapple " DUMPAPPLE_VERSION " listing of " << o.sourceName << "\n";
    os << "; cpu " << cpuName(o.cpu) << ", platform " << o.platform << "\n";
    os << "; rebuild: ca65 --cpu " << ca65Cpu(o.cpu) << " -t none -o " << o.listingBase << ".o " << o.listingBase << ".s\n";
    os << ";          ld65 -C " << o.listingBase << ".cfg -o " << o.listingBase << ".bin " << o.listingBase << ".o\n";
    if (img.omf) os << "; input: OMF v" << img.omfVersion << " load file; output is the relocated loaded image, segments in file order\n";
    for (auto &w : img.warnings) os << "; warning: " << w << "\n";
    if (an.g2AssumeCSW) os << "; assumes CSW hook preserves X/Y (an inline-string helper calls COUT $FDED; nothing in the image stores to CSW $36/$37)\n";
    if (an.unkAssumed) os << "; assumes stores with unknown targets do not modify code\n";
    if (an.g2AssumeD) os << "; assumes decimal mode clear at entry (an inline-string helper adds/subtracts; no cld/sed on the way to its call)\n";
    { std::set<std::string> seen; for (auto &n : an.notes) if (seen.insert(n).second) os << "; note: " << n << "\n"; }
    os << "\n.setcpu \"" << ca65Cpu(o.cpu) << "\"\n";
    cfg << "# ld65 config generated by dumpapple for " << o.sourceName << "\nMEMORY {\n";
    std::ostringstream segcfg;
    int segNo = 0;
    for (size_t si = 0; si < img.segs.size(); si++) {
        const Segment &s = img.segs[si];
        if (s.data.empty()) continue;
        segNo++;
        std::string sn = fmt("SEG%d", segNo);
        cfg << fmt("    M%d: start = $%06X, size = $%X, file = %%O, fill = yes;\n", segNo, s.base, (unsigned)s.data.size());
        segcfg << fmt("    %s: load = M%d, type = rw;\n", sn.c_str(), segNo);
        os << "\n; ------------------------------------------------------------\n";
        if (img.omf)
            os << fmt("; segment %u \"%s\" load \"%s\" kind $%04X org $%X entry +$%X\n", s.segnum, s.name.c_str(), s.loadName.c_str(), s.kind, s.org, s.entry);
        os << fmt("; base $%06X length $%X\n", s.base, (unsigned)s.data.size());
        os << ".segment \"" << sn << "\"\n" << fmt(".org $%06X\n", s.base);
        std::map<uint32_t, const RelocNote *> rel;
        for (auto &r : s.relocs) rel[s.base + r.offset] = &r;
        auto relNote = [&](uint32_t a, uint32_t n) {
            std::string t;
            for (auto it = rel.lower_bound(a > 3 ? a - 3 : 0); it != rel.end() && it->first < a + n; ++it) {
                const RelocNote &r = *it->second;
                if (it->first + r.size <= a) continue;
                int64_t rel = (int64_t)it->first - (int64_t)a;   // negative: field began on the previous line
                t += fmt(" [reloc%s %d@%s%X -> seg %u+$%X%s]", r.inter ? " inter" : "", r.size, rel < 0 ? "-" : "+", (unsigned)(rel < 0 ? -rel : rel), r.targetSeg, r.targetOff, r.resolved ? "" : " UNRESOLVED");
                if (r.shift) t += fmt(" >>%d", -r.shift);
            }
            return t;
        };
        // length of a data line starting at x (at most maxn, at most avail bytes)
        // shortened so that no relocated field is split across two lines
        auto chunk = [&](uint32_t x, uint32_t maxn, uint32_t avail) -> uint32_t {
            uint32_t n = std::min(maxn, avail);
            if (n == avail) return n;
            for (auto it = rel.lower_bound(x + 1); it != rel.end() && it->first < x + n; ++it)
                if (it->first + it->second->size > x + n) return it->first - x;
            return n;
        };
        int curA = -1, curI = -1;
        uint32_t end = s.base + (uint32_t)s.data.size();
        uint32_t a = s.base;
        const uint8_t *d = s.data.data();
        auto byteAt = [&](uint32_t x) { return d[x - s.base]; };
        // boundaries where a data run must stop
        auto nextBoundary = [&](uint32_t from) {
            uint32_t lim = end;
            auto ci = an.code.upper_bound(from);
            if (ci != an.code.end() && ci->first < lim) lim = ci->first;
            auto li = c.names.upper_bound(from);
            if (li != c.names.end() && li->first < lim) lim = li->first;
            auto mi = h.comments.upper_bound(from);
            if (mi != h.comments.end() && mi->first < lim) lim = mi->first;
            auto ii = an.inlineData.upper_bound(from);
            if (ii != an.inlineData.end() && ii->first < lim) lim = ii->first;
            for (auto &t : an.tables) {
                if (t.addr > from && t.addr < lim) lim = t.addr;
                if (t.addr <= from && from < t.end() && t.end() < lim) lim = t.end();
                if (t.kind == TK_SPLIT) {
                    uint32_t he = t.hiAddr + t.count;
                    if (t.hiAddr > from && t.hiAddr < lim) lim = t.hiAddr;
                    if (t.hiAddr <= from && from < he && he < lim) lim = he;
                }
            }
            auto bi = an.bad.upper_bound(from);
            if (bi != an.bad.end() && bi->first < lim) lim = bi->first;
            auto wi = h.wordRanges.upper_bound(from);
            if (wi != h.wordRanges.end() && wi->first < lim) lim = wi->first;
            for (auto w = h.wordRanges.begin(); w != h.wordRanges.end(); ++w)
                if (w->first <= from && (uint64_t)w->first + w->second > from && w->first + w->second < lim) lim = w->first + w->second;
            return lim;
        };
        while (a < end) {
            auto cm = h.comments.find(a);
            if (cm != h.comments.end()) for (auto &t : cm->second) os << "; " << t << "\n";
            if (auto n = nameAt(c, a)) { os << *n << ":\n"; c.definedInline.insert(a); }
            auto ib = an.inlineData.find(a);
            if (ib != an.inlineData.end() && a + ib->second.len <= end) {
                const uint8_t *p = d + (a - s.base);
                uint32_t n = ib->second.len;
                os << "; " << ib->second.why << "\n";
                if (ib->second.kind == 1 && n == 6) {
                    os << pad(fmt("    .word $%04X", p[0] | (p[1] << 8)), 32) << fmt("; %02X/%04X GS/OS call number", a >> 16, a & 0xFFFF) << relNote(a, 2) << "\n";
                    uint32_t pv = (uint32_t)(p[2] | (p[3] << 8) | (p[4] << 16) | ((uint32_t)p[5] << 24));
                    const std::string *pn = nameAt(c, pv);
                    os << pad(pn ? "    .dword " + *pn : fmt("    .dword $%08X", pv), 32) << fmt("; %02X/%04X parameter block", (a + 2) >> 16, (a + 2) & 0xFFFF) << relNote(a + 2, 4) << "\n";
                } else if (ib->second.kind == 3 && n == 14) {
                    auto w16 = [&](int i) { return (unsigned)(p[i] | (p[i + 1] << 8)); };
                    const std::string *tn = ib->second.target ? nameAt(c, ib->second.target) : nullptr;
                    std::string tl = tn ? " -> " + *tn : ib->second.target ? fmt(" -> $%06X", ib->second.target) : std::string();
                    os << pad(fmt("    .word $%04X", w16(0)), 32) << fmt("; %02X/%04X user ID", a >> 16, a & 0xFFFF) << relNote(a, 2) << "\n";
                    os << pad(fmt("    .word $%04X", w16(2)), 32) << fmt("; %02X/%04X load-file number", (a + 2) >> 16, (a + 2) & 0xFFFF) << relNote(a + 2, 2) << "\n";
                    os << pad(fmt("    .word $%04X", w16(4)), 32) << fmt("; %02X/%04X load-segment number", (a + 4) >> 16, (a + 4) & 0xFFFF) << relNote(a + 4, 2) << "\n";
                    os << pad(fmt("    .dword $%08X", w16(6) | (w16(8) << 16)), 32) << fmt("; %02X/%04X segment offset", (a + 6) >> 16, (a + 6) & 0xFFFF) << tl << relNote(a + 6, 4) << "\n";
                    os << pad(fmt("    .byte $%02X,$%02X,$%02X,$%02X", p[10], p[11], p[12], p[13]), 32) << fmt("; %02X/%04X JSL to loader (data, unpatched)", (a + 10) >> 16, (a + 10) & 0xFFFF) << relNote(a + 10, 4) << "\n";
                } else if (ib->second.kind == 2 && n == 3) {
                    os << pad(fmt("    .byte $%02X", p[0]), 32) << fmt("; %02X/%04X MLI command", a >> 16, a & 0xFFFF) << "\n";
                    const std::string *pn = nameAt(c, (a & 0xFF0000) | (uint32_t)(p[1] | (p[2] << 8)));
                    os << pad(pn ? "    .word .loword(" + *pn + ")" : fmt("    .word $%04X", p[1] | (p[2] << 8)), 32) << fmt("; %02X/%04X parameter list", (a + 1) >> 16, (a + 1) & 0xFFFF) << relNote(a + 1, 2) << "\n";
                } else if (ib->second.kind >= 4) {           // terminated string: 16 bytes a line, text in the comment
                    for (uint32_t k = 0, m = 0; k < n; k += m) {
                        m = chunk(a + k, 16, n - k);
                        std::string line = "    .byte ", txt;
                        for (uint32_t q = 0; q < m; q++) {
                            uint8_t ch = p[k + q] & 0x7F;
                            line += fmt("%s$%02X", q ? "," : "", p[k + q]);
                            txt += (ch >= 0x20 && ch < 0x7F) ? (char)ch : '.';
                        }
                        os << pad(line, 32) << fmt("; %02X/%04X \"", (a + k) >> 16, (a + k) & 0xFFFF) << txt << "\"" << relNote(a + k, m) << "\n";
                    }
                } else {
                    std::string line = "    .byte ";
                    for (uint32_t k = 0; k < n; k++) line += fmt("%s$%02X", k ? "," : "", p[k]);
                    os << pad(line, 32) << fmt("; %02X/%04X inline", a >> 16, a & 0xFFFF) << relNote(a, n) << "\n";
                }
                a += n;
                continue;
            }
            const JumpTable *jt = nullptr;
            for (auto &t : an.tables) if (t.addr <= a && a < t.end()) { jt = &t; break; }
            const JumpTable *jh = nullptr;      // the high-byte half of a split table
            for (auto &t : an.tables) if (t.kind == TK_SPLIT && t.hiAddr <= a && a < t.hiAddr + t.count) { jh = &t; break; }
            auto imgByte = [&](uint32_t x) -> int {
                for (auto &sg : img.segs) if (x >= sg.base && x - sg.base < sg.data.size()) return sg.data[x - sg.base];
                return -1;
            };
            if (jh || (jt && jt->kind == TK_SPLIT)) {
                const JumpTable *t = jh ? jh : jt;
                bool high = jh != nullptr;
                uint32_t i = a - (high ? t->hiAddr : t->addr);
                uint32_t base = high ? t->hiAddr : t->addr;
                if (i == 0)
                    os << fmt("; jump table (%s): %u split rts (addr-1) entries, %s bytes; %s bytes at $%06X", t->hinted ? "hint" : "auto", t->count,
                              high ? "high" : "low", high ? "low" : "high", high ? t->addr : t->hiAddr)
                       << (t->user ? fmt(", used by $%06X", t->user) : std::string()) << (t->hinted ? std::string() : ", heuristic stopped: " + t->why) << "\n";
                (void)base;
                int lo = imgByte(t->addr + i), hi = imgByte(t->hiAddr + i);
                uint32_t tg = t->bank | (((uint32_t)(lo | (hi << 8)) + 1) & 0xFFFF);
                const std::string *tn = nameAt(c, tg);
                std::string txt = tn ? fmt(".byte %s(", high ? ">" : "<") + *tn + "-1)" : fmt(".byte $%02X", high ? hi : lo);
                os << pad("    " + txt, 32) << fmt("; %02X/%04X", a >> 16, a & 0xFFFF) << fmt(" -> $%06X", tg) << relNote(a, 1) << "\n";
                a += 1;
                continue;
            }
            if (jt && (a - jt->addr) % jt->entrySize() == 0 && a + jt->entrySize() <= end) {
                if (a == jt->addr) {
                    os << fmt("; jump table (%s): %u %s entr%s", jt->hinted ? "hint" : "auto", jt->count,
                              jt->kind == TK_LONG ? "long" : jt->kind == TK_RTS ? "rts (addr-1)" : jt->kind == TK_RTSLONG ? "rtl long (addr-1)" : "word", jt->count == 1 ? "y" : "ies");
                    if (jt->user) os << fmt(", used by $%06X", jt->user);
                    if (!jt->hinted) os << ", heuristic stopped: " << jt->why;
                    os << "\n";
                }
                const uint8_t *p = d + (a - s.base);
                uint32_t tg = tableTarget(*jt, p);
                const std::string *tn = nameAt(c, tg);
                std::string txt;
                if (jt->kind == TK_LONG) txt = tn ? ".faraddr " + *tn : fmt(".faraddr $%06X", tg);
                else if (jt->kind == TK_RTSLONG) txt = tn && (tg & 0xFFFF) ? ".faraddr " + *tn + "-1" : fmt(".faraddr $%06X", (unsigned)(p[0] | (p[1] << 8) | (p[2] << 16)));
                else if (tn && (tg & 0xFF0000) == jt->bank) txt = jt->kind == TK_RTS ? ".word .loword(" + *tn + "-1)" : ".word .loword(" + *tn + ")";
                else txt = fmt(".word $%04X", p[0] | (p[1] << 8));
                os << pad("    " + txt, 32) << fmt("; %02X/%04X", a >> 16, a & 0xFFFF) << fmt(" -> $%06X", tg) << relNote(a, jt->entrySize()) << "\n";
                a += jt->entrySize();
                continue;
            }
            auto ci = an.code.find(a);
            if (ci != an.code.end() && (a & 0xFFFF) + ci->second.in.len > 0x10000 && a + (0x10000 - (a & 0xFFFF)) <= end) {
                // operand bytes past the bank end come from the start of the same bank: only the
                // in-bank bytes sit here; emitted as data, the decoded form as a comment
                const CodeInsn &ki = ci->second;
                uint32_t nIn = 0x10000 - (a & 0xFFFF);
                std::string bs = ".byte ";
                for (uint32_t i = 0; i < nIn; i++) bs += fmt("%s$%02X", i ? "," : "", ki.in.b[i]);
                std::string t = formatInsn(c, ki.in);
                std::string com = bytesComment(a, ki.in.b, ki.in.len) + " " + (t.empty() ? ki.in.mnemonic : t) + fmt(" (operand wraps to $%02X/0000)", a >> 16);
                os << pad("    " + bs, 32) << com << "\n";
                a += nIn;
                continue;
            }
            if (ci != an.code.end() && a + ci->second.in.len <= end) {
                const CodeInsn &ki = ci->second;
                std::string txt = formatInsn(c, ki.in);
                std::string com = bytesComment(a, ki.in.b, ki.in.len) + relNote(a, ki.in.len);
                if (txt.empty()) {
                    std::string bs = ".byte ";
                    for (int i = 0; i < ki.in.len; i++) bs += fmt("%s$%02X", i ? "," : "", ki.in.b[i]);
                    txt = bs;
                    com += " " + ki.in.mnemonic;
                    if (ki.in.b[0] == 0x00 || ki.in.b[0] == 0x42) com += fmt(" $%02X", ki.in.b[1]);
                    else com += " (target not expressible)";
                }
                auto dp = an.dispatch.find(a);
                if (dp != an.dispatch.end()) com += " ; " + dp->second;
                if (auto pn = an.patchNote.find(a); pn != an.patchNote.end()) com += " ; " + pn->second;
                if (an.unkAssumed && an.unkStores.count(a)) com += " ; unknown-target store (assumed not to modify code)";
                if (o.cpu == Cpu::C65816 && ki.st.m >= 0 && ki.st.m != curA) { os << (ki.st.m ? "    .a8\n" : "    .a16\n"); curA = ki.st.m; }
                if (o.cpu == Cpu::C65816 && ki.st.x >= 0 && ki.st.x != curI) { os << (ki.st.x ? "    .i8\n" : "    .i16\n"); curI = ki.st.x; }
                os << pad("    " + txt, 32) << com << "\n";
                a += ki.in.len;
                continue;
            }
            auto bd = an.bad.find(a);
            if (bd != an.bad.end()) os << "; code flow reached here but decoding stopped: " << bd->second << "\n";
            uint32_t lim = nextBoundary(a);
            // word data
            bool inWord = false;
            for (auto &w : h.wordRanges) if (w.first <= a && (uint64_t)w.first + w.second > a) inWord = true;
            if (inWord) {
                while (a + 1 < lim) {
                    std::string line = "    .word ";
                    uint32_t st = a;
                    for (int k = 0; k < 8 && a + 1 < lim; k++, a += 2)
                        line += fmt("%s$%04X", k ? "," : "", byteAt(a) | (byteAt(a + 1) << 8));
                    os << pad(line, 32) << fmt("; %02X/%04X", st >> 16, st & 0xFFFF) << relNote(st, a - st) << "\n";
                }
                if (a < lim) { os << pad(fmt("    .byte $%02X", byteAt(a)), 32) << fmt("; %02X/%04X", a >> 16, a & 0xFFFF) << "\n"; a++; }
                continue;
            }
            std::vector<uint8_t> plain;
            uint32_t plainStart = a;
            auto flush = [&]() {
                for (size_t i = 0, n = 0; i < plain.size(); i += n) {
                    std::string line = "    .byte ";
                    n = chunk(plainStart + (uint32_t)i, 16, (uint32_t)(plain.size() - i));
                    for (size_t k = 0; k < n; k++) line += fmt("%s$%02X", k ? "," : "", plain[i + k]);
                    uint32_t la = plainStart + (uint32_t)i;
                    os << pad(line, 32) << fmt("; %02X/%04X", la >> 16, la & 0xFFFF) << relNote(la, (uint32_t)n) << "\n";
                }
                plain.clear();
            };
            // a relocated field is never split: runs may not start or end strictly inside one
            auto midRel = [&](uint32_t x) {
                auto it = rel.lower_bound(x >= 4 ? x - 4 : 0);
                for (; it != rel.end() && it->first < x; ++it) if (it->first + it->second->size > x) return true;
                return false;
            };
            auto trim = [&](uint32_t st, uint32_t j) { while (j > st && midRel(j)) j--; return j; };
            while (a < lim) {
                if (midRel(a)) { if (plain.empty()) plainStart = a; plain.push_back(byteAt(a)); a++; continue; }
                uint32_t j = a;
                while (j < lim && byteAt(j) == 0) j++;
                j = trim(a, j);
                if (j - a >= 16) {
                    flush();
                    os << pad(fmt("    .res %u", j - a), 32) << fmt("; %02X/%04X", a >> 16, a & 0xFFFF) << relNote(a, j - a) << "\n";
                    a = j; plainStart = a; continue;
                }
                j = a;
                while (j < lim && hiText(byteAt(j))) j++;
                if (j < lim && j - a >= 4 && loPrint(byteAt(j))) j++;   // final byte with bit 7 clear
                j = trim(a, j);
                if (j - a >= 4) {
                    flush();
                    for (uint32_t k = a, n = 0; k < j; k += n) {
                        n = chunk(k, 16, j - k);
                        std::string line = "    .byte ", txt;
                        for (uint32_t q = 0; q < n; q++) {
                            uint8_t ch = byteAt(k + q);
                            line += fmt("%s$%02X", q ? "," : "", ch);
                            txt += (char)(ch & 0x7F);
                        }
                        os << pad(line, 32) << fmt("; %02X/%04X", k >> 16, k & 0xFFFF) << " hi-ascii \"" << txt << "\"" << relNote(k, n) << "\n";
                    }
                    a = j; plainStart = a; continue;
                }
                j = a;
                while (j < lim && loText(byteAt(j))) j++;
                j = trim(a, j);
                if (j - a >= 4) {
                    flush();
                    for (uint32_t k = a, n = 0; k < j; k += n) {
                        n = chunk(k, 48, j - k);
                        std::string txt(reinterpret_cast<const char *>(d + (k - s.base)), n);
                        os << pad("    .byte \"" + txt + "\"", 32) << fmt("; %02X/%04X", k >> 16, k & 0xFFFF) << relNote(k, n) << "\n";
                    }
                    a = j; plainStart = a; continue;
                }
                if (plain.empty()) plainStart = a;
                plain.push_back(byteAt(a));
                a++;
            }
            flush();
        }
    }
    cfg << "}\nSEGMENTS {\n" << segcfg.str() << "}\n";
    bool hdr = false;
    for (auto &kv : c.names) {
        if (c.definedInline.count(kv.first)) continue;
        if (!hdr) { os << "\n; labels that do not start a listing line\n"; hdr = true; }
        os << kv.second << fmt(" = $%06X\n", kv.first);
    }
    asmOut = os.str();
    cfgOut = cfg.str();
    return true;
}

}
