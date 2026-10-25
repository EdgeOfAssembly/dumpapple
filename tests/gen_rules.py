#!/usr/bin/env python3
"""Synthetic repros for the gold-set rules (no gold-set bytes): variable-length
inline strings, table ends at loads, table splits, no-return OS calls,
immediate code pointers, multi-region raw load maps.  Writes tests/progs/rules_*.bin
and their hints files."""
import os, sys
D = sys.argv[1] if len(sys.argv) > 1 else 'tests/progs'
def put(name, org, parts, size=None, hints=None):
    img = bytearray(size or 0)
    for a, b in parts:
        o = a - org
        if len(img) < o + len(b): img.extend(bytes(o + len(b) - len(img)))
        img[o:o + len(b)] = bytes(b)
    open(os.path.join(D, name + '.bin'), 'wb').write(img)
    if hints is not None: open(os.path.join(D, name + '.hints'), 'w').write(hints)
H = lambda s: bytes.fromhex(s.replace(' ', ''))
# 1. variable-length inline strings ($2000, 6502)
put('rules_var', 0x2000, [
    (0x2000, H('201020') + b'HI\0'),                  # jsr mess ; "HI",0
    (0x2006, H('204020') + H('48C9')),                 # jsr hmess ; "H","I"|$80
    (0x200B, H('207020') + H('60')),                   # jsr notinline ; rts
    (0x2010, H('6885F06885F1A000E6F0D002E6F1B1F0F006 20EDFD 4C1820 A5F148A5F04860')),   # pla/sta/inc/lda (p),y/beq
    (0x2040, H('6885F26885F3A000E6F2D002E6F3B1F23003 4C4820 A5F348A5F24860')),            # bmi: ends at bit 7 set
    (0x2070, H('6885F46885F5A000B1F4F000A5F548A5F44860')),                                  # no +1: not an inline routine
])
put('rules_varhint', 0x2000, [(0x2000, H('2006B0') + b'OK\0' + H('60'))], hints='inline $B006 z\n')
# 2. auto table ends where an ordinary load reads ($2000, 65c02)
put('rules_tblload', 0x2000, [
    (0x2000, H('7C0620')), (0x2006, H('0C20 1020 1420')),
    (0x200C, H('AD0A2060')), (0x2010, H('EA600000')), (0x2014, b'ABCDEFG\0')])
# 3. a second dispatch site whose base is inside an auto table splits it
put('rules_split', 0x2000, [
    (0x2000, H('A2007C0820EAEAEA')), (0x2008, H('1420 1820')), (0x200C, H('1C20 2020')), (0x2010, H('EAEAEAEA')),
    (0x2014, H('7C0C2060')), (0x2018, H('60000000')), (0x201C, H('60000000')), (0x2020, H('60'))])
# 4. no-return OS calls
put('rules_p8quit', 0x2000, [(0x2000, H('2000BF650003') + b'.SYSTEM')])
put('rules_gsquit', 0x2000, [(0x2000, H('22A800E1 2920 0C200000 0000 01000000'))])
put('rules_noret', 0x2000, [(0x2000, H('200820') + b'ABC\0' + H('0060'))], hints='noreturn $2000\n')
# 5. lda #<f / ldx|ldy #>f: f is code; the text pointer is not
put('rules_imm', 0x2000, [
    (0x2000, H('A918A2208DF2038EF303A928A02020EDFD60')), (0x2012, H('000000000060')),
    (0x2018, H('A9018500600000000000000000000000')), (0x2028, b'HELLO\0')])
# 6. region: bytes copied to $0280 and run there
put('rules_region', 0x2000, [(0x2000, H('A000B90E20998002C8D0F74C8002')), (0x200E, H('A9C120EDFD4C8002'))],
    hints='region $0E 8 $0280\n')
# 7. an external command calling the Davex shell vectors (for --hints-lib davex)
put('rules_davex', 0x9000, [(0x9000, H('2006B0') + b'OK\0' + H('2009904C48B0') + H('60'))], hints=None)
open(os.path.join(D, 'rules_noret2.hints'), 'w').write('noreturn $9006\n')
# 8. RTS/RTL dispatch through indexed tables
put('rts_word', 0x2000, [(0x2000, H('A002 B91120 48 8D0003 B91020 48 60 0000')),
    (0x2010, H('1620 1820 000000') + H('60 00 EA60'))])
put('rts_split', 0x2000, [(0x2000, H('A201 BD2020 48 BD1820 48 60')), (0x2018, H('2F33')), (0x2020, H('2020')),
    (0x2030, H('60000000EA60'))])
put('rts_tay', 0x2000, [(0x2000, H('A002 B91120 48 A8 B91020 48 60 0000')),
    (0x2010, H('1620 1820 000000') + H('60 00 EA60'))])
put('rtl_long', 0x2000, [(0x2000, H('A680 BD1220 48 BD1120 48 BD1020 48 6B 00')),
    (0x2010, H('1F2000 232000')), (0x2020, H('6B000000EA6B'))])
put('rtl_phk', 0x2000, [(0x2000, H('A200 4B BD1120 48 BD1020 48 6B')), (0x2010, H('1F20')), (0x2020, H('6B'))])
put('rts_16', 0x2000, [(0x2000, H('A200 BD1020 48 60')), (0x2010, H('1F20')), (0x2020, H('60'))])
put('rts_tail', 0x2000, [(0x2000, H('A002 B91120 48 B91020 48 A5A5 A4A4 60')),
    (0x2010, H('1620 1820 000000') + H('60 00 EA60'))])
# 9. single-byte BRK skipped by a branch; external routine always followed by a string
put('brk1', 0x2000, [(0x2000, H('9001 00 EA 60'))])
put('extstr', 0x2000, [(0x2000, H('201020 201820 202020 60')), (0x2010, H('200030') + b'AB\0' + H('60')),
    (0x2018, H('200030') + b'CD\0' + H('60')), (0x2020, H('200030') + b'EF\0' + H('60'))])
put('extjmp', 0x2000, [(0x2000, H('201020 201820 202820 202020 4C2320')), (0x2028, H('200030') + b'GH\0' + H('60')), (0x2010, H('200030') + b'AB\0' + H('60')),
    (0x2018, H('200030') + b'CD\0' + H('60')), (0x2020, H('200030') + b'EF\0' + H('60'))])
put('extstr2', 0x2000, [(0x2000, H('201020 201820 60')), (0x2010, H('200030') + b'AB\0' + H('60')),
    (0x2018, H('200030') + b'CD\0' + H('60'))])
