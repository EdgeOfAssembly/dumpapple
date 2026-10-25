#include "decode.h"
#include <cctype>

#if CS_API_MAJOR < 6 || (CS_API_MAJOR == 6 && CS_API_MINOR == 0 && CS_VERSION_PRE_RELEASE < CS_VERSION_ALPHA11)
#error "dumpapple needs Capstone >= 6.0.0 Alpha11 (CS_MODE_MOS65XX_65816_LONG_M/LONG_X)"
#endif

namespace da {

bool parseState(const std::string &s0, State &o) {
    std::string s;
    for (char ch : s0) s += (char)std::tolower((unsigned char)ch);
    o = State{};
    o.c = -1;
    if (s == "e" || s == "emu" || s == "emulation") { o.e = 1; o.m = 1; o.x = 1; return true; }
    o.e = 0;
    if (s == "native" || s == "m8x8") { o.m = 1; o.x = 1; return true; }
    if (s == "m8x16") { o.m = 1; o.x = 0; return true; }
    if (s == "m16x8") { o.m = 0; o.x = 1; return true; }
    if (s == "m16x16" || s == "full16") { o.m = 0; o.x = 0; return true; }
    return false;
}

WidthDep widthDep(uint8_t op) {
    switch (op) {
    case 0x09: case 0x29: case 0x49: case 0x69: case 0x89: case 0xA9: case 0xC9: case 0xE9:
        return WidthDep::M;
    case 0xA0: case 0xA2: case 0xC0: case 0xE0:
        return WidthDep::X;
    default:
        return WidthDep::None;
    }
}

bool parseCpu(const std::string &s0, Cpu &c) {
    std::string s;
    for (char ch : s0) s += (char)std::tolower((unsigned char)ch);
    if (s == "6502") { c = Cpu::C6502; return true; }
    if (s == "65c02" || s == "w65c02" || s == "r65c02") { c = Cpu::C65C02; return true; }
    if (s == "65816" || s == "65c816" || s == "w65c816") { c = Cpu::C65816; return true; }
    return false;
}
const char *cpuName(Cpu c) { return c == Cpu::C6502 ? "6502" : c == Cpu::C65C02 ? "65c02" : "65816"; }
const char *ca65Cpu(Cpu c) { return c == Cpu::C6502 ? "6502" : c == Cpu::C65C02 ? "65C02" : "65816"; }

Decoder::Decoder(Cpu cpu) : cpu_(cpu) {
    if (cpu != Cpu::C65816) {
        ok8 = cs_open(CS_ARCH_MOS65XX, (cs_mode)(cpu == Cpu::C6502 ? CS_MODE_MOS65XX_6502 : CS_MODE_MOS65XX_W65C02), &h8) == CS_ERR_OK;
        if (ok8) cs_option(h8, CS_OPT_DETAIL, CS_OPT_ON);
        return;
    }
    okM = cs_open(CS_ARCH_MOS65XX, (cs_mode)CS_MODE_MOS65XX_65816_LONG_M, &hM16) == CS_ERR_OK;
    okX = cs_open(CS_ARCH_MOS65XX, (cs_mode)CS_MODE_MOS65XX_65816_LONG_X, &hX16) == CS_ERR_OK;
    if (okM) cs_option(hM16, CS_OPT_DETAIL, CS_OPT_ON);
    if (okX) cs_option(hX16, CS_OPT_DETAIL, CS_OPT_ON);
}
Decoder::~Decoder() {
    if (okM) cs_close(&hM16);
    if (okX) cs_close(&hX16);
    if (ok8) cs_close(&h8);
}

bool Decoder::decode(const uint8_t *p, size_t avail, uint32_t addr, int m, int x, Insn &out, std::string &reason) {
    if (avail == 0) { reason = "end of image"; return false; }
    WidthDep d = cpu_ == Cpu::C65816 ? widthDep(p[0]) : WidthDep::None;
    csh h = cpu_ == Cpu::C65816 ? hM16 : h8;
    if (d == WidthDep::M) {
        if (m < 0) { reason = "accumulator width unknown (M flag conflict)"; return false; }
        h = m == 0 ? hM16 : hX16;
    } else if (d == WidthDep::X) {
        if (x < 0) { reason = "index width unknown (X flag conflict)"; return false; }
        h = x == 0 ? hX16 : hM16;
    }
    cs_insn *ci = nullptr;
    size_t n = cs_disasm(h, p, avail < 4 ? avail : 4, addr, 1, &ci);
    if (n == 0) {
        if (avail < 4 && cpu_ == Cpu::C65816) reason = "undecodable/truncated";
        else reason = cpu_ == Cpu::C6502 ? "undefined 6502 opcode or truncated" : "undecodable/truncated";
        return false;
    }
    if (cpu_ != Cpu::C65816 && ci->id == MOS65XX_INS_NOP && p[0] != 0xEA) {
        // Capstone decodes the 65C02's undefined opcodes as multi-byte NOPs;
        // ca65 has no mnemonic for them, so they are not treated as code.
        cs_free(ci, n);
        reason = "undefined 65C02 opcode";
        return false;
    }
    out.addr = addr;
    out.len = (uint8_t)ci->size;
    for (int i = 0; i < 4; i++) out.b[i] = i < ci->size ? p[i] : 0;
    out.id = ci->id;
    out.am = ci->detail ? ci->detail->mos65xx.am : 0;
    out.mnemonic = ci->mnemonic;
    cs_free(ci, n);
    return true;
}

}
