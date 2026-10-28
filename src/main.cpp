#include <set>
#include <functional>
// dumpapple - game-agnostic Apple II / IIgs (6502, 65C02, 65816) disassembler producing
// ca65 listings that rebuild byte-identical.
#include "analyze.h"
#include "emit.h"
#include "omf.h"
#include <cstdio>
#include <cstdlib>
#include <cctype>
#ifndef DUMPAPPLE_HINTS_DIR
#define DUMPAPPLE_HINTS_DIR "/usr/local/share/dumpapple/hints"
#endif
#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <sstream>
#include <unistd.h>

#include "version.h"

using namespace da;

static void usage(FILE *f) {
    fprintf(f,
"dumpapple " DUMPAPPLE_VERSION " - Apple II / IIgs (6502, 65C02, 65816) disassembler\n"
"(ca65 output, byte-identical rebuild)\n"
"\n"
"usage: dumpapple [options] FILE\n"
"       dumpapple [-h | --version]     (no arguments: this help, exit 0)\n"
"\n"
"input:\n"
"  --omf               force OMF v1/v2 load file (default: autodetect)\n"
"  --raw               force raw binary\n"
"  --org ADDR          raw: load address (default $2000)\n"
"  --base ADDR         OMF: base of first relocatable segment (default $020000)\n"
"  --stride N          OMF: alignment between segment bases (default $10000)\n"
"  --cpu CPU           6502 | 65c02 | 65816 (default: OMF 65816; raw: auto)\n"
"                      raw auto: 65816 when 65816-only instructions run on flow\n"
"                      from the entry, else 65c02: >=1 of brl/jsl/jml/rtl/rep/\n"
"                      sep/clc;xce or >=3 others such as pea/phd/xba, each\n"
"                      where a 65C02 decode of the same flow also starts an\n"
"                      instruction;\n"
"                      after a weak first hit a key counts only if the 65816\n"
"                      reading runs on as code (no text, brk/cop/wdm; immediates\n"
"                      sized by m/x tracked through rep/sep; rep widens only in\n"
"                      native mode; E/carry tracked, both start unknown, E starts\n"
"                      emulation with --platform prodos8; after xce of unknown\n"
"                      mode or plp outside emulation either size may pass; past 4\n"
"                      such immediates on one path 65816 code may be missed);\n"
"                      at a $xF long op (BBR/BBS on a 65C02) a key within 8\n"
"                      instructions counts only if the 65C02 reading breaks\n"
"                      within 8\n"
"                      65c02 (aliases w65c02, r65c02) = WDC W65C02S:\n"
"                      RMB/SMB/BBR/BBS + WAI/STP (only early non-Rockwell\n"
"                      65C02s, e.g. enhanced IIe/IIc, run $x7/$xF as NOPs)\n"
"                      65816 (aliases 65c816, w65c816); CPU names are\n"
"                      case-insensitive\n"
"  --platform P        none | prodos8 | gsos  (default: OMF gsos, raw none)\n"
"                      gsos: JSL $E100A8 is followed by 6 inline bytes; prodos8:\n"
"                      JSR $BF00 (MLI) by 3\n"
"analysis:\n"
"  --entry ADDR[:S]    add a code entry point, optionally with its own width\n"
"                      state (repeatable; SEG:OFF[:S] allowed for OMF)\n"
"  --no-tables         do not follow jump tables / push+RTS dispatch\n"
"  --no-auto-inline    do not detect routines that read a terminated string\n"
"                      after the call\n"
"  --no-imm-pointers   do not treat lda #<x / ldx #>x pairs as code pointers\n"
"  --no-seed-targets   do not seed in-image jsr/jmp targets when flow leaves\n"
"                      the image (default: seeded, each noted; off under\n"
"                      --strict-smc unless --seed-targets)\n"
"  --no-auto-region    raw: do not turn a recognized copy-then-jump (monitor\n"
"                      MOVE, page copy) into a region (default: auto; off\n"
"                      under --strict-smc unless --auto-region)\n"
"  --strict-smc        stores with unknown targets may modify code (stop\n"
"                      decoding there; the entry run before the first store\n"
"                      stays code; CPU auto-detect ignores it)\n"
"  --state S           entry width state: e | m8x8 | m8x16 | m16x8 | m16x16\n"
"                      (default: raw e, OMF m16x16)\n"
"  --no-org-entry      raw: do not treat --org as an entry point\n"
"  --seg-entries       OMF: also seed the ENTRY of every other static code\n"
"                      segment (default: only the first static code segment,\n"
"                      as the GS/OS loader does; data, jump-table, DP/stack\n"
"                      and dynamic segments never seed code)\n"
"  --no-seg-entries    OMF: seed only the first static code segment's ENTRY\n"
"                      (default; cancels --seg-entries)\n"
"  --hints-lib NAME    also read the shipped hint file NAME.hints (e.g. davex);\n"
"                      never automatic\n"
"  --hints FILE        hints file, also holds name directives (repeatable;\n                      see dumpapple(1))\n"
"output:\n"
"  -o FILE             write listing; if FILE ends in .s the ld65 config goes to\n"
"                      FILE minus .s plus .cfg (default: listing on stdout)\n"
"  --cfg FILE          write the ld65 config here instead\n"
"  --dump-image FILE   write the loaded (relocated) image bytes\n"
"  --verify            rebuild with ca65+ld65 and compare byte-for-byte\n"
"                      (exit 3 if the rebuild fails or differs)\n"
"  --ca65 PATH, --ld65 PATH   assembler/linker to use (default from PATH)\n"
"  -q                  quiet\n"
"  -h, --help          this help;  --version  print version\n"
"\n"
"ADDR accepts $hex, 0xhex or bare hex.\n");
}