# 10. reviewer r2 repros (B1/B3/B4) and the length-prefixed inline form
for nm, hx in [('a1_inline_code', '20edfda9c1d00020edfda9c1d00020edfda9c1d0004c0a20'),
               ('a2_mismatch', '2000fd48454c4c4f002000fd574f524c44002000fd414741494e002000fda90160'),
               ('a4_textbranch', 'a200f0152000fd48454c4c4f002000fd574f524c44002000fda9c1d00060'),
               ('b2_mismatch', '20182048454c4c4f00201820574f524c4400201820a901606885f06885f1a000e6f0d002e6f1b1f0f0034c2020a5f148a5f04860'),
               ('b4_textbranch', 'a200f00c20152048454c4c4f00201520a9c1d000606885f06885f1a000e6f0d002e6f1b1f0f0034c1d20a5f148a5f04860'),
               ('lenpref', '200d2003414243200d200144606885f06885f1a001b1f085f2c4f2b006c8b1f04c1920c8981865f085f0a5f1690048a5f04860'),
               ('r2_len1', 'a200bd0c2048bd0b2048600e200f2060a9ea60'),
               ('r8_brk', 'a2007c052009200c20a90100a9ff60'),
               ('lenhint', '200030024142200030014360')]:
    put(nm, 0x2000, [(0x2000, H(hx))])
# F1 reviewer repro c4/l1_zero: zero length, helper starts at y=1 and skips 2 bytes
put('len0', 0x2000, [(0x2000, H('200e2003414243200e2000a901606885f06885f1a001b1f085f2c4f2b006c8b1f04c1a20c8981865f085f0a5f1690048a5f04860'))])
# G1: carry into the return-address add (sec/clc/unknown) and the high-byte add
put('g1_sec', 0x2000, [(0x2000, H('200e2003414243200e2000a901606885f06885f1a001b1f085f2c4f2b006c8b1f04c1a20c8983865f085f0a5f1690048a5f04860'))])
put('g1_unk', 0x2000, [(0x2000, H('200e2003414243200e2000a901606885f06885f1a001b1f085f2c4f2b006c8b1f04c1a20c82a9865f085f0a5f1690048a5f04860'))])
# G1: carry known from the cpy N / bcs exit (no carry write before the adc), and a cmp that clobbers it
put('g1_bcs', 0x2000, [(0x2000, H('200e2003414243200e2000a901606885f06885f1a001b1f085f2c4f2b006c8b1f04c1a20c898ea65f085f0a5f1690048a5f04860'))])
put('g1_cmp', 0x2000, [(0x2000, H('200e2003414243200e2000a901606885f06885f1a001b1f085f2c4f2b006c8b1f04c1a20c9009865f085f0a5f1690048a5f04860'))])
put('g1_hi1', 0x2000, [(0x2000, H('200e2003414243200e2000a901606885f06885f1a001b1f085f2c4f2b006c8b1f04c1a20c8981865f085f0a5f1690148a5f04860'))])
put('g1_hisec', 0x2000, [(0x2000, H('200e2003414243200e2000a901606885f06885f1a001b1f085f2c4f2b006c8b1f04c1a20c8981865f048a5f138690048a5f04860'))])
# G1 review 736a187 HIGH-1: other paths join the loop exit (carry 0 there) -> carry unknown
put('g1_ft2', 0x2000, [(0x2000, H('200e2003414243200e2000a901606885f06885f1a001b1f085f2c4f2b005c8b1f010f7c89865f085f0a5f1690048a5f04860'))])
put('g1_merge', 0x2000, [(0x2000, H('200e2003414243200e2000a901606885f06885f1a001b1f085f218900bc4f2b006c8b1f04c1d20c89865f085f0a5f1690048a5f04860'))])
put('g1_merge_beq', 0x2000, [(0x2000, H('200e2003414243200e2000a901606885f06885f1a001b1f085f2f00bc4f2b006c8b1f04c1c20c89865f085f0a5f1690048a5f04860'))])
# a bne from the main code also targets the exit
put('g1_join2', 0x2000, [(0x2000, H('a5f3d0242012200341424320122000a901606885f06885f1a001b1f085f2c4f2b006c8b1f04c1e20c89865f085f0a5f1690048a5f04860'))])
# adc on the bcs fall-through (carry 0 path): the exit carry never applies
put('g1_bcs_ft', 0x2000, [(0x2000, H('200e2003414243200e2000a901606885f06885f1a001b1f085f2c4f2b00fc89865f085f0a5f1690048a5f04860c8b1f04c1a20'))])
# iny / clc / tya / adc: explicit clc in the exit block, skip 4
put('g1_clc', 0x2000, [(0x2000, H('2011200341424320112003444546a901606885f06885f1a001b1f085f2c4f2b006c8b1f04c1d20c8189865f085f0a5f1690048a5f04860'))])
# review LOW-1 w_clc: second call site does not fit (length $A9), the rule is dropped with a note
put('g1_wclc', 0x2000, [(0x2000, H('200d2003414243200d20a901606885f06885f1a001b1f085f2c4f2b006c8b1f04c1920c8189865f085f0a5f1690048a5f04860'))])
# G1 indirect rule: any unresolved indirect jump makes the carry unknown, even after sec (m_sec_indirect)
put('g1_sec_ind', 0x2000, [(0x2000, H('20102003414243201020203620a901606885f06885f1a001b1f085f2c4f2b006c8b1f04c1c20c8389865f085f0a5f1690048a5f048606c3412'))])
# sec right before the adc, but an unresolved jmp ($1234) could land on the adc itself
put('g1_sec_adc_ind', 0x2000, [(0x2000, H('20102003414243201020203620a901606885f06885f1a001b1f085f2c4f2b006c8b1f04c1c20c8983865f085f0a5f1690048a5f048606c3412'))])
# sec right before the adc, but a known beq lands between the sec and the adc
put('g1_sec_br', 0x2000, [(0x2000, H('200d2003414243200d20a901606885f06885f1a001b1f085f2a5f2f00dc4f2b006c8b1f04c1d20c8983865f085f0a5f1690048a5f04860'))])
open(os.path.join(D, 'lenhint.hints'), 'w').write('inline $3000 len\n')
open(os.path.join(D, 'rts_word.hints'), 'w').write('rtstable $2010 2\n')
open(os.path.join(D, 'rts_split.hints'), 'w').write('rtstable split $2020 $2018 2\n')
# G2/G3: helpers that walk their inline bytes through (zp),y; each call site is emulated
PRO = '6885F06885F1'                                   # pla / sta $F0 / pla / sta $F1
RET = '981865F085F0A5F1690048A5F04860'                 # tya / clc / adc $F0 / ... / pha / pha / rts
RETSEC = '983865F085F0A5F1690048A5F04860'              # sec: one byte too far
S2 = lambda *ss: b''.join(H('204020') + s for s in ss) + H('60')
g2 = [
  ('g2_iny',   S2(b'HELLO\0', b'AB\0'), PRO + 'A000' + 'C8B1F0F00620EDFD4C4820' + RET),           # iny first, beq exit
  ('g2_y1',    S2(b'HELLO\0', b'\0'),   PRO + 'A001' + 'B1F0F00620EDFDC8D0F6' + RET),             # Y starts at 1
  ('g3_bmi',   S2(b'HELL\xcf', b'O\xcb'), PRO + 'A000' + 'C8B1F0300620EDFD4C4820' + '20EDFD' + RET),   # dci: low chars, last high (bmi)
  ('g3_bpl',   S2(b'\xc8\xc5\xccL', b'\xcfK'), PRO + 'A000' + 'C8B1F048098020EDFD68100230F2' + RET),     # high chars, last low (pha/pla, bpl)
  ('g2_jmpind', S2(b'HELLO\0'),          PRO + 'E6F0D002E6F1A000B1F0D0F4E6F0D002E6F16CF000'),   # inc pointer loop, jmp (ptr)
  ('g2n_ambig', S2(b'HELLO\0'),          PRO + 'A000' + 'C8B1F0F008AE00033003 4C4820' + RET),      # second exit on unknown memory
  ('g2n_join',  S2(b'AB\0'),             PRO + 'A000AD0003F002A005' + 'C8B1F0F0034C4F20' + RET),   # path joins the loop with another Y
  ('g2n_adj',   S2(b'HELLO\0'),          PRO + 'A000' + 'C8B1F0F00620EDFD4C4820' + RETSEC),        # return one byte past the terminator
  ('g2n_ind',   S2(b'HELLO\0'),          PRO + 'A000' + 'C8B1F0F0034C4820' + '6C0003'),            # return through an unknown vector
]
for nm, main, hl in g2:
    put(nm, 0x2000, [(0x2000, main), (0x2040, H(hl))])
