# dumpapple

Thanks to **Kelvin Sherlock** ([ksherlock](https://github.com/ksherlock)), who let us use
his `itty-bitty-vtty` VT100 program and its source as a private test file
(not included in this repository)
([permission](https://github.com/ksherlock/itty-bitty-vtty/issues/2#issuecomment-6306044028)).
dumpapple's byte-identical rebuild was first checked against real code using it.

A game-agnostic Apple II / IIgs (6502, 65C02, 65816) reverse-engineering tool: it loads OMF
load files or raw binaries, follows control flow with M/X/E width tracking,
and writes a **ca65 (cc65) listing that rebuilds byte-identical** with
ca65 + ld65. Sibling of [dumpexe](https://github.com/EdgeOfAssembly/dumpexe)
(DOS/Windows). It follows the same rules as dumpexe but shares no code with it:

* Every listing must rebuild byte-identical. `--verify` checks it.
* Gold listings, round-trip tests and fuzzing guard regressions.
* Knowledge you supply (entry points, widths, names, data ranges) goes in a
  hints file, never in the tool.
* No game-specific tricks.

## Build

    git clone https://github.com/EdgeOfAssembly/dumpapple && cd dumpapple && make

Needs a C++20 compiler, Capstone **>= 6.0.0 Alpha11** (W65C816 LONG_M/LONG_X
modes) and cc65 (`ca65`/`ld65`) for `--verify` and the tests. Capstone comes
only from `CAPSTONE_PREFIX` (default `~/.local`, static `libcapstone.a`) for every
target, including `dumpapple-asan` and the fuzzer. A system Capstone 5 is never
used, and an older or missing Capstone stops the build with an error.
To build Capstone 6 into `~/.local` (from a Capstone 6.0.0 Alpha11 or later
source tree):

    cmake -B b -DCMAKE_INSTALL_PREFIX=$HOME/.local -DCAPSTONE_BUILD_SHARED_LIBS=OFF && cmake --build b --target install

The tests also need `python3` (generators in `tests/*.py`) and `da65` (from
cc65) for the cross-check.

    make                         # CAPSTONE_PREFIX defaults to ~/.local
    make CAPSTONE_PREFIX=/opt/capstone6
    make test                    # round trips, gold sets, OMF loader, da65 cross-check
    make fuzz FUZZ_RUNS=20000    # ASan/UBSan harness (libFuzzer with FUZZ_ENGINE=libfuzzer + clang)
    make fuzz-roundtrip FUZZ_ITERS=300   # random images must rebuild byte-identical

Capstone note: Capstone 6.0's `cs_open` rejects plain `CS_MODE_MOS65XX_65816`
(8-bit M/X), but it accepts `..._LONG_M`, `..._LONG_X` and `..._LONG_MX`.
dumpapple therefore opens a LONG_M handle (m16/x8) and a LONG_X handle (m8/x16).
Each instruction depends on at most one of M and X, so it is decoded with the
handle whose width matches the current state. `tests/gen_allops.py` checks
this. It builds every opcode in all four width states and checks the lengths
against its own table built from the WDC data sheet. ca65 then checks the
encodings.

## Usage

    dumpapple PROG.SYS16 -o prog.s --verify          # OMF (autodetected)
    dumpapple --org 2000 --cpu 65816 --state e code.bin -o code.s
    dumpapple --org 0800 --cpu 6502 apple2.bin -o a2.s          # 8-bit CPUs
    dumpapple --cpu 65816 --entry 2000:m16x16 --entry 3000:e x.bin
    ca65 --cpu 65816 -t none -o prog.o prog.s && ld65 -C prog.cfg -o prog.bin prog.o

Running it with no arguments prints usage and exits 0. Full option list:
`dumpapple --help` or `man -l man/dumpapple.1`. `dumpapple --version` prints
the version.

Exit status: 0 success (also no arguments, `--help`, `--version`); 1 cannot
read the input or hints, bad OMF, empty input, image out of range, write
error, `--hints-lib` not found; 2 usage error (unknown option, missing or bad
argument, more than one FILE, options without FILE); 3 `--verify` failed (the
rebuild did not assemble/link or differs; the work dir
`/tmp/dumpapple-verify-XXXXXX` is kept).

* **OMF**: v1 and v2 load files. The supported records are CONST, LCONST, DS,
  RELOC, cRELOC, INTERSEG, cINTERSEG, SUPER (RELOC2, RELOC3, INTERSEG1–36) and
  END. Segments are loaded at `--base` (default `$020000`), one bank apart
  (`--stride`). A segment with ORG set is loaded at ORG. `segbase` hints
  override both. Relocations are applied. The rebuilt image is the
  concatenation of the relocated segments in file order; `--dump-image`
  writes the same bytes.
* **CPU** (`--cpu 6502|65c02|65816`; default 65816 for OMF; raw input is
  auto-detected, see below):
  each CPU has its own decode path (Capstone `CS_MODE_MOS65XX_6502`,
  `_W65C02`, `_65816_LONG_M/_LONG_X`) and its own `.setcpu` (`"6502"`,
  `"65C02"`, `"65816"`). `65c02` (aliases `w65c02`, `r65c02`) is
  the WDC W65C02S, which has RMB/SMB/BBR/BBS (the Rockwell bit ops) plus
  WAI/STP. A Rockwell program uses a subset of the same encodings, and ca65's
  `65C02` accepts all of them. Only early non-Rockwell 65C02s (such as the one
  in Apple's enhanced IIe and the IIc) run `$x7`/`$xF` as NOPs; decoding
  does not model those parts.
  * Raw input without `--cpu`: the file is decoded from the entry as a 65816
    starting in emulation mode (how a 65C02 would run it). If that flow runs a
    65816-only instruction (`brl`, `jsl`, `jml`, `rtl`, `rep`, `sep`, `clc; xce`,
    `phb`/`plb`, `phd`/`pld`, `phk`, `tcd`/`tdc`, `tcs`/`tsc`, `txy`/`tyx`,
    `xba`, `mvn`/`mvp`, `pea`/`pei`/`per`, `jsr (abs,x)`), the CPU is 65816;
    otherwise 65c02. One control or mode instruction (`brl`, `jsl`, `jml`,
    `rtl`, `rep`, `sep`, `clc; xce`) is enough; the others need at least three,
    and an instruction inside a run of text bytes (ASCII or high ASCII) does
    not count. A hit counts only where a 65C02 decode of the same flow reaches
    the same address as an instruction start, falling into it or arriving via
    an edge the 65C02 decode also has (an entry, a jump table it uses): a
    decode that slips after a length-differing opcode (BBR/BBS 3 vs 4 bytes,
    `$x3` 1 vs 2), a jump into an operand, or flow into data the 65C02 decode
    never reaches is no evidence. Where the decodes part at a `$xF` long
    instruction (4 bytes on a 65816, BBR/BBS 3 on a 65C02), both readings are
    compared: a key instruction within 8 instructions on the 65816 reading
    (no brk/cop/wdm on the way) counts only if the 65C02 reading breaks within
    8 instructions (brk, an undefined opcode, a branch or jump off the image or
    into the middle of an instruction); a 65C02 reading that carries on validly
    (`bbr7 $C0,w; cpx #$E2; beq w`) vouches nothing. When the first such hit
    is one of the weak class, brl/jsl/... found after it count only if that
    hit is not among text (under 6 of 9 text bytes) and the 65816 reading runs
    from it to the key and 4 instructions on without brk/cop/wdm, sizing
    immediates by m/x as tracked through rep/sep (rep widens only in native
    mode; carry and E are tracked through clc/sec/xce and every carry-writing
    instruction, both starting unknown; with `--platform prodos8` E starts in
    emulation, as ProDOS 8 launches SYS/BIN files that way); after xce of
    unknown mode or plp outside emulation a width is unknown and either size
    may pass, with at most 4 such splits on a path (known limit: a fifth can
    only make it miss 65816 code) (`phk; plb; rep #$30; lda #$0001` counts
    (without `--platform prodos8`), a data file's `mvp ... jsl ... brk` does
    not); weak hits mostly surrounded by text do not count. A brk or a stop on
    an undefined 65C02 opcode that is not 65816-only ends the evidence. The
    probe ignores `--strict-smc`, so both modes pick the same CPU. On a 65C02
    these encodings are NOPs, so a 65C02 program
    does not run them. Not evidence: COP/WDM (`$02`/`$42`, 2-byte NOPs on the
    65C02), `xce` without `clc` right before it, long or stack-relative operands
    alone (`$x7`/`$xF` are RMB/SMB/BBR/BBS), and bytes off the flow (data after
    `rts`, behind an unresolved `jmp (ind)`). An image above `$FFFF` is 65816.
    The header says `; cpu: 65816 (auto: 65816-only brl at $2000 ...)`;
    `--cpu` overrides. Tests: `tests/cpu_auto/` (`tests/test_cpu_auto.sh`).
  `w65c02` and `r65c02` are accepted as aliases of `65c02`; `65c816` and
  `w65c816` of `65816`. CPU names are case-insensitive. The decoder also
  accepts WAI/STP, which a Rockwell part does not have.
  Capstone reports undefined 65C02 opcodes as multi-byte NOPs. ca65 cannot
  assemble those, so they end flow and are listed as data. 6502 and 65C02
  images must fit in $0000–$FFFF. Independent per-CPU length tables live in
  `tests/gen_allops.py` (65816: 256 opcodes × 4 width states) and
  `tests/gen_allops_8bit.py` (6502: 151 opcodes, W65C02S: 212). Every opcode
  round-trips through ca65.
* **Jump tables and dispatch** (switch off with `--no-tables`):
  * `jmp (abs,x)` and `jsr (abs,x)` read word tables in the program bank.
  * `jmp (abs)` reads a word pointer, and `jml [abs]` a long pointer, from
    bank 0.
  * The push-address-minus-1 patterns are followed: `pea v; rts`,
    `phk; pea v; rtl`, `lda #v16; pha; rts` and
    `lda #>v; pha; lda #<v; pha; rts`.
  * The table-length heuristic accepts consecutive entries while each target
    is in the image (and in the same segment for word tables), decodes in the
    current width state, and does not point into the table, into data or into
    the middle of an instruction. It stops at a label, at decoded code, at
    another table or table operand, or when the OMF relocation pattern
    changes. A table holds at most 256 entries.
  * Every table is listed with a comment giving its source, its size, its user
    and why the heuristic stopped. Entries are emitted as
    `.word .loword(L)`, `.word .loword(L-1)` or `.faraddr L`.
  * The heuristic is iterated to a fixpoint. If code, a label or another
    reference later reaches into an auto table, the table is cut before that
    entry and the analysis runs again (stop reason "code reached later at
    ..."). Flow that is refused because it runs into data or a hinted table
    is noted.
  * On the NMOS 6502, `jmp ($xxFF)` takes its high byte from `$xx00` (the
    page-wrap bug), and dumpapple follows that.
  * The hint `table ADDR COUNT [word|long|rts] [STATE]` overrides the
    heuristic. Overlapping table hints are rejected with a warning. Without a
    STATE, the hint uses the state at its jump site (the first decoded
    `jmp/jsr (abs,x)` or `jmp (abs)` with that operand). It waits until such
    a site is decoded. If none ever is, it falls back to the entry state and
    a note says so.
* **Platform** (`--platform none|prodos8|gsos`; default gsos for OMF, none for
  raw input) adds generic ABI rules for inline parameters. Each rule that fires
  gets a listing comment.
  * `gsos`: `JSL $E100A8` (the GS/OS entry) is followed by a 2-byte call
    number and a 4-byte parameter-block pointer. They are emitted as
    `.word`/`.dword`, and the call returns past them. `JSL $E100B0` and the
    toolbox entry `JSL $E10000` have no inline bytes.
  * `prodos8`: `JSR $BF00` (MLI) is followed by a command byte and a 2-byte
    parameter-list pointer.
  * Other routines: use the hint `inline ADDR N` (applies to `jsr`/`jsl` to
    ADDR).
  * Parameter pointers that point into the image become labels
    (`params_ADDR`), emitted as `.word .loword(params_ADDR)` / `.dword params_ADDR`.
  * ProDOS 8 `QUIT` (MLI command $65) and GS/OS `Quit` (call $2029, P16
    $0029) return only when they fail: flow continues after their inline
    bytes with the carry set, so a `bcs` error path decodes and the code after
    it does not.
  * Calls that do not return. Their fall-through edge is removed everywhere
    (decoding, the flow graph, dominance, must-store and runs-once):
    - `noreturn ADDR` on a routine or a call site (the listing says `assumed
      by noreturn hint`). A hint is a claim, not proof: the whole analysis is
      run again with every hinted call taken as an ordinary returning call, and
      any `runs as` result that differs is tagged `(per noreturn hint)`. ROM
      no-return entries below are not hints and are not relaxed;
    - with `--platform prodos8`, `jsr` to the Apple II ROM entry points $FF59
      (OLDRST), $FF65 (MON), $FF69 (MONZ), $FA62 (RESET), $E000 and $E003
      (BASIC cold/warm start). This applies only while the ROM is provably
      mapped. If any decoded instruction may touch the language-card switches
      $C080-$C08F, the call stays ordinary and a note says why. That covers a
      read or write (`bit $C08B` and `lda $C081` count): a constant address in
      the range, an indexed base that reaches it, and any pointer,
      stack-relative or long-indexed access, an indirect jump whose pointer may
      lie in the range (`jmp ($C080)`, `jmp ($C000,x)`) or block move (with `tcd`/`pld`
      in the code, every direct-page access too).
      Slot ROM ($Cn00) is never in the list;
    - with `--platform gsos`, `_SysFailMgr` (`ldx #$1503` right before
      `jsl $E10000`, with no jump into the `jsl`).

    Anything else is an ordinary call unless a hint says otherwise.
* **Variable-length inline strings**: a routine that pulls its return address
  (`pla; sta P; pla; sta P+1`), steps past the JSR's off-by-one (`inc P`
  before the first read, or `ldy #1`), reads with `lda (P),y` until a
  terminator and returns through the advanced pointer (`pha; pha; rts` or
  `jmp (P)`) is detected automatically. The loop's branch gives the
  terminator: `beq` exit / `bne` loop = zero byte, `bmi`/`bpl` = the first byte
  with bit 7 set (or clear, by branch direction). Each call is then followed
  by a string that is listed as data, and flow resumes after the terminator.
  Without the off-by-one step the routine is not matched. For routines outside
  the image, use `inline ADDR z|hi|lo|len`. A length-prefixed form is also
  detected: the first inline byte read is kept (`sta N` or `tax`) and bounds
  the loop (`cpy N`, `dex/bne`). When the helper's body shows the skip
  (`cpy N / bcs` loop, extra `iny`s, return through `tya / adc P`), the block
  length comes from it: pointer increments + max(start Y, N) + extra
  increments, so N = 0 is handled as the helper really does it. Otherwise
  the block is the count + 1 bytes.
  Detection is tentative: if any call site has no terminator in reach, or a
  flow target or code label lands inside one of its blocks, the rule is
  dropped for that routine and the analysis is redone.
  Routines outside the image are never treated as inline automatically: when
  at least 3 decoded call sites are each followed by text + $00 (and no flow
  reaches those bytes), the listing only notes `suggested hint: inline ADDR z`.
  Those call sites are then treated as having an unknown return: flow stops
  after the call and the bytes stay undecoded `.byte` data (the call line says
  `unknown: possible inline data after jsr ADDR`). A branch, jump, table entry,
  or label reaching the bytes still decodes them (a relocated data word
  pointing there only gets a note: it is usually a data pointer); a decoded call
  site that is not text + $00 withdraws the suggestion and fall-through
  resumes everywhere (re-analysis until stable).
  `--no-auto-inline` turns detection and suggestions off.
  For 8-bit index helpers each call site is proven by emulating the helper
  once (other shapes too: the pointer copied to another zero-page pair,
  `(zp,x)` reads, a `tsx` / `lda $0101,x` frame; such a helper must be seen
  reading through its return address, otherwise the call is ordinary).
  Decimal mode is tracked along the flow (`cld`/`sed`/`plp`, `rep`/`sep #$08`):
  a site reached with D set or unknown is not resolved when the helper adds or
  subtracts, and a site that relies on D being clear at the entry point puts
  `; assumes decimal mode clear at entry` in the header. COUT ($FDED) is
  emulated as the stock routine only when nothing decoded can change CSW
  ($36/$37) or code: every write is classified (below) and misses CSW and all
  instruction bytes (self-modifying code), no indirect jump is unresolved, and the helper
  does not write CSW itself. The header then says `; assumes CSW hook preserves
  X/Y`; otherwise such sites get a note naming the store. A CSW store after
  the call still counts (ordering is not proven). Bytes reached only by
  falling through `jmp`/`rts`/... or a branch known to be taken are not code.
  Every `rts`/`rtl`/`rti` must also pop a caller's return frame: the stack is
  tracked symbolically from each subroutine entry (pha/pla/php/plp/phx/...,
  pea/pei/per/phd/phb/phk, tax/txa/tay/tya; paths that join with different
  stacks lose it), and the
  popped bytes must be one whole frame, never touched or pulled and pushed back
  unchanged and in order (`pla / pla / rts` returns to an outer caller and is
  fine; `pla / rts`, a net push, swapped bytes or a pushed computed address are
  an unresolved transfer). An `rti` always needs P plus a whole interrupt frame
  (3 bytes, 4 in 65816 native mode) and is never fine in a routine entered by
  `jsr`. A proven RTS table exempts only its own `rts`, where the pushed bytes
  come straight from the table loads; inline helpers' own returns are exempt;
  txs/tcs/tsc lose the stack.
  **One write classifier.** Every store and read-modify-write (sta/stx/sty/stz,
  inc/dec/asl/lsr/rol/ror on memory, tsb/trb, Rockwell RMB/SMB, 65816 long,
  `sta n,s`, `sta (n,s),y`, mvn/mvp) is classified once, from a whole-code
  dataflow state (A/X/Y as constants or ranges, e.g. X in 0..$3F in an
  `ldx #$3F / ... / dex / bpl` loop; DB from `plb` after `lda # / pha`, `phk`
  or mvn/mvp; D; S; known bank-0 bytes for pointers; patched immediates are
  unknown), into the set of 24-bit bytes it may write, or unknown; the
  stack-slot, CSW and self-modifying-code checks all use that set. Absolute
  uses DB (the 2nd byte of a 16-bit store at the next linear address, crossing
  into the next bank), long modes the operand's bank, direct page D in bank 0
  (emulation with DL=0 wraps in the page, also for pointer fetches), indexed
  modes the index value or range, indirect modes the resolved pointer,
  stack-relative S (page 1 in emulation mode); mvn/mvp write dstbank:Y..Y+C
  (mvp Y-C..Y) wrapping in the bank, the whole bank when Y or C is unknown.
  65816 writes are 2 bytes when m=0 (x=0 for stx/sty) or the width is unknown;
  on the 6502/65C02 addresses wrap at $FFFF. A write in the live stack (above
  S, up to the S set by `ldx #n / txs`; S carried into subroutines through their
  jsr sites) loses the frame; when S is unknown, on 8-bit platforms all of page
  1 except $0100-$013F (a common scratch buffer) is live. With `--platform
  gsos`, an OMF (S16) load or a native-mode entry, D and S are unknown at entry
  and may be anywhere in bank 0: there is no $0100-$013F carve-out, any bank-0
  write not placeable relative to a known S (outside emulation mode, where S is
  in page 1) loses the frame, and a direct-page write with D unknown may hit CSW
  or code. An unknown D (`pld`, ...) is unknown on every CPU mode.
  Two relocation shapes are exempt: a run-once `ldx #N / ldy #0 / lda S,y /
  sta D,y / iny / bne / inc / inc / dex / beq` loop at the image start that
  copies N pages onto the image's own base, and the same copy through two
  zero-page pointers set up by `lda #` / `sta zp` (`lda (p),y / sta (q),y /
  iny / bne / inc p+1 / inc q+1 / dex / bne`), whose store then writes just
  those pages. Listed at its load address S
  instead, the loop gets a note proposing `--org D`. A store to one exact
  address (absolute, or a resolved pointer with known Y) that lands only on
  the operand of a decoded immediate instruction (`lda #`, `adc #`, `cmp #`,
  ...; on 65816 with m/x known) is also allowed: that operand is then unknown
  everywhere (pointer resolver, helper emulation, table bounds), and a helper
  whose own immediate is patched is left as an ordinary call. Any other store
  that may hit code also stops the emulation of a helper whose bytes it may
  change, with or without COUT, and flow that reaches undecodable bytes (e.g.
  65816 width unknown) makes COUT untrusted, as do an rts/rtl/rti after pushes
  in its block (return-address dispatch) unless a proven RTS table belongs to
  it, and 65816 `tcs` / native `txs`. The relocation exemption needs the copy source
  outside the listed image. No input routine (KSW $38/$39) is trusted. An indexed store to an
  unknown address that may reach the image also stops the proof.
  Known gaps: a jsr into the middle of a helper, and 65C02 `(zp)` code under
  `--cpu 6502`, are left as plain calls (no false return is claimed, the bytes
  after them decode as code). D, DB and S changed inside a subroutine are not
  carried back to its callers (a GS/OS helper whose D is set by an earlier call
  is still taken as D unknown); `sta (n,s),y` is always unknown, and `pld` is
  known only when the two pulled bytes come from known pushes (up to four D values).
* **RTS/RTL dispatch**: `lda T+1,y / pha / lda T,y / pha / rts` (or `,x`), the
  split form `lda HI,y / pha / lda LO,y / pha / rts`, a 16-bit `lda T,x / pha /
  rts`, and on the 65816 `rtl` with three byte pushes (T+2, T+1, T) or with
  `phk` and a word/split push. Instructions that change neither A, the index
  nor the stack may sit between the loads and pushes; after the last push,
  register loads and transfers are allowed too. Each entry + 1 is a code entry.
  An index guard bounds the table: a constant index (`ldx/ldy #k`) or a
  `cmp/cpx/cpy #N` + `bcc/bcs` on the straight-line path before the loads.
  An unguarded RTS table needs at least 2 entries.
  The table ends under the usual auto rules (code, label, load-read address,
  other table, clean decode of every entry); split halves are bounded
  together. Entries are listed as `.word L-1` (`.faraddr L-1` for rtl) or as
  `.byte <(L-1)` / `.byte >(L-1)` runs. Hints: `rtstable ADDR N [STATE]` and
  `rtstable split HI LO N [STATE]`.
* **Single-byte BRK**: when a branch, jump or call lands on the signature
  byte of a BRK that ends flow, the BRK is listed as `.byte $00` and the
  target is decoded. A table entry pointing there does not count: such an
  entry stops the auto table.
* **Branches on known flags**: the decoder tracks C, Z, N and V per path.
  `clc`/`sec`, `clv`, `sep`/`rep` and `lda`/`ldx`/`ldy #imm` (Z and N, only
  when the register width is known) set them; stores, pushes and `nop` keep
  them; any other instruction, a call, `plp`, `rti` and a join of paths that
  disagree make them unknown. A conditional branch whose flag is known on
  every incoming path is followed on the taken side only (always taken) or
  the fall-through only (never taken); the other side's bytes are code only
  if something else reaches them. Flags are never taken from bytes a store
  may change: an instruction that any store may patch (an exact store, or a
  store whose target range covers it) leaves every flag unknown for branch
  decisions, whatever it currently decodes as, and a branch that may itself
  be patched stays two-sided. The same applies to widths on the 65816: if a
  store with a bounded target set (a known base plus an index, whose unknown
  range counts as base..base+$FF, or +$FFFF when X/Y are 16-bit or of unknown
  width; a known D set; a resolved pointer range) may reach an instruction's
  opcode byte, or any byte of a `rep`/`sep`, then e, m and x after it are
  unknown (the byte could become a `sec` before an `xce`, a `rep`/`sep`
  operand could change, or the opcode could become `xce`/`plp`/`rep`/`sep`),
  and nothing width-dependent is decoded until a `rep`/`sep`/`xce` with
  trusted inputs sets them again. A store that only reaches the operand of
  another instruction leaves the mode alone.
  A store whose target is fully unknown (an unresolved `(dp),y`/`[dp],y`
  pointer, or a dp store with D unknown) is by default assumed not to modify
  code: the header says `; assumes stores with unknown targets do not modify
  code` and each such store is marked `; unknown-target store (assumed not
  to modify code)`. The assumption covers code and width decoding only; the
  same stores still make return frames unresolved, COUT $FDED untrusted and
  inline-string helpers unproven (a note lists those reasons).
  `--strict-smc` drops the assumption: such stores may modify any code.
  It is the worst-case mode: on real programs with even one store through an
  unresolved pointer it proves almost nothing (decoding stops at the entry
  point; a real 65816 program decodes 0 bytes), so use it to check a claim, not to
  disassemble.
  A bounded store whose possible range covers a whole 64K bank (for example
  `sta $1D00,x` with a 16-bit X of unknown value, or `sta f:$000000,x`) is
  treated as fully unknown in the same way.
  The set of possibly modified bytes is a greatest fixpoint: analysis starts
  with every byte trusted, and each pass recomputes all store ranges (index
  ranges, D sets and pointers) from that pass's own decode, marks every
  reachable byte untrusted and repeats until a pass reproduces exactly the set
  it started from (capped at 40 passes; then the older accumulating method is
  used). Every decoded byte (opcode, operands, branch offsets) is checked: a
  store that can hit a branch or jump operand makes that target unknown, and
  one that can hit another store's address operand makes that store
  unknown-target. Counted loops (`ldx #imm` falling into a straight-line body
  ending in `dex`/`inx` steps and `bpl`/`bne` back) narrow X to the values
  the loop really takes, so `stz 0,x` with `ldx #254; ... dex; dex; bpl`
  writes only D+0..D+255. When a store writes a known value (an exact
  `sta`/`stx`/`sty`/`stz` of a known register, or a short `mvn`/`mvp` from
  bytes nothing else writes) and both the old and new opcode are flag-only
  one-byte instructions (`nop`, `clc`, `sec`, `cli`, `sei`, `clv`, `cld`,
  `sed`), the M/X widths are kept.
  Direct-page targets use the set of D values on every path
  (up to four, from `tcd`/`pld` of `pea` or immediate values), so a known D
  does not widen a `sta dp` to the whole bank.
  Instructions that run only before any store can have run (straight-line
  flow from the single entry point, reached by nothing else, up to the first
  instruction that writes memory, branches, calls or returns) are exempt; this
  is kept only when the final pass has fully known flow (no stopped decoding,
  unresolved indirect jump or call left undecoded after it).
  The skipped side of an
  always-taken branch may still contain bytes a store changes (as in a
  relocator's `sec; bcs` over its own patched data); those bytes are left
  as data unless other flow reaches them.
  **Patched bytes.** For every byte a store may change, the possible values are
  collected. With exactly one known value (an exact store of a known register,
  `stz`, or a short `mvn`/`mvp` from bytes nothing else writes), the patched
  instruction is decoded with its full semantics: its length, flags, widths
  (`xce`, `plp`, `rep`/`sep`, `xba`, `tcd`, ...), branch target and successors;
  the listing says `; may also run as <insn> (bytes)`. With an unknown value
  or several values, decoding stops at that instruction. The default is the
  union: the original instruction keeps its own successors and the patched form
  adds its own. The original is replaced (`; changed by a store before it runs:
  runs as ...`) only when the store is proven to dominate every path to the
  byte. This is a must-store dataflow over the decoded flow graph from every
  entry point. A `jsr` continues with the callee's summary: the stores that run
  on every path from its entry to each of its returns, so a store in a
  subroutine called before the byte counts. Dominance needs fully known flow
  (every reason counts, not only the first one named: an rts-trick return
  anywhere is a computed edge). When the order cannot be proven, decoding stops
  at the byte instead of keeping the original form:
  - the byte would be dominated, but flow is not fully known;
  - the store may run inside a callee with no summary (no return found, or an
    unresolved indirect call).

  Incomplete flow elsewhere does not block the proof. When every point where
  flow leaves the known graph runs only after all stores to the byte, the
  unknown edges cannot reach the byte in its original form, and only the
  patched form is decoded. Those points are an unproven call continuation, a
  computed return or a decode stop. This is how a store in the caller that
  patches an inline-string helper is decoded; only the helper's own return
  stays unknown. A patched form that is shorter than the original and falls
  through is never proven (the code it runs would start inside the listed
  instruction).
  The union stays only when a path that misses the store exists, or when every
  form has the same length and none changes flow, the stack or the widths (the
  original form then makes no other byte code).
  Stores whose range is wider than four bytes (indexed with an unknown index,
  long or unknown-length block moves) write an unknown value: decoding stops at
  every byte they may reach, opcode or operand. The one exception is the operand
  of a `rep`/`sep`, which stays a width setter that leaves e/m/x unknown. Under
  `--strict-smc` a store with a fully unknown target reaches every byte, so it
  stops decoding everywhere (sound, but large images may decode very little).
  The fixpoint is monotone: once a pass finds a store that reaches a byte, later
  passes keep it, so an untrusted byte never becomes trusted again. The same
  holds for the other verdicts: COUT/CSW at risk, a byte found not dominated, an
  order found unknown, revoked helpers, and truncated tables (which only
  shrink). The suite checks that every gold image settles below the 40-pass cap
  (`DUMPAPPLE_PASSES=1` prints the pass count).
  **Read-modify-write on code** (`asl`/`lsr`/`rol`/`ror`/`inc`/`dec`/`tsb`/
  `trb`/`rmb`/`smb` on one exact byte) gives one known value (computed from the
  encoded byte; `rol`/`ror` only with a known carry, `tsb`/`trb` only with a
  known 8-bit A) only when the instruction provably runs once. That means:
  - it is on no cycle of the decoded flow graph (a return may go to every call
    continuation);
  - the code before it is entered from one place only: at most one `jsr`/`jsl`,
    the image's only entry point, and no jump-table, computed or indirect
    target, and no entry point also reached by other flow;
  - no other store reaches the byte;
  - flow is fully known.
  Otherwise the result is an unknown value and decoding stops there.
  **Table narrowing** (CSW and frame checks): `lda`/`ldx`/`ldy tbl,x|y` with an
  8-bit destination, a known DB and an index range that stays inside the table
  gives the register the min..max of the table bytes, but only when no store in
  the same fixpoint pass can reach the table (default mode ignores stores with
  unknown or whole-bank targets, as above). `cmp`/`cpx`/`cpy #N` followed by
  `bcc`/`bcs` narrows the register on each edge (unsigned). On ProDOS 8 (not
  GS/OS) DB starts at 0, and DB, like D, is carried into subroutines.
  **Bank wrap (65816):** the program counter wraps inside the program bank, so
  an instruction at $xx:FFFE takes its operand bytes from $xx:0000 and the next
  instruction after $xx:FFFF is $xx:0000. Such an instruction cannot be written
  by ca65 and is listed as `.byte` of its in-bank bytes with the decoded form as
  a comment (`; 7F/FFFE: AD 34 12 lda a:$1234 (operand wraps to $7F/0000)`); a
  branch whose target is in another 64K window is listed the same way.
* **Immediate code pointers**: `lda #<x` with `ldx #>x` or `ldy #>x` (either
  order), or `ld? #a; st? p; ld? #b; st? p+1` with the same register (either
  byte first), makes x a code entry when x decodes cleanly to a terminator
  (rts/rti/rtl/jmp) without BRK, data or a mid-instruction overlap, does not
  start with a text or zero run, and follows a terminator (`rts`, `rti`,
  `jmp`, `bra`, or a conditional branch known to be taken) or the image start. `--no-imm-pointers` turns this off.
* **Auto table ends** (in addition to code, labels and other tables): an
  entry that an ordinary absolute load reads (`lda`/`ldx`/`ldy`/`cmp`/...
  abs), or that is the base of an indexed load. When a later-found dispatch
  site's table starts inside an auto table, that table is split there and each
  part keeps its own site.
* **Load map for raw input**: `region FILEOFF LEN ADDR` in the hints file lists
  file bytes FILEOFF..FILEOFF+LEN-1 at ADDR (code copied elsewhere and run
  there); the rest stays at `--org` + file offset. Regions must not overlap in
  the file or in memory. The rebuild stays byte-identical.
* **Misdecode guard (OMF)**: a relocated field must lie entirely within an
  instruction's operand bytes, at any offset and size. MVN/MVP 1-byte bank
  fields at +1 and +2 are legal. A field that covers the opcode byte or
  crosses the instruction's end means the bytes are not code: the decode is
  dropped and they are listed as data with the reason. `.byte` lines never
  split a relocated field; the line breaks before it.
* **OMF entry points**: as with the GS/OS loader, only the ENTRY of the
  first static code segment seeds code flow. A segment does not seed flow if
  its type is data, jump table, DP/stack or anything else non-code, or if its
  KIND has the dynamic bit $8000 set. `--seg-entries` adds the ENTRY of every
  other static code segment (`--no-seg-entries` restores the default). This is a
  deliberate opt-in exception to "maximum analysis by default": a heuristic: a segment marked as code
  may hold data, and its ENTRY (often +0) is then decoded anyway. In one real
  program it lists a false `rts` at a music segment's entry. The default output is the
  reliable one; use `entry` hints for code the default does not reach.
* **OMF jump-table segment** (KIND $02): read as in the GS/OS Reference. After
  an 8-byte zero header come 14-byte entries: user ID, load-file number and
  load-segment number (words), segment offset (dword), and an unpatched JSL to
  the loader (4 bytes). A load-file number of 0 ends the list. For load file 1,
  each (segment, offset) pair becomes an entry point, dynamic segments
  included. The table is listed as data: `.word`/`.word`/`.word`/`.dword` plus
  the JSL as `.byte`, with each entry labelled `jt_ADDR` and a comment naming
  the target label. It is never decoded as code.
* **~ExpressLoad** is always data: no code flow starts in it or enters it.
* **Overlaps**: when two real entry points overlap (the BIT-skip idiom
  `sec; .byte $24; clc`), the listing keeps the lower one, notes
  "overlapping entry point", and emits the other label as an equate.
* **COP/BRK**: both are 2 bytes (opcode + signature). COP returns past the
  signature (RTI), so flow continues. BRK ends flow unless a `returns ADDR
  STATE` hint names that BRK.
* **Width tracking**: REP and SEP set the widths. CLC/SEC followed by XCE
  switches emulation mode. PHP and PLP keep a small shadow stack. At join
  points the states are merged; a conflicting flag becomes *unknown*. An
  M- or X-dependent immediate seen with an unknown width stops decoding at
  that point: the bytes become data and a comment says why. The tool does not
  guess. A call is assumed to return with the caller's state unless a
  `returns` hint says otherwise.
* **Listing**: `.a8/.a16/.i8/.i16` appear at every width change. Each segment
  gets `.segment` and `.org`. Operands carry explicit `z:`/`a:`/`f:` sizes.
  Branch, call and jump targets get labels; JSR/JMP use `.loword(label)`.
  A branch that wraps within its bank, which ca65 cannot express, is emitted
  as `.byte`. Data is `.byte`, printable ASCII becomes `"strings"`, and zero
  runs become `.res`. High-bit ASCII (`$A0-$FE`, optionally ending in one
  byte with bit 7 clear) is shown as hex with the decoded text in a comment.
  `word` hints emit `.word`. Relocated fields are marked `[reloc ...]` in the
  comments.

## Platform hint libraries (`hints/`)

Hint files for documented platform interfaces ship as data in `hints/`, never
as code paths in the analyzer. Load one explicitly with `--hints-lib NAME`
(looked up in `$DUMPAPPLE_HINTS`, then `hints/` next to the binary, then
`/usr/local/share/dumpapple/hints`), or pass its path with another `--hints`.
`--hints` may be repeated; files are read in order. Nothing is enabled by file
name, hash or content.

* `davex.hints`: the Davex 1.x shell vectors at $B000-$B07B that external
  commands call, with names, `inline $B006 z` (xmess) and `noreturn` for
  xProDOS_err ($B042) and xerr ($B048). Sources are cited in the file. It
  describes external commands, not the shell file itself.

## Hints file

    entry   $021000 m16x16     # code entry (state: e m8x8 m8x16 m16x8 m16x16)
    state   2:0040 m8x16       # force width state at an address (SEG:OFF works for OMF)
    returns $02100D m16x16     # calls to this routine come back in this state
    noreturn $021200
    data    $021036 6          # never decode as code
    word    $021036 6          # data, emitted as .word
    name    $021036 jtab
    comment $021000 program start
    segbase 3 $060000          # OMF: load segment 3 at $060000
    table   $021036 3 word m16x16  # jump table: 3 entries (word | long | rts), optional state
    inline  $021200 3          # calls to $021200 are followed by 3 inline bytes
    returns $021300 m16x16     # also: a BRK at $021300 returns (continues after its signature)
    region  0 $100 $0300       # raw: file bytes 0..$FF run at $0300
    rtstable $2100 8 [STATE]   # rts dispatch table: 8 words, each target-1
    rtstable split $2200 $2210 8   # split rts table: high bytes, low bytes, count
    inline  $FDxx z            # string helper: z|hi|lo|len

## Known gaps

* CPU auto-detect: Rockwell bit-op code (BBR/BBS/RMB/SMB) followed directly
  by bytes that also read as valid 65816 code may mislead auto-detect; use
  `--cpu`.
* CPU auto-detect: 6502 code built on purpose to look like 65816 (weak
  opcodes on agreed boundaries running cleanly into a rep/sep) still picks
  65816; use `--cpu`.
* Jump tables through computed pointers are not followed; split lo/hi RTS
  tables are detected (see RTS/RTL dispatch). Inline parameters are known from
  the platform rules, auto-detected string helpers and `inline` hints. Add
  `entry`, `table` or `inline` hints for the rest. A wrong guess can mislabel
  bytes, but the rebuild stays byte-identical, and every guess is commented.
* BRK ends flow unless a `returns` hint names it; COP continues after its
  signature byte; `noreturn` routines end flow.
* Data references (`lda abs`) stay numeric; only code and PER targets get
  labels. DB/D/S are tracked for write classification only.
* CPU auto-detect: the clean-run check splits on at most 4 unknown-width
  immediates per path; past that it can only miss 65816 code (pick 65C02),
  never pick 65816 wrongly.
* OMF: only load-file records are accepted; object/library records such as
  EXPR are rejected. ExpressLoad segments are loaded and listed as plain data (never code).
  Interseg references to other files (file ≠ 1) are left unpatched and
  reported. The SUPER INTERSEG1–12 encoding (segment number in the third byte
  of the patch site) follows the GS/OS reference and has only been tested
  against fixtures built here.
* The dispatch fixtures (`tests/gen_disp.py`: disp, disp2, OMF variant) rebuild
  byte-identical. Their coverage is pinned in `tests/baseline/coverage.txt`.
* da65 2.18 has no 65816 mode, so the da65 cross-check covers only the
  8-bit (65C02-compatible) program.

## References

dumpapple's behaviour is based on the published documentation below. Where
the tool makes an assumption, the listing header says so.

**CPU**
- Western Design Center, *W65C816S 8/16-bit Microprocessor* data sheet:
  opcodes, emulation/native modes, `rep`/`sep`/`xce`, bank wrap rules,
  `mvn`/`mvp`.
- David Eyes & Ron Lichty, *Programming the 65816* (Brady/Prentice Hall, 1986).
- Rockwell R65C00/R65C02 data sheets: `rmb`/`smb`/`bbr`/`bbs`. Apple's
  enhanced IIe/IIc 65C02s lack these.

**Apple II / ProDOS 8**
- Apple Computer, *Apple II Reference Manual* (1978/1979): Monitor COUT
  (`$FDED`) and the CSW output hook (`$36/$37`).
- Apple Computer, *ProDOS 8 Technical Reference Manual* (1985/1987): MLI
  calling convention (`jsr $BF00` + 3 inline bytes), QUIT (`$65`), and the
  emulation-mode launch of SYS/BIN files (the `--org` default `$2000` follows
  the SYS load address).

**Apple IIgs / GS/OS**
- Apple Computer, *Apple IIgs Toolbox Reference*, Vols. 1-3: tool dispatcher
  (`jsl $E10000`).
- Apple Computer, *GS/OS Reference* (1988/1989): OS calls through `$E100A8`,
  Quit; the S16 launch state is treated as D and S unknown.
- Apple Computer, *Apple IIgs Technical Notes* (OMF).

**Thanks**
- Kelvin Sherlock, who gave permission to use *itty-bitty-vtty* (vt100) as a
  private test file (not included in this repository;
  ksherlock/itty-bitty-vtty, issue #2).

## Disclaimer

dumpapple is an independent open-source project. It is not affiliated with,
sponsored by or endorsed by Apple Inc. "Apple", "Apple II", "Apple IIgs",
"ProDOS" and "GS/OS" are trademarks of Apple Inc. They are used here only to
describe the systems the tool works with.

dumpapple ships no Apple ROMs, system software or commercial programs. You
must supply your own files and have the right to analyse them.

## License

dumpapple is free software, licensed under the GNU General Public License,
version 3 or (at your option) any later version (GPL-3.0-or-later); see
[LICENSE](LICENSE). Copyright (C) 2026 EdgeOfAssembly.

Kelvin Sherlock's `itty-bitty-vtty`, used as a private test file, is not
included in this repository and is not covered by this license.