static bool readFile(const std::string &p, std::vector<uint8_t> &v) {
    std::ifstream in(p, std::ios::binary);
    if (!in) return false;
    v.assign(std::istreambuf_iterator<char>(in), {});
    return true;
}
static bool writeFile(const std::string &p, const std::string &s) {
    std::ofstream o(p, std::ios::binary);
    o << s;
    return (bool)o;
}
static std::string shq(const std::string &s) {
    std::string r = "'";
    for (char c : s) { if (c == '\'') r += "'\\''"; else r += c; }
    return r + "'";
}

int main(int argc, char **argv) {
    if (argc < 2) { usage(stdout); return 0; }
    std::vector<std::string> hintsPaths;
    std::string in, out, cfgPath, dumpImage, ca65 = "ca65", ld65 = "ld65";
    bool forceOmf = false, forceRaw = false, verify = false, quiet = false, segEntries = false, haveState = false, defaultEntry = true, haveCpu = false, followTables = true;
    bool autoInline = true, immPointers = true, strictSmc = false, seedTargets = true, autoRegion = true;
    int seedSet = -1, regionSet = -1;      // explicit --[no-]seed-targets / --[no-]auto-region (-1: default)
    Cpu cpu = Cpu::C65816;
    std::string platformArg;
    uint32_t org = 0x2000;
    OmfOptions oo;
    std::vector<std::string> entryArgs;
    State entry;
    for (int i = 1; i < argc; i++) {
        std::string a = argv[i];
        auto need = [&](const char *what) -> std::string {
            if (i + 1 >= argc) { fprintf(stderr, "dumpapple: %s needs an argument\n", what); exit(2); }
            return argv[++i];
        };
        auto num = [&](const char *what) -> uint32_t {
            std::string s = need(what);
            uint32_t v;
            if (!parseNumber(s, v) || v > 0xFFFFFF) { fprintf(stderr, "dumpapple: bad number for %s: %s\n", what, s.c_str()); exit(2); }
            return v;
        };
        if (a == "-h" || a == "--help") { usage(stdout); return 0; }
        else if (a == "--version") { printf("dumpapple " DUMPAPPLE_VERSION "\n"); return 0; }
        else if (a == "--omf") forceOmf = true;
        else if (a == "--raw") forceRaw = true;
        else if (a == "--org") org = num("--org");
        else if (a == "--base") oo.base = num("--base");
        else if (a == "--stride") { oo.stride = num("--stride"); if (!oo.stride) oo.stride = 1; }
        else if (a == "--entry") entryArgs.push_back(need("--entry"));
        else if (a == "--state") { std::string s = need("--state"); if (!parseState(s, entry)) { fprintf(stderr, "dumpapple: bad state %s\n", s.c_str()); return 2; } haveState = true; }
        else if (a == "--no-seg-entries") segEntries = false;
        else if (a == "--seg-entries") segEntries = true;
        else if (a == "--no-org-entry") defaultEntry = false;
        else if (a == "--no-auto-inline") autoInline = false;
        else if (a == "--no-imm-pointers") immPointers = false;
        else if (a == "--strict-smc") strictSmc = true;
        else if (a == "--no-seed-targets") seedSet = 0;
        else if (a == "--seed-targets") seedSet = 1;
        else if (a == "--no-auto-region") regionSet = 0;
        else if (a == "--auto-region") regionSet = 1;
        else if (a == "--no-tables") followTables = false;
        else if (a == "--platform") { platformArg = need("--platform"); if (platformArg != "none" && platformArg != "prodos8" && platformArg != "gsos") { fprintf(stderr, "dumpapple: bad --platform %s (none, prodos8, gsos)\n", platformArg.c_str()); return 2; } }
        else if (a == "--cpu") { std::string c = need("--cpu"); if (!parseCpu(c, cpu)) { fprintf(stderr, "dumpapple: bad --cpu %s (6502, 65c02, 65816)\n", c.c_str()); return 2; } haveCpu = true; }
        else if (a == "--hints") hintsPaths.push_back(need("--hints"));
        else if (a == "--hints-lib") {
            // shipped platform hint files: <dir of the binary>/hints, $DUMPAPPLE_HINTS, $(PREFIX)/share/dumpapple/hints
            std::string nm = need("--hints-lib"), found;
            for (char ch : nm) if (!(isalnum((unsigned char)ch) || ch == '_' || ch == '-')) { fprintf(stderr, "dumpapple: bad --hints-lib name %s\n", nm.c_str()); return 2; }
            std::vector<std::string> dirs;
            if (const char *e = getenv("DUMPAPPLE_HINTS")) dirs.push_back(e);
            std::string self = argv[0];
            {   // the real binary's directory, even when run via PATH; argv[0] as fallback
                char buf[4096]; ssize_t n = readlink("/proc/self/exe", buf, sizeof buf - 1);
                if (n > 0) { buf[n] = 0; self = buf; }
            }
            auto sl = self.rfind('/');
            dirs.push_back((sl == std::string::npos ? std::string(".") : self.substr(0, sl)) + "/hints");
            dirs.push_back(DUMPAPPLE_HINTS_DIR);
            for (auto &d : dirs) { std::string f = d + "/" + nm + ".hints"; if (FILE *fp = fopen(f.c_str(), "r")) { fclose(fp); found = f; break; } }
            if (found.empty()) { fprintf(stderr, "dumpapple: --hints-lib %s: no %s.hints in $DUMPAPPLE_HINTS, <bindir>/hints or %s\n", nm.c_str(), nm.c_str(), DUMPAPPLE_HINTS_DIR); return 1; }
            hintsPaths.push_back(found);
        }
        else if (a == "-o") out = need("-o");
        else if (a == "--cfg") cfgPath = need("--cfg");
        else if (a == "--dump-image") dumpImage = need("--dump-image");
        else if (a == "--verify") verify = true;
        else if (a == "--ca65") ca65 = need("--ca65");
        else if (a == "--ld65") ld65 = need("--ld65");
        else if (a == "-q") quiet = true;
        else if (!a.empty() && a[0] == '-') { fprintf(stderr, "dumpapple: unknown option %s\n", a.c_str()); return 2; }
        else if (in.empty()) in = a;
        else { fprintf(stderr, "dumpapple: more than one input file\n"); return 2; }
    }
    if (in.empty()) { usage(stderr); return 2; }
    std::vector<uint8_t> file;
    if (!readFile(in, file)) { fprintf(stderr, "dumpapple: cannot read %s\n", in.c_str()); return 1; }
    std::string err;
    RawHints raw;
    for (auto &hp : hintsPaths)
        if (!readHintsFile(hp, raw, err)) { fprintf(stderr, "dumpapple: %s\n", err.c_str()); return 1; }
    if (!hintsSegBase(raw, oo.segBase, err)) { fprintf(stderr, "dumpapple: %s\n", err.c_str()); return 1; }
    // --strict-smc proves, it does not guess: seeded entries and auto regions (heuristics whose
    // stores would then count against the entry code) are off unless asked for
    seedTargets = seedSet >= 0 ? seedSet == 1 : !strictSmc;
    autoRegion = regionSet >= 0 ? regionSet == 1 : !strictSmc;
    std::vector<Hints::Region> autoRegions; std::vector<std::string> autoNotes; std::set<uint32_t> autoCopyStores; bool autoTried = false;
rebuild:     // a second pass when copy-then-jump regions were recognized (auto region)
    std::vector<Hints::Region> regions;
    if (!hintsRegions(raw, regions, err)) { fprintf(stderr, "dumpapple: %s\n", err.c_str()); return 1; }
    const bool hintRegions = !regions.empty();
    regions.insert(regions.end(), autoRegions.begin(), autoRegions.end());
    Image img;
    bool omf = forceOmf || (!forceRaw && looksLikeOmf(file));
    if (omf) {
        if (!loadOmf(file, oo, img, err)) { fprintf(stderr, "dumpapple: OMF: %s\n", err.c_str()); return 1; }
    } else {
        if (file.empty()) { fprintf(stderr, "dumpapple: empty input\n"); return 1; }
        if ((uint64_t)org + file.size() > 0x1000000) { fprintf(stderr, "dumpapple: image does not fit in 24-bit space at --org\n"); return 1; }
        // `region FILEOFF LEN ADDR` hints split the file: those bytes are listed at the
        // address they run at, everything else at --org + file offset (file order kept)
        std::sort(regions.begin(), regions.end(), [](const Hints::Region &x, const Hints::Region &y) { return x.fileOff < y.fileOff; });
        uint64_t pos = 0;
        for (auto &r : regions) {
            if ((uint64_t)r.fileOff + r.len > file.size() || r.fileOff < pos) { fprintf(stderr, "dumpapple: region %X+%X is outside the file or overlaps another region\n", r.fileOff, r.len); return 1; }
            if ((uint64_t)r.addr + r.len > 0x1000000) { fprintf(stderr, "dumpapple: region at $%06X does not fit in 24-bit space\n", r.addr); return 1; }
            if (r.fileOff > pos) {
                Segment s; s.name = "RAW"; s.base = org + (uint32_t)pos;
                s.data.assign(file.begin() + pos, file.begin() + r.fileOff); img.segs.push_back(std::move(s));
            }
            Segment s; s.name = "REGION"; s.base = r.addr; s.org = r.fileOff;
            s.data.assign(file.begin() + r.fileOff, file.begin() + r.fileOff + r.len); img.segs.push_back(std::move(s));
            pos = (uint64_t)r.fileOff + r.len;
        }
        if (pos < file.size() || regions.empty()) {
            Segment s; s.name = "RAW"; s.base = org + (uint32_t)pos;
            s.data.assign(file.begin() + pos, file.end()); img.segs.push_back(std::move(s));
        }
        for (size_t i = 0; i < img.segs.size(); i++) {
            img.segs[i].segnum = (uint16_t)(i + 1);
            for (size_t j = 0; j < i; j++) {
                auto &x = img.segs[i], &y = img.segs[j];
                if (x.base < y.base + y.data.size() && y.base < x.base + x.data.size()) { fprintf(stderr, "dumpapple: region at $%06X overlaps $%06X-$%06X in the load map\n", x.base, y.base, (unsigned)(y.base + y.data.size() - 1)); return 1; }
            }
        }
    }
    if (omf && !regions.empty()) { fprintf(stderr, "dumpapple: region hints apply to raw input only (use segbase for OMF)\n"); return 1; }
    bool autoCpu = !haveCpu && !omf;   // raw input without --cpu: decided from flow below
    if (!haveCpu) cpu = omf ? Cpu::C65816 : Cpu::C65C02;
    std::string cpuWhy;   // auto choice for raw input, shown in the listing header
    if (cpu != Cpu::C65816 && !autoCpu) {
        for (auto &sg : img.segs)
            if ((uint64_t)sg.base + sg.data.size() > 0x10000) { fprintf(stderr, "dumpapple: --cpu %s image must lie in $0000-$FFFF\n", cpuName(cpu)); return 1; }
    }
    Hints h;
    if (!resolveHints(raw, img, h, err)) { fprintf(stderr, "dumpapple: %s\n", err.c_str()); return 1; }
    AnalyzeOptions ao;
    if (!haveState) { State d; parseState(omf ? "m16x16" : "e", d); ao.entryState = d; }
    else ao.entryState = entry;
    ao.followTables = followTables;
    ao.autoInline = autoInline;
    ao.immPointers = immPointers;
    ao.strictSmc = strictSmc;
    ao.seedTargets = seedTargets;
    ao.copyStores = autoCopyStores;
    if (platformArg.empty()) platformArg = omf ? "gsos" : "none";
    if (platformArg == "gsos" && cpu != Cpu::C65816 && !quiet)
        fprintf(stderr, "dumpapple: warning: --platform gsos with --cpu %s (GS/OS calls are 65816 JSL; the rule cannot fire)\n", cpuName(cpu));
    ao.platform = platformArg == "gsos" ? Platform::GSOS : platformArg == "prodos8" ? Platform::ProDOS8 : Platform::None;
    for (auto &e : entryArgs) {
        EntryPoint ep{0, false, State{}};
        std::string as = e;
        auto c = e.rfind(':');
        if (c != std::string::npos && parseState(e.substr(c + 1), ep.st)) {
            ep.hasState = true; as = e.substr(0, c);
            if (cpu != Cpu::C65816 && !quiet) fprintf(stderr, "dumpapple: warning: --entry %s: width state ignored for --cpu %s\n", e.c_str(), cpuName(cpu));
        }
        if (!parseAddr(as, img, ep.addr)) { fprintf(stderr, "dumpapple: bad --entry %s\n", e.c_str()); return 2; }
        ao.entries.push_back(ep);
        ao.userEntries.insert(ep.addr);
    }
    if (omf) {
        bool first = true;
        for (auto &s : img.segs) {
            // only static code segments (type $00, KIND bit $8000 = dynamic clear)
            if (!s.isCode() || (s.kind & 0x8000) || s.data.empty()) continue;
            if (!first && !segEntries) break;
            if (s.entry < s.data.size()) ao.entries.push_back(EntryPoint{s.base + s.entry, false, State{}});
            first = false;
        }
    } else if (defaultEntry) {
        ao.entries.push_back(EntryPoint{org, false, State{}});
    }
    if (autoCpu) {
        // Raw file, no --cpu: decode from the entry as a 65816 (starting in emulation mode, as a
        // 65C02 would run it) and look for instructions that only a 65816 runs. On a 65C02 all
        // of these encodings are NOPs, so a 65C02 program does not execute them on its flow.
        // Not evidence: COP/WDM ($02/$42, the 65C02's 2-byte NOPs), xce without a clc right
        // before it (carry unknown), and long or stack-relative operands alone ($x7/$xF are the
        // 65C02's RMB/SMB/BBR/BBS). Bytes off the flow (data, unresolved jumps) never count.
        static const std::map<uint8_t, const char *> strong = {
            {0x82, "brl"}, {0x22, "jsl"}, {0x5C, "jml"}, {0xDC, "jml [abs]"}, {0x6B, "rtl"}, {0xC2, "rep"}, {0xE2, "sep"},
            {0x8B, "phb"}, {0xAB, "plb"}, {0x0B, "phd"}, {0x2B, "pld"}, {0x4B, "phk"}, {0x5B, "tcd"}, {0x7B, "tdc"},
            {0x1B, "tcs"}, {0x3B, "tsc"}, {0x9B, "txy"}, {0xBB, "tyx"}, {0xEB, "xba"}, {0x44, "mvp"}, {0x54, "mvn"},
            {0xF4, "pea"}, {0xD4, "pei"}, {0x62, "per"}, {0xFC, "jsr (abs,x)"}};
        bool fits = true;
        for (auto &sg : img.segs) if ((uint64_t)sg.base + sg.data.size() > 0x10000) fits = false;
        Decoder pd(Cpu::C65816);
        Analysis pa;
        std::string ev; int nev = 0, npri = 0, nagree = 0; bool gatePri = false; bool evPri = false; uint32_t gateAd = 0; int gateTxt = 0;
        if (pd.ok()) {
            AnalyzeOptions po = ao;
            po.strictSmc = false;      // the CPU does not depend on the store policy: same choice in both modes
            analyze(img, h, po, pd, pa);
            // agreement: the same file decoded as a 65C02 must reach the address with an
            // instruction starting there (decoded, or flow stopped on it). Flow the 65C02 never
            // takes (data after a divergence, operands of a 3-byte BBR the 65816 reads as 4)
            // is not evidence.
            Analysis ca;
            std::vector<uint32_t> co_entries;
            {
                Decoder cd(Cpu::C65C02);
                AnalyzeOptions co = po;
                Hints ch = h;
                State e8; parseState("e", e8);
                co.entryState = e8;
                for (auto &ep : co.entries) ep.st = e8;
                for (auto &he : ch.entries) he.st = e8;
                for (auto &f : ch.forced) f.second = e8;
                for (auto &r : ch.returns) r.second = e8;
                for (auto &t : ch.tables) t.st = e8;
                if (cd.ok() && fits) analyze(img, ch, co, cd, ca);
                for (auto &e : co.entries) co_entries.push_back(e.addr);
                for (auto &e : ch.entries) co_entries.push_back(e.addr);
            }
            // a 65C02 stop agrees when the 65C02 flow falls into it from a decoded instruction or
            // starts there (an entry); a jump landing on it may be a jump into data at a wrong
            // origin. Table entries the 65816 decode takes from a table the 65C02 decode uses agree too.
            std::set<uint32_t> edgeOk;
            for (auto &[a, why] : ca.bad) {
                auto it = ca.code.lower_bound(a);
                bool fall = it != ca.code.begin() && (--it, it->first + it->second.in.len == a);
                bool ent = !img.segs.empty() && a == img.segs[0].base;
                for (auto &e : co_entries) ent |= e == a;
                if (fall || ent) edgeOk.insert(a);
            }
            {
                AddrMap am(img);
                for (auto &t : pa.tables) {
                    if (!t.user || !ca.code.count(t.user)) continue;
                    for (uint32_t i = 0; i < t.count; i++) {
                        size_t n; const uint8_t *q = am.at(t.addr + i * t.entrySize(), n);
                        if (!q || n < t.entrySize()) break;
                        int hi = -1;
                        if (t.kind == TK_SPLIT) { size_t n2; const uint8_t *qh = am.at(t.hiAddr + i, n2); if (!qh) break; hi = *qh; }
                        edgeOk.insert(tableTarget(t, q, hi));
                    }
                }
            }
            // the shared prefix must read as code: past a brk or an invalid 65C02 stop on a byte that
            // is not 65816-only either, the flow is in data and what follows is no evidence
            uint32_t junk = ~0u;
            for (auto &[a, c] : ca.code) if (c.in.b[0] == 0x00) { junk = a; break; }
            {
                AddrMap am(img);
                for (auto &[a, why] : ca.bad) {
                    if (a >= junk) break;
                    size_t n; const uint8_t *q = am.at(a, n);
                    if (q && (strong.count(*q) || *q == 0x82 || *q == 0x22 || *q == 0x5C || *q == 0xDC || *q == 0x6B || *q == 0xC2 || *q == 0xE2 || *q == 0xFB)) continue;
                    junk = a; break;
                }
            }
            // divergence at a long operand: $xF reads as a 4-byte long address on a 65816 but as a
            // 3-byte BBR/BBS on a 65C02, so the decodes part there and a key instruction right after
            // can never agree. Compare the two readings past the divergence: vouch for the 65816 one
            // only when the 65C02 reading breaks within 8 instructions (brk, an undefined opcode, a
            // branch or jump off the image or into the middle of an instruction) while the 65816
            // reading runs on without brk/cop/wdm into a key instruction. A 65C02 reading that
            // carries on validly (bbr7 $C0,w; cpx #$E2; beq w; rts) vouches nothing.
            std::vector<std::pair<uint32_t, uint32_t>> vouched;   // 65C02-reading ranges to ignore for junk
            {
                AddrMap am(img);
                Decoder cd(Cpu::C65C02);
                for (auto &[a0, c0] : pa.code) {
                    uint8_t o = c0.in.b[0];
                    if ((o & 0x0F) != 0x0F || c0.in.len != 4 || !cd.ok()) continue;
                    if (!ca.code.count(a0) && !edgeOk.count(a0)) continue;
                    // 65816 reading
                    uint32_t key = ~0u, q = a0 + 4;
                    for (int k = 0; k < 8 && key == ~0u; k++) {
                        auto it = pa.code.find(q);
                        if (it == pa.code.end()) break;
                        uint8_t oq = it->second.in.b[0];
                        if (oq == 0x00 || oq == 0x02 || oq == 0x42) break;
                        if (oq == 0x82 || oq == 0x22 || oq == 0x5C || oq == 0xDC || oq == 0x6B || oq == 0xC2 || oq == 0xE2) key = q;
                        else if (oq == 0x18) {
                            auto nx = pa.code.find(q + 1);
                            if (nx != pa.code.end() && nx->second.in.b[0] == 0xFB) key = q + 1;
                        }
                        q += it->second.in.len;
                    }
                    if (key == ~0u) continue;
                    // 65C02 reading from the end of the BBR/BBS
                    bool broken = false;
                    std::vector<std::pair<uint32_t, uint32_t>> rng{{a0, a0 + 3}};
                    std::vector<uint32_t> tg, tgAbs;   // branch targets / jmp,jsr abs targets (may be ROM/OS: off the image is fine)
                    {
                        size_t n; const uint8_t *pb = am.at(a0, n);
                        if (pb && n >= 3) tg.push_back(a0 + 3 + (int8_t)pb[2]);   // the BBR/BBS target
                    }
                    q = a0 + 3;
                    for (int k = 0; k < 8 && !broken; k++) {
                        size_t n; const uint8_t *pb = am.at(q, n);
                        Insn in; std::string why;
                        if (!pb || !cd.decode(pb, n, q, 1, 1, in, why) || pb[0] == 0x00) { broken = true; break; }
                        rng.push_back({q, q + in.len});
                        uint8_t oq = pb[0];
                        if ((oq & 0x1F) == 0x10 || oq == 0x80) tg.push_back(q + 2 + (int8_t)pb[1]);
                        else if ((oq & 0x07) == 0x07 && (oq & 0x08)) tg.push_back(q + 3 + (int8_t)pb[2]);
                        else if (oq == 0x4C || oq == 0x20) tgAbs.push_back(pb[1] | pb[2] << 8);
                        // an unconditional transfer ends the window: the 65C02 reading carried on
                        // validly, and bytes after it (a $00 table) are not a breakdown
                        if (oq == 0x60 || oq == 0x40 || oq == 0x4C || oq == 0x6C || oq == 0x7C || oq == 0x80) break;
                        q += in.len;
                    }
                    for (uint32_t t : tgAbs)
                        for (auto &[r0, r1] : rng) if (t > r0 && t < r1) broken = true;
                    for (uint32_t t : tg) {
                        if (!am.contains(t)) broken = true;
                        for (auto &[r0, r1] : rng) if (t > r0 && t < r1) broken = true;
                    }
                    if (!broken) continue;
                    edgeOk.insert(key);
                    vouched.push_back({a0 + 3, key + 1});
                }
            }
            if (junk != ~0u) {   // a 65C02 break inside a vouched divergence is the evidence, not junk
                bool in = false;
                for (auto &[r0, r1] : vouched) in |= junk >= r0 && junk < r1;
                if (in) {
                    uint32_t j2 = ~0u;
                    for (auto &[a, c] : ca.code) {
                        bool v = false; for (auto &[r0, r1] : vouched) v |= a >= r0 && a < r1;
                        if (!v && c.in.b[0] == 0x00) { j2 = a; break; }
                    }
                    AddrMap am(img);
                    for (auto &[a, why] : ca.bad) {
                        if (a >= j2) break;
                        bool v = false; for (auto &[r0, r1] : vouched) v |= a >= r0 && a < r1;
                        if (v) continue;
                        size_t n; const uint8_t *q = am.at(a, n);
                        if (q && (strong.count(*q) || *q == 0xFB)) continue;
                        j2 = a; break;
                    }
                    junk = j2;
                }
            }
            // the 65816 reading from a weak first hit, decoded straight-line with m/x tracked
            // through rep/sep (immediates sized by the current widths), must reach the key and run
            // 4 instructions past it without brk/cop/wdm or an undecodable byte. Carry and E are
            // tracked too (clc/sec, xce swaps them; start native, carry unknown). A width that is
            // unknown (xce of unknown mode, plp, rep with E unknown): an immediate that depends on
            // it is tried both ways (at most 4 such splits) and the reading passes if either path
            // stays clean.
            AddrMap pam(img);
            std::function<bool(uint32_t, uint32_t, int, int, int, int, int, int, int)> run =
                [&](uint32_t q, uint32_t to, int k, int after, int m, int x, int c, int e, int splits) -> bool {
                for (; k < 24; k++) {
                    size_t n; const uint8_t *pb = pam.at(q, n);
                    if (!pb) return false;
                    uint8_t oq = pb[0];
                    WidthDep wd = widthDep(oq);
                    if ((wd == WidthDep::M && m < 0) || (wd == WidthDep::X && x < 0)) {
                        if (splits >= 4) return false;
                        for (int v = 1; v >= 0; v--)
                            if (run(q, to, k, after, wd == WidthDep::M ? v : m, wd == WidthDep::X ? v : x, c, e, splits + 1)) return true;
                        return false;
                    }
                    Insn in; std::string why;
                    if (!pd.decode(pb, n, q, m < 0 ? 1 : m, x < 0 ? 1 : x, in, why)) return false;
                    if (oq == 0x00 || oq == 0x02 || oq == 0x42) return false;
                    if (q == to) after = 0;
                    else if (after >= 0 && ++after >= 4) return true;
                    else if (after < 0 && q > to) return false;
                    // e: 0 native, 1 emulation, -1 unknown; c: carry 0/1/-1. rep widens only in
                    // native mode; in emulation m/x stay 8-bit; with E unknown rep leaves them unknown
                    if (oq == 0xC2) {
                        if (e == 0) { if (pb[1] & 0x20) m = 0; if (pb[1] & 0x10) x = 0; }
                        else if (e < 0) { if (pb[1] & 0x20) m = -1; if (pb[1] & 0x10) x = -1; }
                    }
                    if (oq == 0xE2) { if (pb[1] & 0x20) m = 1; if (pb[1] & 0x10) x = 1; }
                    if (oq == 0xC2 && (pb[1] & 1)) c = 0;   // rep #1 clears carry
                    if (oq == 0xE2 && (pb[1] & 1)) c = 1;   // sep #1 sets it
                    {   // other carry writers: adc/sbc/cmp (all modes), cpx/cpy, asl/lsr/rol/ror
                        int lo = oq & 0x1F, hi = oq & 0xE0;
                        bool alu = (hi == 0x60 || hi == 0xE0 || hi == 0xC0) &&
                                   (lo == 0x01 || lo == 0x03 || lo == 0x05 || lo == 0x07 || lo == 0x09 || lo == 0x0D || lo == 0x0F ||
                                    lo == 0x11 || lo == 0x12 || lo == 0x13 || lo == 0x15 || lo == 0x17 || lo == 0x19 || lo == 0x1D || lo == 0x1F);
                        bool cxy = oq == 0xE0 || oq == 0xE4 || oq == 0xEC || oq == 0xC0 || oq == 0xC4 || oq == 0xCC;
                        bool sh = (hi == 0x00 || hi == 0x20 || hi == 0x40 || hi == 0x60) &&
                                  (lo == 0x06 || lo == 0x0A || lo == 0x0E || lo == 0x16 || lo == 0x1E);
                        if (alu || cxy || sh) c = -1;
                    }
                    if (oq == 0x18) c = 0;
                    if (oq == 0x38) c = 1;
                    if (oq == 0xFB) {   // xce swaps carry and E
                        int ne = c, wasE = e; c = e; e = ne;
                        if (e == 1 || (e == 0 && wasE == 1)) m = x = 1;   // emulation / just entered native
                        else if (e < 0 || wasE < 0) m = x = -1;
                    }
                    if (oq == 0x28) { c = -1; if (e != 1) m = x = -1; }   // plp: carry, m, x unknown, E kept
                    if (oq == 0x60 || oq == 0x6B || oq == 0x40 || oq == 0x4C || oq == 0x5C || oq == 0x6C || oq == 0x7C || oq == 0xDC || oq == 0x80 || oq == 0x82)
                        return after >= 0;   // flow ends after the key
                    q += in.len;
                }
                return false;
            };
            auto plain = [&](uint32_t from, uint32_t to) { return run(from, to, 0, -1, 1, 1, -1, platformArg == "prodos8" ? 1 : -1, 0); };
            // start: carry unknown; E unknown, or emulation under ProDOS 8 (it launches SYS/BIN files in emulation)
            for (auto &[ad, ci] : pa.code) {
                if (ad > junk) break;
                uint8_t op = ci.in.b[0];
                const char *nm = nullptr;
                bool agreed = ca.code.count(ad) || edgeOk.count(ad);
                if (!agreed) {
                    // past the point where the 65C02 decode stopped, the 65816 decode is the only one;
                    // an address the 65C02 decoded as part of another instruction contradicts it
                    auto it = ca.code.upper_bound(ad);
                    if (it != ca.code.begin() && (--it, ad < it->first + it->second.in.len)) continue;
                }
                if (auto it = strong.find(op); it != strong.end()) nm = it->second;
                else if (op == 0xFB) {   // xce counts only right after clc (native mode on purpose)
                    auto pv = pa.code.find(ad - 1);
                    if (pv != pa.code.end() && pv->second.in.len == 1 && pv->second.in.b[0] == 0x18) nm = "clc; xce";
                }
                if (!nm) continue;
                // bytes that read as text around it (ASCII or high ASCII): flow that ran into a
                // message, not 65816 code
                int txt = 0;
                for (int k = -4; k <= 4; k++) {
                    uint32_t q = ad + k; uint8_t c; bool have = false;
                    for (auto &sg : img.segs) if (q >= sg.base && q < sg.base + sg.data.size()) { c = sg.data[q - sg.base]; have = true; }
                    if (have && ((c >= 0x20 && c < 0x7F) || (c >= 0xA0 && c < 0xFF))) txt++;
                }
                if (txt == 9) continue;
                // weak-class bytes (not brl/jsl/jml/rtl/rep/sep/clc;xce) mostly surrounded by text
                // are a decode that ran into a message
                if (txt >= 6 && !(op == 0x82 || op == 0x22 || op == 0x5C || op == 0xDC || op == 0x6B || op == 0xC2 || op == 0xE2 || op == 0xFB)) continue;
                bool primary = op == 0x82 || op == 0x22 || op == 0x5C || op == 0xDC || op == 0x6B || op == 0xC2 || op == 0xE2 || op == 0xFB;
                // the first agreed hit sets the tone: after a stray other-class byte (mvp, plb, ...)
                // stopped the 65C02 decode, the 65816 decode runs on in what is likely data, so a
                // brl/jsl found there is not trusted; only more of the weak class can add up
                if (!agreed && !nagree) continue;
                if (agreed && !nagree) gatePri = primary, gateAd = ad, gateTxt = txt;
                if (agreed) nagree++;
                // a weak first hit away from text (under 6 of 9 text bytes) whose 65816 reading runs on as code into this key
                // (phk; plb; rep) still lets the key count; next to text, or with brk/cop/wdm on the
                // way or in the 4 instructions after the key, it is data
                if (primary && !agreed && !gatePri && !(gateTxt < 6 && plain(gateAd, ad))) continue;
                if (primary) npri++;
                if (!nev || (primary && !evPri)) { char buf[96]; snprintf(buf, sizeof buf, "65816-only %s at $%04X on flow from the entry", nm, (unsigned)(ad & 0xFFFF)); ev = buf; evPri = primary; }
                nev++;
            }
        }
        int stray = 0;
        if (!nagree) { stray = nev; nev = 0; npri = 0; }   // the 65C02 decode never reaches any of it
        if (!npri && nev < 3) { stray = nev; nev = 0; }   // one or two stray pea/phd-like bytes: not enough
        if (nev) { cpu = Cpu::C65816; cpuWhy = ev + (nev > 1 ? " (" + std::to_string(nev) + " such instructions)" : ""); }
        else cpuWhy = !fits ? "image above $FFFF" : stray ? "only " + std::to_string(stray) + " stray 65816-only byte(s) such as " + ev.substr(11) + ", no brl/jsl/jml/rtl/rep/sep/clc;xce" : "no 65816-only instruction on flow from the entry";
        if (!fits) cpu = Cpu::C65816;     // only a 65816 addresses more than 64K
    }
    if (cpu != Cpu::C65816) {          // no M/X/E on 6502/65C02: everything is 8-bit
        State e8; parseState("e", e8);
        ao.entryState = e8;
        for (auto &ep : ao.entries) ep.st = e8;
        for (auto &he : h.entries) he.st = e8;
        for (auto &f : h.forced) f.second = e8;
        for (auto &r : h.returns) r.second = e8;
        for (auto &t : h.tables) t.st = e8;
    }
    Decoder dec(cpu);
    if (!dec.ok()) { fprintf(stderr, "dumpapple: Capstone 65816 support unavailable\n"); return 1; }
    Analysis an;
    analyze(img, h, ao, dec, an);
    if (autoRegion && !omf && !hintRegions && !autoTried) {
        autoTried = true;
        autoRegions = detectMoves(img, an, org, autoNotes, autoCopyStores);
        if (!autoRegions.empty()) goto rebuild;
    }
    for (auto &n : autoNotes) an.notes.insert(an.notes.begin(), n);
    bool seedOff = seedSet < 0, regOff = regionSet < 0 && !omf;    // auto regions apply to raw input only
    if (strictSmc && (seedOff || regOff)) {
        std::string what = seedOff && regOff ? "seed targets and auto regions are" : seedOff ? "seed targets are" : "auto regions are";
        std::string how = seedOff && regOff ? "--seed-targets / --auto-region turn them" : seedOff ? "--seed-targets turns them" : "--auto-region turns them";
        an.notes.insert(an.notes.begin(), "--strict-smc: " + what + " off (" + how + " back on)");
    }
    if (!dumpImage.empty()) {
        auto f = img.flat();
        if (!writeFile(dumpImage, std::string(f.begin(), f.end()))) { fprintf(stderr, "dumpapple: cannot write %s\n", dumpImage.c_str()); return 1; }
    }
    std::string base = "listing";
    if (!out.empty()) {
        base = out;
        auto sl = base.find_last_of('/');
        if (sl != std::string::npos) base = base.substr(sl + 1);
        if (base.size() > 2 && base.substr(base.size() - 2) == ".s") base.resize(base.size() - 2);
    }
    EmitOptions eo{in, base, cpu, platformArg};
    std::string asmText, cfgText;
    if (!emitListing(img, h, an, eo, asmText, cfgText, err)) { fprintf(stderr, "dumpapple: %s\n", err.c_str()); return 1; }
    if (!cpuWhy.empty()) {           // say which CPU was assumed and why (--cpu overrides)
        std::string ln = std::string("; cpu: ") + ca65Cpu(cpu) + " (auto: " + cpuWhy + "; --cpu overrides)\n";
        auto p = asmText.find("\n.setcpu ");
        asmText.insert(p == std::string::npos ? 0 : p + 1, ln);
    }
    if (out.empty()) fwrite(asmText.data(), 1, asmText.size(), stdout);
    else {
        if (!writeFile(out, asmText)) { fprintf(stderr, "dumpapple: cannot write %s\n", out.c_str()); return 1; }
        if (cfgPath.empty() && out.size() > 2 && out.substr(out.size() - 2) == ".s") {
            cfgPath = out;
            if (cfgPath.size() > 2 && cfgPath.substr(cfgPath.size() - 2) == ".s") cfgPath.resize(cfgPath.size() - 2);
            cfgPath += ".cfg";
        }
    }
    if (!cfgPath.empty() && !writeFile(cfgPath, cfgText)) { fprintf(stderr, "dumpapple: cannot write %s\n", cfgPath.c_str()); return 1; }
    size_t codeBytes = 0;
    for (auto &kv : an.code) codeBytes += kv.second.in.len;
    size_t total = img.flat().size();
    if (!quiet)
        fprintf(stderr, "dumpapple: %zu segment(s), %zu bytes, %zu instructions (%zu bytes code), %zu labels, %zu stop(s)\n",
                img.segs.size(), total, an.code.size(), codeBytes, an.labels.size(), an.bad.size());
    if (verify) {
        char tmpl[] = "/tmp/dumpapple-verify-XXXXXX";
        if (!mkdtemp(tmpl)) { perror("mkdtemp"); return 1; }
        std::string dir = tmpl;
        auto f = img.flat();
        writeFile(dir + "/v.s", asmText);
        writeFile(dir + "/v.cfg", cfgText);
        writeFile(dir + "/orig.bin", std::string(f.begin(), f.end()));
        std::string cmd = shq(ca65) + " --cpu " + ca65Cpu(cpu) + " -t none -o " + shq(dir + "/v.o") + " " + shq(dir + "/v.s") + " 2>" + shq(dir + "/log") +
                          " && " + shq(ld65) + " -C " + shq(dir + "/v.cfg") + " -o " + shq(dir + "/v.bin") + " " + shq(dir + "/v.o") + " 2>>" + shq(dir + "/log") +
                          " && cmp -s " + shq(dir + "/v.bin") + " " + shq(dir + "/orig.bin");
        int rc = system(cmd.c_str());
        if (rc != 0) {
            std::ifstream lg(dir + "/log");
            std::stringstream ss; ss << lg.rdbuf();
            fprintf(stderr, "dumpapple: VERIFY FAILED (work dir kept: %s)\n%s", dir.c_str(), ss.str().c_str());
            return 3;
        }
        system(("rm -rf " + shq(dir)).c_str());
        if (!quiet) fprintf(stderr, "dumpapple: verify OK: ca65/ld65 rebuild is byte-identical (%zu bytes)\n", total);
    }
    return 0;
}