# string runs off the end of the image (no terminator)
put('g2n_off', 0x2000, [(0x2000, H('4C4020')), (0x2003, H(PRO + 'A000' + 'C8B1F0F00620EDFD4C0B20' + RET)), (0x2040, H('200320') + b'AB')])
# pointer-increment loop entered by a branch on the pulled high byte (common print-helper shape)
put('g2_incptr', 0x2000, [(0x2000, S2(b'HI\x8d\0', b'\0')), (0x2040, H(PRO + 'D003' + '20EDFD' + 'E6F0D002E6F1' + 'A000B1F0D0F1' + 'A5F148A5F04860'))])
# a string that crosses a page: the high-byte add carries
put('g2_page', 0x2000, [(0x2000, H('4CF820')), (0x2040, H(PRO + 'A000' + 'C8B1F0F00620EDFD4C4820' + RET)),
    (0x20F8, H('204020') + b'PAGE CROSS\0' + H('60'))])
# review of 008a3ec (adv.py cases): helper shapes found by emulation, decimal mode, CSW
S1 = lambda *ss: b''.join(H('204020') + s for s in ss) + H('60')
BODY = 'A000C8B1F0F00620EDFD4C4820'
HOOK = (0x2200, H('C860'))                             # CSW target: changes Y
CP = 'A5F085F2A5F185F3'                                # copy the pointer to $F2/$F3
TS = 'BABD010185F0BD020185F1'                          # tsx / lda $0101,x ... (frame not pulled)
adv = [
  ('g2a_c17', [(0x2000, S1(b'HELLO\0')), (0x2040, H(PRO + CP + 'A000C8B1F2F00620EDFD4C5020' + RET))]),
  ('g2a_c18', [(0x2000, S1(b'HELLO\0')), (0x2040, H(PRO + 'A5F085F2A5F185F3E6F2' + 'A000C8B1F2F00620EDFD4C5220' + RET))]),
  ('g2a_c20', [(0x2000, S1(b'HELLO\0')), (0x2040, H(PRO + 'A200E6F0D002E6F1' + 'A1F0F00620EDFD4C4820' + 'A5F148A5F04860'))]),
  ('g2a_c22', [(0x2000, H('4C0521')), (0x2040, H(PRO + BODY + RET)), (0x2105, H('F8204020') + b'HELLO\0' + H('D860'))]),
  ('g2a_c28', [(0x2000, S1(b'HELLO\0')), (0x2040, H(TS + 'A000C8B1F0F00620EDFD4C4D20' + '981865F0' + 'BA9D0101' + 'A5F16900' + '9D0201' + '60'))]),
  ('g2a_c39', [(0x2000, H('A90085 36A92285 37'.replace(' ', '')) + S1(b'HELLO WORLD\0')), (0x2040, H(PRO + BODY + RET)), HOOK]),
  ('g2a_c40', [(0x2000, H('A200A9009536A9229537') + S1(b'HELLO WORLD\0')), (0x2040, H(PRO + BODY + RET)), HOOK]),
  ('g2a_c41', [(0x2000, H('A93685F8A90085F9A000A90091F8C8A92291F8') + S1(b'HELLO WORLD\0')), (0x2040, H(PRO + BODY + RET)), HOOK]),
  ('g2a_c42', [(0x2000, S1(b'HELLO WORLD\0')), (0x2040, H(PRO + 'A9008536A9228537' + 'A000C8B1F0F00620EDFD4C5020' + RET)), HOOK]),
  ('g2a_c43', [(0x2000, H('A9008D3600A9228D3700') + S1(b'HELLO WORLD\0')), (0x2040, H(PRO + BODY + RET)), HOOK]),
  ('g2a_absx', [(0x2000, S1(b'HELLO\0')), (0x2040, H(PRO + 'AE0003A9009D0020' + 'A000C8B1F0F00620EDFD4C5020' + RET))]),
  ('g2a_cld', [(0x2000, H('4C0521')), (0x2040, H(PRO + BODY + RET)), (0x2105, H('D8204020') + b'HELLO\0' + H('60'))]),
  ('g2a_plp', [(0x2000, H('4C0521')), (0x2040, H(PRO + BODY + RET)), (0x2105, H('28204020') + b'HELLO\0' + H('60'))]),
]
for nm, parts in adv:
    put(nm, 0x2000, parts)
