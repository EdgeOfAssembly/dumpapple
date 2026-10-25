// Fuzz target: OMF loader + analysis + listing emitter must never crash,
// hang or trip ASan/UBSan on arbitrary input.
// Build with clang -fsanitize=fuzzer (libFuzzer) or, without clang, with
// -DSTANDALONE_FUZZ which adds a small built-in mutation driver.
#include "../src/analyze.h"
#include "../src/emit.h"
#include "../src/omf.h"
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <random>
#include <string>
#include <vector>

using namespace da;

static void runOne(const std::vector<uint8_t> &f, bool asOmf, uint8_t knob) {
    static Decoder dec816(Cpu::C65816), dec02(Cpu::C65C02), dec6502(Cpu::C6502);
    Cpu cpu = asOmf ? Cpu::C65816 : (knob % 3 == 0 ? Cpu::C6502 : knob % 3 == 1 ? Cpu::C65C02 : Cpu::C65816);
    Decoder &dec = cpu == Cpu::C65816 ? dec816 : cpu == Cpu::C65C02 ? dec02 : dec6502;
    Image img;
    std::string err;
    if (asOmf) {
        OmfOptions oo;
        if (!loadOmf(f, oo, img, err)) return;
    } else {
        if (f.empty()) return;
        Segment s; s.base = cpu == Cpu::C65816 ? 0x2000 + ((uint32_t)knob << 16) : 0x0200; s.data = f;
        if (cpu != Cpu::C65816 && f.size() > 0xF000) return;
        img.segs.push_back(s);
    }
    Hints h;
    AnalyzeOptions ao;
    const char *st[] = {"e", "m8x8", "m8x16", "m16x8", "m16x16"};
    parseState(st[knob % 5], ao.entryState);
    ao.maxSteps = 200000;
    ao.followTables = (knob & 0x40) == 0;
    ao.autoInline = (knob & 0x04) == 0;
    ao.immPointers = (knob & 0x08) == 0;
    if (knob & 0x20) h.varInlines[0x2000 + (knob & 0x1F)] = 4 + knob % 4;
    ao.platform = (knob & 0x30) == 0x10 ? Platform::GSOS : (knob & 0x30) == 0x20 ? Platform::ProDOS8 : Platform::None;
    if (knob & 0x80) { h.inlines[0x2000 + (knob & 0x0F)] = (knob & 7); /* includes N=0: analyzer must ignore it */ h.tables.push_back({0x2004u + (knob & 3), 1u + (knob & 3), knob % 3, (knob & 8) != 0, ao.entryState}); }
    for (auto &s : img.segs) if (!s.data.empty()) ao.entries.push_back(EntryPoint{s.base + (s.entry < s.data.size() ? s.entry : 0), false, State{}});
    Analysis an;
    analyze(img, h, ao, dec, an);
    std::string a, c;
    EmitOptions eo{"fuzz", "fuzz", cpu, "none"};
    emitListing(img, h, an, eo, a, c, err);
}

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *d, size_t n) {
    if (n > (1u << 20)) return 0;
    std::vector<uint8_t> f(d, d + n);
    runOne(f, true, n ? d[0] : 0);
    runOne(f, false, n ? d[n - 1] : 0);
    return 0;
}

#ifdef STANDALONE_FUZZ
int main(int argc, char **argv) {
    long runs = 10000;
    std::vector<std::vector<uint8_t>> corpus;
    for (int i = 1; i < argc; i++) {
        if (!strncmp(argv[i], "-runs=", 6)) { runs = atol(argv[i] + 6); continue; }
        std::ifstream in(argv[i], std::ios::binary);
        corpus.emplace_back(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
    }
    if (argc < 2) { printf("usage: fuzz_dumpapple [-runs=N] SEED...\n"); return 0; }
    if (corpus.empty()) corpus.push_back({});
    std::mt19937 rng(12345);
    for (long r = 0; r < runs; r++) {
        std::vector<uint8_t> f = corpus[rng() % corpus.size()];
        int muts = 1 + rng() % 8;
        for (int k = 0; k < muts; k++) {
            int kind = rng() % 6;
            size_t p = f.empty() ? 0 : rng() % f.size();
            if (kind == 0 && !f.empty()) f[p] = (uint8_t)rng();
            else if (kind == 1 && !f.empty()) f[p] ^= 1u << (rng() % 8);
            else if (kind == 2) f.insert(f.begin() + p, (uint8_t)rng());
            else if (kind == 3 && !f.empty()) f.erase(f.begin() + p);
            else if (kind == 4 && f.size() > 4) { uint32_t v = rng() % 3 == 0 ? 0xFFFFFFFF : rng(); size_t q = rng() % (f.size() - 3); memcpy(&f[q], &v, 4); }
            else if (kind == 5 && f.size() > 1) f.resize(rng() % f.size());
        }
        LLVMFuzzerTestOneInput(f.data(), f.size());
        if (r % 2000 == 0) fprintf(stderr, "run %ld\n", r);
    }
    fprintf(stderr, "done: %ld runs, no crashes\n", runs);
    return 0;
}
#endif
