#pragma once
#include "image.h"
#include "state.h"
#include <map>
#include <set>
#include <string>
#include <vector>

namespace da {
// User-supplied hints ("names file").  One directive per line, '#' comments.
//   entry   ADDR [STATE]   code entry point (STATE: e m8x8 m8x16 m16x8 m16x16)
//   state   ADDR STATE     force the width state whenever flow reaches ADDR
//   returns ADDR STATE     calls to ADDR come back with STATE
//   noreturn ADDR          calls to ADDR do not return
//   data    ADDR LEN       never decode ADDR..ADDR+LEN-1 as code
//   word    ADDR LEN       data, emitted as .word (LEN bytes, even)
//   name    ADDR NAME      label name
//   comment ADDR TEXT...   comment line before ADDR
//   segbase SEGNUM ADDR    OMF: load segment SEGNUM at ADDR
//   inline  ADDR N         calls (jsr/jsl) to ADDR are followed by N inline bytes
//   table   ADDR COUNT [word|long|rts] [STATE]
//                          jump table of COUNT entries (overrides the heuristic);
//                          word: bank-of-ADDR | w, long: 24-bit, rts: w+1 (RTS/push tables)
// ADDR is $hex, 0xhex or bare hex (24-bit), or SEGNUM:OFFSET (hex) for OMF.
struct Hints {
    struct Entry { uint32_t addr; bool hasState; State st; };
    std::vector<Entry> entries;
    std::map<uint32_t, State> forced, returns;
    std::set<uint32_t> noreturn;
    std::map<uint32_t, uint32_t> dataRanges, wordRanges;   // start -> len
    std::map<uint32_t, std::string> names;
    std::map<uint32_t, std::vector<std::string>> comments;
    std::map<uint16_t, uint32_t> segBase;
    struct Table { uint32_t addr; uint32_t count; int kind; bool hasState; State st; uint32_t hiAddr = 0; };   // kind 4 = split (hiAddr)
    std::vector<Table> tables;
    std::map<uint32_t, uint32_t> inlines;
    std::map<uint32_t, int> varInlines;      // `inline ADDR z|hi|lo`: 4 zero, 5 bit 7 set, 6 bit 7 clear terminator
    struct Region { uint32_t fileOff, len, addr; };
};
struct RawHints { std::vector<std::vector<std::string>> lines; std::vector<int> lineNo; std::vector<std::string> files; std::string file; };
// Appends the directives of PATH (several files may be read into one RawHints).
bool readHintsFile(const std::string &path, RawHints &raw, std::string &err);
bool parseNumber(const std::string &s, uint32_t &v);
// Pass 1: only segbase (needed before loading OMF).
bool hintsSegBase(const RawHints &raw, std::map<uint16_t, uint32_t> &out, std::string &err);
// Pass 1 too: `region FILEOFF LEN ADDR` (raw input: bytes that run at another address).
bool hintsRegions(const RawHints &raw, std::vector<Hints::Region> &out, std::string &err);
// Pass 2: resolve addresses against the loaded image.
bool resolveHints(const RawHints &raw, const Image &img, Hints &h, std::string &err);
bool parseAddr(const std::string &s, const Image &img, uint32_t &addr);
}