# review of 0267bff (adv2.py n-cases): CSW scan, D flag, other helper shapes
def _adv2():
    H2 = bytes.fromhex
    C = []
    ADV2 = r'''
PRO = '6885F06885F1'
BODY = 'A000C8B1F0F00620EDFD4C4820'               # 2046.. exit at 2053
RET = '981865F085F0A5F1690048A5F04860'
def S(*ss, h=0x2040): return b''.join(H('20%02X%02X' % (h & 0xFF, h >> 8)) + s for s in ss) + H('60')
C = []
def add(n, parts, exp='any', cpu='6502', why=''): C.append((n, cpu, parts, exp, why))
std = lambda main, hl, **k: [(0x2000, main), (0x2040, H(hl))]
HOOK = (0x2200, H('C860'))
SETCSW = 'A9008536A9228537'
HW = b'HELLO WORLD\0'
def M(pre, *ss, post='', hl=PRO+BODY+RET):
    return [(0x2000, H('4C0021')), (0x2040, H(hl)), (0x2100, H(pre) + b''.join(H('204020') + x for x in ss) + H(post + '60')), HOOK]
add('n01_csw_zpx_wrap', M('A2FEA9009538A2FFA9229538', HW), 'note', why='sta $38,x with X=$FE/$FF wraps to $36/$37')
add('n02_csw_zpy_ptr', M('A93685F8A90085F9A000A90091F8C8A92291F8', HW), 'note', why='sta ($F8),y -> $36')
add('n03_csw_one_path', M('AD0003D008'+SETCSW, HW), 'note', why='store on one branch path')
add('n04_csw_after_call', M('', HW, post=SETCSW), 'any', why='store only after the call (benign; note = over-note)')
add('n05_csw_undecoded', [(0x2000, H('4C0021')), (0x2040, H(PRO+BODY+RET)), (0x2100, H('ADF0218D0003ADF1218D0103202021')+H('204020')+HW+H('60')),
    (0x2120, H('6C0003')), (0x21F0, H('8021')), (0x2180, H(SETCSW+'60')), HOOK], 'note', why='CSW store only in code reached by unresolved jmp ($0300)')
add('n06_csw_smc', M('A9368D0D21A9378D1121A9008500A9228501', HW), 'note', why='self-modified sta $00/$01 -> $36/$37')
add('n07_csw_rmb_c02', M('4736', HW), 'note', cpu='65c02', why='RMB4 $36 (Rockwell) moves CSW to $FDE0')
add('n08_d_sed_cld_helper', M('', HW, hl=PRO+BODY+'F8D8'+RET), 'ok', why='sed;cld inside helper before adc')
add('n09_d_php_sed_plp', M('08F828', HW), 'ok', why='php/sed/plp restores D=0')
add('n10_d_sed_php_cld_plp', M('F808D828', HW), 'note', why='plp restores D=1')
add('n11_d_rti', M('A92148A90A48A93848'+'40', HW), 'any', why='rti pulls P with D set, continues at call')
add('n12_d_sed_no_adc', M('F8', b'HI\0', hl=PRO+'D003'+'20EDFD'+'E6F0D002E6F1'+'A000B1F0D0F1A5F148A5F04860'), 'ok', why='D set but helper has no adc')
add('n13_d_sep08_816', M('E208', HW), 'note', cpu='65816', why='sep #$08')
add('n14_d_rep08_816', M('F8C208', HW), 'ok', cpu='65816', why='sed; rep #$08')
add('n15_d_sed_xce_816', M('F818FB38FB', HW), 'note', cpu='65816', why='sed; clc xce; sec xce')
CP = 'A5F085F2A5F185F3'; INC = 'E6F0D002E6F1'
add('n16_cp_extra_iny', M('', HW, hl=PRO+CP+'A000C8B1F2F00620EDFD4C5020'+'C8'+RET), 'note')
add('n17_zpx_double_inc', M('', HW, hl=PRO+'A200'+INC+'A1F0F00620EDFD4C4820'+INC+'A5F148A5F04860'), 'note')
TS = 'BABD010185F0BD020185F1'
add('n18_tsx_sec', M('', HW, hl=TS+'A000C8B1F0F00620EDFD4C4D20'+'983865F0BA9D0101A5F169009D020160'), 'note')
add('n19_tsx_wrong_frame', M('', HW, hl='BABD020185F0BD030185F1'+'A000C8B1F0F00620EDFD4C4D20'+'981865F0BA9D0101A5F169009D020160'), 'note')
add('n20_benign_ind_store', M('A90085F8A90485F9A000A9A091F8', HW), 'any', why='sta ($F8),y to $0400 (benign; note = over-note)')
add('n21_benign_abs_x', M('A200A9A09D0004', HW), 'ok', why='sta $0400,x')
add('n22_benign_cout1', M(SETCSW, HW, hl=PRO+'A000C8B1F0F00620F0FD4C4820'+RET), 'ok', why='CSW changed but helper uses COUT1')
add('n23_benign_cld', M('D8', HW), 'ok')
add('n24_info_absx_store', M('', HW, hl=PRO+'AE0003'+'A000C8B1F0F0099D002020EDFD4C4B20'+RET), 'note', why='sta $2000,x X unknown inside helper')
add('n25_cp_ok', M('', HW, hl=PRO+CP+'A000C8B1F2F00620EDFD4C5020'+RET), 'ok')
add('n26_zpx_ok', M('', HW, hl=PRO+'A200'+INC+'A1F0F00620EDFD4C4820'+'A5F148A5F04860'), 'ok')
add('n27_tsx_ok', M('', HW, hl=TS+'A000C8B1F0F00620EDFD4C4D20'+'981865F0BA9D0101A5F169009D020160'), 'ok')
'''
    ns = {'H': H2}; exec(ADV2, ns); return ns['C']
for n, cpu, parts, exp, why in _adv2():
    put('g2b_' + n.split('_')[0], 0x2000, parts)
# immediate-operand SMC: an exact store onto an immediate operand is allowed, the operand becomes unknown
SM = lambda r: [(0x2000, H('208021') + S1(b'HELLO\0')[0:]), (0x2040, H(PRO + BODY + RET)), (0x2180, H(r))]
PAT = 'A9058D8D21A90D8D8F21' + '18EA6900C900' + '60'            # patch adc #/cmp # operands at $218D/$218F
smc = [
  ('g2s_ok',     SM(PAT)),
  ('g2s_helper', SM('A9018D472060')),                                         # patch ldy #0 in the helper
  ('g2s_ptr',    SM('A90085F8A90485F9A000A90091F8' + 'A9008D8521' + '60')),     # patched lda # builds the pointer high byte
  ('g2s_opc',    SM(PAT.replace('8D8D21', '8D8C21'))),                        # store onto the adc opcode
  ('g2s_range',  SM('A000A90599 8A21'.replace(' ', '') + '18EA6900C900' + '60')),   # sta $218D,y: a range
  ('g2s_rngu',   SM('AC0003A905998A21' + '18EA6900C900' + '60')),            # sta $218A,y with Y unknown: a range over code
  ('g2s_816e',   SM('0828' + 'A9058D8921' + 'EA6900' + '60')),              # 65816 emulation mode: php/plp, width still 8 bits
  ('g2s_816',    SM('18FB' + 'A9058D8A21' + '28' + '6900' + '38FB60')),       # 65816 native: plp, width unknown at the adc
  ('g2s_nocout', [(0x2000, H('A901A000994D20') + S1(b'HELLO\0')), (0x2040, H(PRO + 'E6F0D002E6F1A000B1F0D0F4E6F0D002E6F16CF000'))]),   # range store into a helper without COUT
]
for nm, parts in smc:
    put(nm, 0x2000, parts)
