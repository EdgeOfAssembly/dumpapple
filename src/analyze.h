#pragma once
#include "decode.h"
#include "hints.h"
#include "image.h"
#include <map>
#include <set>
#include <string>
#include <vector>

namespace da {
struct CodeInsn { Insn in; State st; };
enum LabelKind { LK_CODE = 1, LK_SUB = 2, LK_DATA = 4, LK_ENTRY = 8, LK_JTE = 16, LK_PARAM = 32 };

enum class Platform { None, ProDOS8, GSOS };
struct EntryPoint { uint32_t addr; bool hasState; State st; };
struct AnalyzeOptions {
    State entryState;
    std::vector<EntryPoint> entries;      // in addition to hints entries
    bool followTables = true;
    Platform platform = Platform::None;
    bool autoInline = true;               // detect routines that read a terminated string after their call
    bool immPointers = true;              // lda #<x / ldx #>x pairs that point at clean code
    long maxSteps = 20000000;
    bool strictSmc = false;               // stores with fully unknown targets may modify code (no assumption)
};

// A jump/dispatch table found by the heuristic or given by a `table` hint.
// TK_RTS: words holding target-1 (RTS dispatch); TK_RTSLONG: 3-byte target-1 (RTL);
// TK_SPLIT: target-1 split into a low-byte table at addr and a high-byte table at hiAddr.
enum TableKind { TK_WORD = 0, TK_LONG = 1, TK_RTS = 2, TK_RTSLONG = 3, TK_SPLIT = 4 };
struct JumpTable {
    uint32_t addr = 0;       // first entry
    uint32_t count = 0;      // entries
    int kind = TK_WORD;      // entry size 2 (word, rts) or 3 (long)
    uint32_t bank = 0;       // bank OR'ed onto word entries
    uint32_t user = 0;       // instruction that uses it (0 = hint only)
    bool hinted = false;
    std::string why;         // why the heuristic stopped
    uint32_t hiAddr = 0;     // TK_SPLIT: the high-byte table
    uint32_t entrySize() const { return kind == TK_LONG || kind == TK_RTSLONG ? 3 : kind == TK_SPLIT ? 1 : 2; }
    uint32_t end() const { return addr + count * entrySize(); }
    bool covers(uint32_t a, uint32_t n) const {   // [a,a+n) meets one of the table's byte ranges
        if (a < end() && addr < a + n) return true;
        return kind == TK_SPLIT && a < hiAddr + count && hiAddr < a + n;
    }
};

// Inline parameter bytes that follow a call (platform ABI rule or `inline` hint).
struct InlineBlock { uint32_t len; int kind; std::string why; uint32_t target = 0; };   // kind: 0 bytes, 1 GS/OS, 2 ProDOS 8 MLI, 3 OMF jump-table entry, 4/5/6 terminated string (zero, bit 7 set, bit 7 clear)
using TableLimits = std::map<uint32_t, std::pair<uint32_t, std::string>>;   // auto table addr -> (max count, reason)

struct Analysis {
    std::set<uint32_t> refused;                 // flow targets refused because they lie in data/tables
    std::map<uint32_t, InlineBlock> inlineData; // start -> block
    int overlapEntries = 0;                     // dropped overlaps that are real entry points (BIT-skip style)
    int droppedOverlaps = 0;
    int misalignedRelocs = 0;
    int omfJumpEntries = 0;
    bool g2AssumeCSW = false, g2AssumeD = false;   // a resolved inline-string site relied on COUT via CSW / on D clear at entry
    int varInlineSites = 0;                     // calls followed by a terminated inline string
    std::map<uint32_t, std::vector<std::pair<uint32_t, uint32_t>>> varAutoBlocks;   // auto routine -> (start, len)
    std::set<uint32_t> varMisfit;
    std::map<uint32_t, int> unknownStops;       // outside routine -> call sites left undecoded after
    std::set<uint32_t> stopMisfit;
    std::map<uint32_t, uint32_t> heldBack;      // start -> length of bytes left undecoded after such calls              // outside routines with a decoded call site not followed by text+$00               // auto routines with a call site that does not fit
    std::set<uint32_t> varExits;
    std::set<uint32_t> looseOrdExits, looseProvedExits;   // pla;pla-shaped helpers: returns of ordinary calls / of proven inline calls                // return instructions of inline helpers reached by their emulation
    std::map<uint32_t, int> varInlineRoutines;  // routine -> kind (4/5/6), auto-detected or hinted
    std::set<uint32_t> noretSites;              // call sites with no fall-through edge (hint, ROM list, _SysFailMgr)
    bool lcRiskIn = false;                      // input: language-card banking may map RAM over the ROM
    std::set<uint32_t> hintNoret;               // no-return call sites that rest on a user hint
    std::set<uint32_t> hintDomIn;               // input: dominated bytes proven only with those hints
    bool romNoret = false;                      // a ROM no-return entry ended flow this pass
    std::set<uint32_t> sysFailIn, sysFailBadIn;  // _SysFailMgr sites taken / input: sites also entered by a jump
    std::map<uint32_t, uint32_t> romCallKept;   // ROM no-return target -> first call site kept as ordinary (LC risk)
    int noreturnCalls = 0;                      // OS calls that do not return (QUIT) or `noreturn` sites
    std::set<uint32_t> immEntries;              // code reached only through lda #<x / ldx #>x pairs                     // KIND $02 jump-table entries turned into entry points
    std::vector<JumpTable> tables;              // sorted by addr, non-overlapping
    std::map<uint32_t, std::string> dispatch;   // RTS/RTL/indirect addr -> comment
    std::map<uint32_t, CodeInsn> code;          // accepted, non-overlapping
    std::map<uint32_t, int> labels;             // addr -> LabelKind bits
    std::map<uint32_t, std::string> bad;        // flow reached addr but decode stopped
    std::vector<std::string> notes;
    // G1: a known carry at a length helper's adc that holds only if no other path joins in
    struct CarryClaim { uint32_t from, adc, exitBr; bool branch; uint32_t lo, hi; };   // [from,adc] must have no other entries
    std::map<uint32_t, CarryClaim> carryClaims;          // helper -> claim
    std::map<uint32_t, std::set<uint32_t>> ctlSrc;       // control target -> sources (~0u = entry, table, hint)
    std::set<uint32_t> unkStores;                        // stores with a fully unknown target
    bool unkAssumed = false;                             // ... assumed not to modify code (default mode)
    std::set<uint32_t> indSites;                         // decoded jmp (abs)/(abs,x)/[abs], jsr (abs,x)
    // self-modifying code: the instruction forms that may run at an address whose bytes a store with
    // a known value may change (the encoded form first unless the store runs before it on every path)
    std::map<uint32_t, std::vector<CodeInsn>> variants;
    std::map<uint32_t, std::string> patchNote;           // listing comment for such instructions
};

// Locates bytes for an absolute 24-bit address in the image.
struct AddrMap {
    const Image &img;
    explicit AddrMap(const Image &i) : img(i) {}
    // returns pointer and bytes available within the containing segment
    const uint8_t *at(uint32_t a, size_t &avail, int *segIndex = nullptr) const;
    bool contains(uint32_t a) const { size_t n; return at(a, n) != nullptr; }
};

// p = entry bytes; hi = the entry's high byte for TK_SPLIT
uint32_t tableTarget(const JumpTable &t, const uint8_t *p, int hi = -1);
bool analyze(const Image &img, const Hints &h, const AnalyzeOptions &o, Decoder &dec, Analysis &out);
}
