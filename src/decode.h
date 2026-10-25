#pragma once
#include "state.h"
#include <capstone/capstone.h>
#include <cstdint>
#include <cstddef>
#include <string>

namespace da {
struct Insn {
    uint32_t addr = 0;
    uint8_t len = 0;
    uint8_t b[4] = {0, 0, 0, 0};
    unsigned id = 0;            // MOS65XX_INS_*
    int am = 0;                 // MOS65XX_AM_*
    std::string mnemonic;
};
enum class WidthDep { None, M, X };
// Target CPU.  C65C02 is the WDC W65C02S superset (Rockwell RMB/SMB/BBR/BBS plus
// WAI/STP); a Rockwell-only or plain CMOS program uses a subset of the same
// encodings, so one decoder covers both.  ca65 ".setcpu \"65C02\"" accepts all.
enum class Cpu { C6502, C65C02, C65816 };
bool parseCpu(const std::string &s, Cpu &c);
const char *cpuName(Cpu c);      // for messages
const char *ca65Cpu(Cpu c);      // .setcpu argument
WidthDep widthDep(uint8_t opcode);

// Wraps Capstone 6 for the W65C816.  Capstone 6.0 rejects plain
// CS_MODE_MOS65XX_65816 (8-bit m/x) in cs_open's mode mask, so two handles are
// used: LONG_M (m16,x8) and LONG_X (m8,x16).  Any instruction depends on at
// most one of M/X, so one of the two handles always has the right width.
class Decoder {
public:
    explicit Decoder(Cpu cpu = Cpu::C65816);
    Cpu cpu() const { return cpu_; }
    ~Decoder();
    bool ok() const { return cpu_ == Cpu::C65816 ? (okM && okX) : ok8; }
    // m/x: 1 = 8-bit, 0 = 16-bit, -1 = unknown.  Returns false with
    // reason set when the width is unknown, bytes are truncated or invalid.
    bool decode(const uint8_t *p, size_t avail, uint32_t addr, int m, int x, Insn &out, std::string &reason);
private:
    csh hM16 = 0, hX16 = 0;
    bool okM = false, okX = false;
    Cpu cpu_;
    csh h8 = 0;   // 6502 / 65C02 handle
    bool ok8 = false;
};
}