# main sets S first (ldx #$FF / txs): the helper at $2180 runs with S=$FD, its frame at $01FE/$01FF
SMS = lambda pre, r: [(0x2000, H(pre + '208021' + '204020') + b'HELLO\0' + H('4C0F20')), (0x2040, H(PRO + BODY + RET)), (0x2180, H(r))]   # main ends in jmp * (no rts after txs)
# symbolic stack at rts (helper at $2180, error exit taken when $0300 != 0)
stk = [
  ('g2t_pp',    SM('AD0003F003' + '6868' + '60' + '60')),                  # pla;pla;rts: outer caller's frame
  ('g2t_p1',    SM('AD0003F002' + '68' + '60' + '60')),                    # pla;rts: half a frame
  ('g2t_push',  SM('AD0003F002' + '48' + '60' + '60')),                    # net push
  ('g2t_disp',  SM('AD0003F009' + '6868A92148A97F4860' + '60')),          # net 0, pushed computed address
  ('g2t_xblk',  SM('48' + 'AD0003F000' + '60')),                       # pha, then a branch joins at the rts
  ('g2t_scr',   SM('A9008D2001' + '60')),                              # sta $0120: page-1 scratch at a known address
  ('g2t_tsx',   SM('BA' + 'FE0101' + '60')),                             # tsx; inc $0101,x: return address changed
  ('g2t_rti',   SM('40')),                                              # rti on a jsr frame
  ('g2t_plp',   SM('28' + 'A9058D8821' + 'EA6900' + '60')),            # old g2s_816e shape: bare plp pulls a frame byte
  ('g2t_s1hi',  SM('A9008DF001' + '60')),                              # S unknown: sta $01F0 may hit a frame
  ('g2t_skok',  SMS('A2FF9A', 'A9008DF001' + '60')),                    # S known: $01F0 is below S, free
  ('g2t_skhit', SMS('A2FF9A', 'A9008DFE01' + '60')),                    # S known: $01FE is the return address
  ('g2t_dpok',  SM('18FBC230A900015BE23038FB' + 'A9008530' + '60')),    # 65816 D=$0100: sta $30 -> $0130 (scratch)
  ('g2t_dphit', SM('18FBC230A900015BE23038FB' + 'A90085F0' + '60')),    # 65816 D=$0100: sta $F0 -> $01F0
  ('g2t_dpunk', SM('AD00034828' + 'F400012B' + 'A9008530' + '60')),      # 65816 D from pld: unknown
  ('g2t_bal',   SM('4868' + '60')),                                      # balanced pha/pla
  ('g2t_same',  SM('AD0003F007' + '68AA68488A4860' + '60')),              # pla;tax;pla;pha;txa;pha: same order back
  ('u01',       SM('A000A90091F8' + '60')),                              # sta ($F8),y, pointer never set: fully unknown target
  ('u02',       SM('18FBC230AD00035BE23038FB' + 'A90085F0' + '60')),    # 65816 D unknown (tcd of a load): sta $F0 anywhere in bank 0
  ('g2t_swap',  SM('AD0003F009' + '68AA68A88A489848' + '60' + '60')),    # frame bytes swapped
]
for nm, parts in stk:
    put(nm, 0x2000, parts)
# round 9: one write classifier (every store / RMW mode, DB / D / S / index ranges, wrap rules)
W9 = lambda x: '18FB' + x + '38FB' + '60'                   # sub body in native mode, back to emulation before rts
SMP = lambda pre, r, mid='': [(0x2000, H(pre + '208021' + mid + '204020') + b'HELLO\0' + H('60')), (0x2040, H(PRO + BODY + RET)), (0x2180, H(r))]
GSD = '18FBC230A900005BE23038FB'                            # D=0 set by main (GS/OS: D unknown at entry)
wcl = [
  ('g2w_long0',   '65816', '', SM(W9('A9BF8FFE0100')), 'note'),          # sta $00:01FE (long): bank in the operand
  ('g2w_elong',   '65816', '', SM('A9BF8FFE010060'), 'note'),            # emulation, long store to the frame
  ('g2w_elongff', '65816', '', SM('A9218FFF010060'), 'note'),            # long $00:01FF
  ('g2w_m16',     '65816', '', SM(W9('C220A9BFBF8D3F01E220')), 'note'),  # m=0 sta $013F writes $0140
  ('g2w_k16',     '65816', '', SMS('A2FF9A', W9('C220A900BF8DFD01E220')), 'note'),   # S known, m=0 sta $01FD writes $01FE
  ('g2w_gs0ffe',  '65816', 'gsos', SMP(GSD, W9('A9BF8DFE0F')), 'note'),  # GS/OS: S anywhere in bank 0
  ('g2w_gs0120',  '65816', 'gsos', SMP(GSD, W9('A9BF8D2001')), 'note'),  # GS/OS: no $0100-$013F carve-out
  ('g2w_gsemu',   '65816', 'gsos', SMP(GSD, 'A9BF8D000360'), 'ok'),      # GS/OS, emulation: S in page 1, $0300 free
  ('g2w_gsdp',    '65816', 'gsos', SMP('', 'A9BF85FE60', GSD), 'note'),  # GS/OS: D unknown at entry, sta $FE
  ('g2w_gscsw',   '65816', 'gsos', SMP('', 'A900853660', GSD), 'note'),  # GS/OS: D unknown, sta $36 may be CSW
  ('g2w_plb1',    '65816', '', SM(W9('A90148ABA9BF8DFE01')), 'ok'),      # lda #1; pha; plb: $01:01FE
  ('g2w_plb0',    '65816', '', SM(W9('A90048ABA9BF8DFE01')), 'note'),    # DB=0: $00:01FE
  ('g2w_dbuf',    '6502',  '', SM('A23FA9009D0001CA10FA60'), 'ok'),      # ldx #$3F loop: X in 0..$3F
  ('g2w_d20',     '65816', '', SM(W9('C220A900015BE220A9BF8520')), 'ok'),   # native D=$0100: sta $20 -> $0120
  ('g2w_dpnat',   '65816', '', SM(W9('A9BF8580')), 'ok'),                # native dp store with D=0: $0080 (no SMC note)
  ('g2w_srok',    '65816', '', SMS('A2FF9A', W9('A9BF8310')), 'ok'),     # sta $10,s native: $020D
  ('g2w_srhit',   '65816', '', SMS('A2FF9A', W9('A9BF8301')), 'note'),   # sta $01,s: $01FE
  ('g2w_sry',     '65816', '', SM(W9('A000A9BF9301')), 'note'),          # sta ($01,s),y: unknown
  ('g2w_mvnok',   '65816', '', SM(W9('C230A00003A20000A90F00540000E230')), 'ok'),    # mvn: $00:0300-$030F
  ('g2w_mvnhit',  '65816', '', SM(W9('C230A0F801A20000A90F00540000E230')), 'note'),  # mvn: $01F8-$0207
  ('g2w_mvphit',  '65816', '', SM(W9('C230A0FF01A20000A90000440000E230')), 'note'),  # mvp: Y-C..Y = $01FF
  ('g2w_mvnunk',  '65816', '', SM(W9('C230AC0003A20000A90F00540000E230')), 'note'),  # mvn: Y unknown
  ('g2w_mvnwrap', '65816', '', SM(W9('C230A0F8FFA20000A93F00540000E230')), 'note'),  # mvn: $FFF8.. wraps to $0000-$0037 (CSW)
  ('g2w_mvndbr',  '65816', '', SM(W9('C230A00003A20000A90F00540100E230A9BF8DFE01')), 'ok'),   # DB = 1 after mvn: $01:01FE
  ('g2w_tsbhit',  '65c02', '', SM('A9BF0CFE0160'), 'note'),              # tsb $01FE
  ('g2w_trbok',   '65c02', '', SM('A9BF1C200160'), 'ok'),                # trb $0120
  ('g2w_rmwhit',  '6502',  '', SM('A2FE1E000160'), 'note'),              # asl $0100,x X=$FE
  ('g2w_rmwok',   '6502',  '', SM('A2207E000160'), 'ok'),                # ror $0100,x X=$20
  ('g2w_inchit',  '6502',  '', SM('EEFF0160'), 'note'),                  # inc $01FF
  ('g2w_stzhit',  '65c02', '', SM('9CFE0160'), 'note'),                  # stz $01FE
  ('g2w_stzok',   '65c02', '', SM('9C200160'), 'ok'),                    # stz $0120
  ('g2w_stz16',   '65816', '', SM(W9('C2209C3F01E220')), 'note'),        # m=0 stz $013F writes $0140
  ('g2w_pea',     '65816', '', SM('F4000060'), 'note'),                  # pea: a push, rts takes it
  ('g2w_peabal',  '65816', '', SM('F40000686860'), 'ok'),                # pea; pla; pla: balanced
  ('g2w_pei',     '65816', '', SM('D4F060'), 'note'),                    # pei
  ('g2w_per',     '65816', '', SM('62000060'), 'note'),                  # per
  ('g2w_dpwrap',  '65816', '', SM('18FBC220A900015BE22038FB' + 'A2FFA9BF95FF60'), 'note'),   # emulation D=$0100: $FF,x X=$FF wraps to $01FE
  ('g2w_dpnowrap','65816', '', SM(W9('C220A900015BE220A2FFA9BF95FF')), 'ok'),               # native D=$0100: $02FE (no page wrap)
  ('g2w_absxpg',  '6502',  '', SM('A210A9BF9DF00160'), 'ok'),            # $01F0,x X=$10: $0200
  ('g2w_absxpgh', '6502',  '', SM('A20EA9BF9DF00160'), 'note'),          # X=$0E: $01FE
  ('g2w_absxwrap','6502',  '', SM('A237A9009DFFFF60'), 'note'),          # 6502 $FFFF,x X=$37 wraps to $0036 (CSW)
  ('g2w_absxbank','65816', '', SM('A90048AB' + 'A237A9009DFFFF60'), 'ok'),   # 65816 DB=0: $00:FFFF+$37 is $01:0036
  ('g2w_indybank','65816', '', SM('A90048AB' + 'A9F085F8A9FF85F9A046A90091F860'), 'ok'),   # ($F8),y crosses into bank 1
  ('g2w_ptrwrap', '6502',  '', SM('A90085FFA9038500A000A9BF91FF60'), 'ok'),  # ($FF),y: pointer high byte from $00
  ('g2w_long16',  '65816', '', SM(W9('C220A9BFBF8FFFFF00E220')), 'ok'),  # m=0 sta $00:FFFF: $00:FFFF and $01:0000
  ('g2w_srwrap',  '65816', '', SMS('A2FF9A', 'A9BF830260'), 'note'),     # emulation sta $02,s: $01FF
  ('g2w_srwok',   '65816', '', SMS('A2FF9A', 'A9BF831060'), 'ok'),       # emulation sta $10,s: $010D (page-1 wrap)
]
for nm, cpu, plat, parts, exp in wcl:
    put(nm, 0x2000, parts)
# review of 8217ea8 (adv3.py cases): immediate patches, rts dispatch, relocator look-alikes, 65816 widths
def _adv3():
    ADV3 = r'''
PRO = '6885F06885F1'
BODY = 'A000C8B1F0F00620EDFD4C4820'               # 2046.. exit at 2053
RET = '981865F085F0A5F1690048A5F04860'
def S(*ss, h=0x2040): return b''.join(H('20%02X%02X' % (h & 0xFF, h >> 8)) + s for s in ss) + H('60')
C = []
def add(n, parts, exp='any', cpu='6502', why=''): C.append((n, cpu, parts, exp, why))
HOOK = (0x2200, H('C860'))
SETCSW = 'A9008536A9228537'
HW = b'HELLO WORLD\0'
HLP = PRO+BODY+RET
def M(pre, *ss, post='', hl=HLP, extra=()):
    return [(0x2000, H('4C0021')), (0x2040, H(hl)), (0x2100, H(pre) + b''.join(H('204020') + x for x in ss) + H(post + '60')), HOOK] + list(extra)
# --- immediate-patch rule ---
# helper offsets: 2046 A0 00 (ldy operand $2047); RET at 2053: adc #0 hi operand at $205B
add('p01_patch_opcode', M('A9A28D4620', HW), 'note', why='store onto helper opcode $2046 (ldy# -> ldy#?)')
add('p02_absx_covers_opc', M('A200A9EA9D4620', HW), 'note', why='sta $2046,x X known 0: indexed covers opcode+operand')
CMPH = PRO+'A000C8B1F0C900F00620EDFD4C4820'+RET      # cmp #$00 operand at $204C; exit $2055
add('p03_patch_cmp_term', M('A9218D4C20', b'HI!THERE\0', hl=CMPH), 'note', why='patched cmp # terminator')
add('p04_patch_ldy_start', M('A9028D4720', b'A\0B\0'), 'note', why='patched ldy # start index')
add('p05_patch_adc_hi', M('A9018D5B20', HW), 'note', why='patched adc #0 (high byte) in return adjust')
# p06: pointer built from lda #$00 / lda #$04 (benign $0400) but both immediates are patched to $36/$00 first
# 2100: A936 8D1121 A900 8D1521 | 210A? compute: patches target operands of the pointer-building lda #s
P6 = 'A9368D0B21A9008D0F21' + 'A90085F8A90485F9A000A90091F8'
add('p06_patch_ptr_lda', M(P6, HW), 'note', why='patched lda # that builds a (zp),y pointer -> $0036')
add('p07_ptr_y_unknown_zp', M('A90085F885F9AC0003A90091F8', HW), 'note', why='ptr $0000, Y unknown')
add('p07b_ptr_y_unknown_benign', M('A90085F8A90485F9AC0003A9A091F8', HW), 'ok', why='ptr $0400, Y unknown')
add('p08_ptr_call_between', M('A93685F8A90085F9202021A000A90091F8C8A92291F8', HW, extra=[(0x2120, H('60'))]), 'note', why='jsr between pointer immediates and store')
add('p09_ptr_branch_target', M('A93685F8A90085F9F000A000A90091F8C8A92291F8', HW), 'note', why='branch target between immediates and store')
add('p10_ptr_page_wrap', M('A9F085F8A9FF85F9A046A90091F8A047A92291F8', HW), 'note', why='ptr $FFF0 + Y=$46 wraps to $0036')
add('p11_benign_zpx', M('A200A9009500', HW), 'ok', why='sta $00,x (benign, X=0)')
add('p12_benign_patch_counter', M('A9058D0621A900', HW), 'ok', why='exact patch of a non-helper lda # operand')
# rts dispatch with computed target into undecoded CSW-store code
add('p13_rts_dispatch', [(0x2000, H('4C0021')), (0x2040, H(HLP)), (0x2100, H('202021204020')+HW+H('60')),
    (0x2120, H('ADF12148ADF0214860')), (0x21F0, H('7F21')), (0x2180, H(SETCSW+'60')), HOOK], 'note', why='push/rts to computed target')
# --- relocator lookalikes (helper at $2300) ---
def RL(n=1, src=0x21, tail0=b'', tail1=None, br='F003', mid='B9%02X%02X99%02X20' , dest=0x20, extra_loop=''):
    loop = H('A2%02XA000' % n) + H('B900%02X' % src) + H('99%02X%02X' % (0, dest)) + H('C8D0F7EE0620EE0920CA') + H(br) + H('4C0420')
    return loop
HLP3 = H(PRO.replace('','') + 'A000C8B1F0F00620EDFD4C0823' + RET)   # same helper rebased to $2300: loop $2308 exit $2313
def reloc_img(body0, body1):
    lp = RL()
    p0 = lp + body0; p1 = lp + body1
    return [(0x2000, p0), (0x2100, p1), (0x2200, H('C860')), (0x2300, HLP3)]
J = lambda s: H('200023') + s
add('r01_overlap_src_in_image', reloc_img(J(HW)+H('60'), H(SETCSW)+J(HW)+H('60')), 'note', why='copies image page $2100 over $2000 (not identity)')
add('r02_reloc_identity_ok', reloc_img(J(HW)+H('60'), J(HW)+H('60')), 'any', why='identity copy page1->page0 (truth same)')
add('r03_reloc_dest_zp', [(0x2000, H('A201A000B90021990000C8D0F7EE0620EE0920CAF0034C0420')+J(HW)+H('60')), (0x2100, H('A9228537')), (0x2200, H('C860')), (0x2300, HLP3)], 'note', why='dest $0000 covers $36')
add('r04_reloc_reentered', [(0x2000, H('A201A000B90021990020C8D0F7EE0620EE0920CAF0034C0420')+J(HW)+H('4C0420')), (0x2100, b'\0'), (0x2200, H('C860')), (0x2300, HLP3)], 'note', why='loop re-entered from later code')
add('r05_reloc_eor', [(0x2000, H('A201A000B900214980990020C8D0F5EE0620EE0B20CAF0034C0420')+J(HW)+H('60')), (0x2200, H('C860')), (0x2300, HLP3)], 'note', why='copy transforms bytes (eor)')
add('r06_reloc_called_twice', [(0x2000, H('A201A000B90021990020C8D0F7EE0620EE0920CAF0034C0420')+H('200020')+J(HW)+H('60')), (0x2200, H('C860')), (0x2300, HLP3)], 'note', why='relocator run twice (jsr back to base)')
# --- convergence chain: 10 exact patches, each patching the next store's pointer immediate ---
def chain(k):
    code = b''; base = 0x2100
    # each link: lda #lo; sta $F8; lda #hi; sta $F9; ldy #0; lda #$EA; sta ($F8),y  -> targets the 'lda #lo' operand of the next link
    L = 14
    for i in range(k):
        nxt = base + (i + 1) * L + 1
        code += H('A9%02X85F8A9%02X85F9A000A9EA91F8' % (nxt & 0xFF, nxt >> 8))
    return code
add('v01_chain10', [(0x2000, H('4C0021')), (0x2040, H(HLP)), (0x2100, chain(10) + H('A900204020') + HW + H('60')), HOOK], 'any', why='10-link patch chain')
# --- 65816 (analytical; no py65 truth) ---
E2N = '18FB'; N2E = '38FB'
add('s01_816_m16_sta0035', M(E2N+'C220A900228D3500E220'+N2E, HW), 'note', cpu='65816', why='m=16 sta $0035 writes $36')
add('s02_816_m16_sta203F', M(E2N+'C220A9EAEA8D3F20E220'+N2E, HW), 'note', cpu='65816', why='m=16 sta $203F writes helper opcode $2040')
add('s03_816_m16_imm_plus_opc', M(E2N+'C220A9A0A08D4720E220'+N2E, HW), 'note', cpu='65816', why='m=16 store at ldy# operand $2047 also hits opcode $2048')
add('s04_816_m_unknown_patch', M(E2N+'AD00034828'+'8D4720'+N2E, HW), 'note', cpu='65816', why='patch with m unknown (plp)')
add('s05_816_known_ok', M(E2N+'E230A9058D0A21A900'+N2E, HW), 'any', cpu='65816', why='exact patch with known m8')
add('s06_816_e_unknown', M('AD0003'+'6A'+'FB'+'A9058D0B21'+'A900', HW), 'note', cpu='65816', why='xce on unknown carry then patch')
add('s07_816_tcs_pea', M(E2N+'C230A93700'+'1B'+'F40022'+'E230'+N2E, HW), 'note', cpu='65816', why='tcs to $0037 then pea writes $36/$37')
'''
    ns = {'H': bytes.fromhex, 'ORG': 0x2000}; exec(ADV3, ns); return ns['C']
for n, cpu, parts, exp, why in _adv3():
    put('g2c_' + n.split('_')[0], 0x2000, parts)
# relocation loop that copies the image onto its own base, run once: ($00) = $2000 load address,
# ($02) = $1000 run address, 2 pages, then jmp to the next byte in the copy ($1023)
REL = ('A9008500' '8502' 'A920' '8501' 'A910' '8503' 'A202' 'A000' 'B100' '9102' 'C8' 'D0F9'
       'E601' 'E603' 'CA' 'D0F2' '4C2310')
RH = '6885F06885F1' + 'A000C8B1F0F00620EDFD4C8810' + '981865F085F0A5F1690048A5F04860'   # helper at $1080
put('g2r_reloc', 0x1000, [(0x1000, H(REL) + H('208010') + b'HELLO\0' + H('208010') + b'AB\0' + H('60')), (0x1080, H(RH))])
# the same loop entered again later (jmp $1000 after the strings): not run once, COUT not trusted
put('g2r_reloc_again', 0x1000, [(0x1000, H(REL) + H('208010') + b'HELLO\0' + H('4C0010')), (0x1080, H(RH))])
# branch-always: a branch whose flag is known on every incoming path is unconditional
put('ba_secbcs', 0x2000, [(0x2000, H('38B003') + b'HI\0' + H('60'))])        # sec; bcs: skipped bytes are data
put('ba_clcbcc', 0x2000, [(0x2000, H('1890 03') + b'HI\0' + H('60'))])       # clc; bcc
put('ba_lda1bne', 0x2000, [(0x2000, H('A901D003') + b'HI\0' + H('60'))])     # lda #1; bne
put('ba_lda0beq', 0x2000, [(0x2000, H('A900F003') + b'HI\0' + H('60'))])     # lda #0; beq
put('ba_clcbcs', 0x2000, [(0x2000, H('18B002EA60 02'))])                      # clc; bcs never taken: $2006 not code
# carry 0 from one path, 1 from the other: bcs at the join stays conditional
put('ba_join', 0x2000, [(0x2000, H('A5F0F003 18 9001 38 B001 60 60'))])
# the flag setter is a jump target (bne joins in front of it): its result is still known
put('ba_settgt', 0x2000, [(0x2000, H('A5F0D001EA 38 B003') + b'HI\0' + H('60'))])
# 65816 native: rep #$01 is a jump target, bcc after it is unconditional
put('ba_rep816', 0x2000, [(0x2000, H('18FB A5F0D000 C201 9003') + b'HI\0' + H('38FB60'))])
put('ba_f12', 0x2000, [(0x2000, H('A9388D062018EA9006A9C120EDFD6060'))])   # nop between clc and bcc patched to sec: carry unknown, both sides code
put('ba_f16', 0x2000, [(0x2000, H('A9C98D06201885109006A9C120EDFD6060'))])   # sta between clc and bcc patched to cmp #: carry unknown
put('ba_f17', 0x2000, [(0x2000, H('A9698D062038A900B006A9C120EDFD6060'))])   # lda # after sec patched to adc #: carry unknown
put('ba_s04', 0x2000, [(0x2000, H('189003A90160A9038DF003A9208DF10300'))])   # lda #</sta p/lda #>/sta p+1 after an always-taken bcc: routine found
put('ba_s04b', 0x2000, [(0x2000, H('189003A90160A903A22020F00360'))])   # lda #</ldx #> after an always-taken bcc: routine found
put('w01', 0x2000, [(0x2000, H('AC0003A93899082018FBC220A96060A9008D00C060'))])   # wide store may make the clc a sec: width after xce unknown
put('w02', 0x2000, [(0x2000, H('A9388D052018FBC220A96060A9008D00C060'))])   # exact store patches clc to sec: width unknown
put('w03', 0x2000, [(0x2000, H('AC0003A900990B2018FBC220A96060A9008D00C060'))])   # wide store may reach the rep operand: m/x unknown
put('w04', 0x2000, [(0x2000, H('A9008D082018FBC220A96060A9008D00C060'))])   # exact store patches the rep operand: m/x unknown
put('w05', 0x2000, [(0x2000, H('685BA938851018FBC220A96060A9008D00C060'))])   # unknown D: sta dp may hit any bank-0 code
put('r01', 0x2000, [(0x2000, H('18FBC230E210A6109D001DC220A96060A9008D00C060'))])   # ring buffer under sep #$10: 8-bit X, $1D00-$1DFF misses the sep (a 16-bit X would cover it)
put('r02', 0x2000, [(0x2000, H('18FBC230A200029E001FCA10FAE220A96060A9008D00C060'))])   # counted 16-bit loop $1F00-$2101 covers the sep: stops
put('r03', 0x2000, [(0x2000, H('A9058D07201890 02A9018D00C060'.replace(' ','')))])   # exact store hits only a branch offset
put('r04', 0x2000, [(0x2000, H('A9C18D07208D00C060'))])   # exact store hits only the address operand of the next store
put('r05', 0x2000, [(0x2000, H('18FBC230A9001F5BA2FE007400CACA10FAE220A96060A9008D00C060'))])   # D=$1F00, ldx #254; stz 0,x; dex; dex; bpl: $1F00-$1FFF
put('r06', 0x2000, [(0x2000, H('18FBC220A9EA388D0C20E220EA189002A90060'))])   # 16-bit sta writes EA 38 over nop/clc: flag-only, widths kept
put('r07', 0x2000, [(0x2000, H('18FBE220A9388D0B20EAEA18FBC220A9000060'))])   # known sec written over clc before xce: must stop
# table narrowing (CSW check): an inline-string helper calls COUT; the caller first runs sub $2180:
# ldx tbl,y with Y bounded inside the 4-byte table -> X in 0..3, sta $30,x cannot reach CSW $36/$37
TN = lambda sub: [(0x2000, H('4C0021')), (0x2040, H('6885F06885F1A000C8B1F0F00620EDFD4C4820981865F085F0A5F1690048A5F04860')),
                  (0x2100, H('208021204020') + b'HELLO WORLD\0' + H('60')), (0x2180, H(sub)), (0x21A0, H('00010203'))]
put('t01', 0x2000, TN('A003BEA021A9BF95308810F660'))
# same with Y unknown (index not bounded within the table): X unknown, may hit CSW -> not proven
put('t02', 0x2000, TN('AC0003BEA021A9BF95308810F660'))
# bounded, but a store reaches the table ($36 into tbl+1): no narrowing -> not proven
put('t03', 0x2000, TN('A9368DA121A003BEA021A9BF95308810F660'))
# both-ways patch: sec is stored over clc on one path only -> clc runs as clc or sec, both successors kept
put('b01', 0x2000, [(0x2000, H('AD00031005A9388D0A20189003A90160A90260'))])
# 65816 bank wrap: lda $1234 at $7F:FFFE takes its high operand byte from $7F:0000; bne at $7F:FFFC falls to $7F:FFFE
wr = bytearray(0x10000); wr[0:3] = H('1260EA'); wr[0xFFF0:0xFFFE] = H('EAEAEAEAEAEAEAEAEAEAEAEAD000'); wr[0xFFFE:] = H('AD34')
put('wrap01', 0x7F0000, [(0x7F0000, bytes(wr))])
# read-modify-write on code: lsr turns ldx #$10 (A2) into eor ($10),y (51); one known value only when it runs once
put('rmw_once', 0x2000, [(0x2000, H('4E0420EAA21060'))])            # straight line from the only entry: runs as eor
put('rmw_loop', 0x2000, [(0x2000, H('A2034E0920CAD0FAEAA21060'))])  # lsr inside a counted loop: unknown, stops
put('rmw_twocall', 0x2000, [(0x2000, H('20072020072060''4E0B20EAA21060'))])   # routine called twice: stops
put('rmw_jtab', 0x2000, [(0x2000, H('A2007C052007204E0B20EAA21060'))])   # reached through jmp ($2005,x): stops
# a store in a callee that runs on every path before the patched byte (callee must-store summary)
put('dom_callee', 0x2000, [(0x2000, H('2006204C0C20A9608D0C20605F00008D00C060'))])   # jsr s; jmp pp: pp runs as rts only
put('dom_fall', 0x2000, [(0x2000, H('200A205F00008D00C060A9608D032060'))])           # jsr s; pp right after the jsr
# calls that never return: Apple II ROM list (pp is reached only through the store path)
for nm, t in (('ff59','59FF'),('ff65','65FF'),('ff69','69FF'),('fa62','62FA'),('e000','00E0'),('e003','03E0')):
    put('noret_'+nm, 0x2000, [(0x2000, H('AD0003F008A9608D10204C102020'+t+'5F00008D00C060'))])
# the language card may be switched to RAM: the ROM call is an ordinary call
put('noret_lc', 0x2000, [(0x2000, H('AD83C0AD0003F008A9608D13204C13202069FF5F00008D00C060'))])
# _SysFailMgr: ldx #$1503; jsl $E10000 never returns
put('noret_sysfail', 0x2000, [(0x2000, H('A20315220000E18D00C060'))])
# QUIT returns only on error (C=1): bcs taken, the bytes after it stay data
put('quit_err', 0x2000, [(0x2000, H('2000BF650003B0038D00C0A9C120EDFD60'))])
# any access to $C080-$C08F (reads too) may switch the language card: ROM calls stay ordinary
put('noret_lcbit', 0x2000, [(0x2000, H('2C8BC02C8BC02069FF8D00C060'))])     # bit $C08B twice (RAM read/write)
put('noret_lcread', 0x2000, [(0x2000, H('AD81C02069FF8D00C060'))])          # lda $C081 (state not modelled)
# jmp ($C080) reads the switch itself; jmp ($C000,x) may read $C080-$C08F
put('noret_lcjmp', 0x2000, [(0x2000, H('AD0003F0036C80C02069FF8D00C060'))])
put('noret_lcjmpx', 0x2000, [(0x2000, H('AD0003F0037C00C02069FF8D00C060'))])
