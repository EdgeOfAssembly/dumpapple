#!/usr/bin/env python3
"""Width-sound r4 probes (096132f). ca65 source at ORG (default $2000).
MUST* labels: truly executed, must be an instruction start.  DEAD..DEADEND: never
executed as an opcode; an instruction start inside = FALSE-CODE.
Usage: advws3.py DUMPAPPLE OUTDIR [--strict-smc]"""
import sys, os, re, subprocess
DA, OUT = sys.argv[1], sys.argv[2]; MODE = sys.argv[3:]; os.makedirs(OUT, exist_ok=True)
C = []
def add(n, src, cpu='65816', why='', org=0x2000, extra=()): C.append((n, cpu, src, org, list(extra), why))
FALL = "MUST: lda #$C1\n jsr $FDED\n rts\n"
TAIL = " lda #$60\nDEAD: .byte $60,$A9,$00,$8D,$00,$C0,$60\nDEADEND:\n"   # m8: lda #$60;rts  m16: lda #$6060 then DEAD
TAILM = " lda #$60\n .byte $60\nDEAD: .byte $A9,$00,$8D,$00,$C0,$60\nDEADEND:\n"  # real path m8 (rts at .byte $60)

# DEADB: width-independent bytes (sta $C000; rts) -- an instruction start inside = FALSE-CODE
DB = "DEAD: .byte $8D,$00,$C0,$60\nDEADEND:\n"
# ---------- mvn/mvp over code (65816).  pp: nop is turned into rts ($60) by the block move
MV = "clc\n xce\n rep #$30\n .a16\n .i16\n ldx #{src}\n ldy #{dst}\n lda #{n}\n {op} #0,#0\n sep #$30\n .a8\n .i8\n"
add('m01_mvn_short_known_rts', MV.format(src='src',dst='pp',n=1,op='mvn')+"pp: nop\n nop\n"+DB+"src: .byte $60,$EA\n", why='2-byte known src (<=16): rts dominates')
add('m02_mvn_32_known_rts', MV.format(src='src',dst='dst',n=31,op='mvn')+"dst: .res 31,$EA\npp: nop\n"+DB+"src: .res 31,$EA\n .byte $60\n", why='32-byte known src (>16 -> wide): pp becomes rts')
add('m02b_mvn_8_srcwritten', "clc\n xce\n lda #$60\n sta src+7\n"+MV.format(src='src',dst='dst',n=7,op='mvn')+"dst: .res 7,$EA\npp: nop\n"+DB+"src: .res 8,$EA\n", why='8-byte src written by another store (wide): pp=rts')
add('m03_mvn_unk_len', "clc\n xce\n rep #$30\n .a16\n .i16\n ldx #src\n ldy #dst\n lda $300\n and #$000F\n mvn #0,#0\n sep #$30\n .a8\n .i8\ndst: .res 7,$EA\npp: nop\n"+DB+"src: .res 7,$EA\n .byte $60\n .res 8,$EA\n", why='unknown length (real 7): pp=rts')
add('m04_mvn_unk_src', "clc\n xce\n rep #$30\n .a16\n .i16\n ldx $300\n ldy #pp\n lda #0\n mvn #0,#0\n sep #$30\n .a8\n .i8\npp: nop\n"+DB, why='unknown source, 1 byte: value unknown -> must stop')
add('m05_mvp_back_32', MV.format(src='srce',dst='ppe',n=31,op='mvp')+"dst: .res 31,$EA\nppe:\npp: nop\n"+DB+"src: .res 31,$EA\nsrce: .byte $60\n", why='mvp backward, 32 bytes, last byte rts lands on pp')
add('m06_mvn_loop', "clc\n xce\n ldy #2\nlp: phy\n rep #$30\n .a16\n .i16\n ldx #src\n ldy #dst\n lda #31\n mvn #0,#0\n sep #$30\n .a8\n .i8\n ply\n dey\n bne lp\ndst: .res 31,$EA\npp: nop\n"+DB+"src: .res 31,$EA\n .byte $60\n", why='mvn in a loop')
add('m07_mvn_branch_off', "clc\n xce\n"+MV.format(src='src',dst='dst',n=31,op='mvn').replace("clc\n xce\n","",1)+"dst: .res 30,$EA\n bra ov\nMUST: rts\nov:\n"+DB+"src: .res 30,$EA\n .byte $80,$00\n", why='mvn rewrites bra offset to 0: ov never runs')
add('m08_mvn_jmp_operand', MV.format(src='src',dst='dst',n=31,op='mvn')+"dst: .res 29,$EA\n jmp old\nMUST: rts\nold:\n"+DB+"src: .res 29,$EA\n .byte $4C\n .word MUST\n", why='mvn rewrites jmp target')
add('m09_mvn_sep_operand', MV.format(src='src',dst='dst',n=31,op='mvn')+"dst: .res 30,$EA\n rep #$00\n lda #$60\n .byte $60\nDEAD: .byte $A9,$00,$8D,$00,$C0,$60\nDEADEND:\nsrc: .res 30,$EA\n .byte $E2,$20\n", why='mvn: rep#0 -> sep #$20 (m8)')
# ---------- 6502 wide indexed store over an opcode
add('w01_6502_sta_x_rts', "ldx $300\n lda #$60\n sta base,x\n jmp go\nbase: .res $40,$EA\ngo: nop\npp: nop\n"+DB, '6502', why='sta base,x X unknown 8-bit, pp at base+$44 -> rts (bounded store)')
add('w02_6502_loop_rts', "ldx #$7F\nlp: lda #$60\n sta base,x\n dex\n bpl lp\n jmp go\nbase: .res $44,$EA\ngo:\npp: nop\n"+DB, '6502', why='counted loop X=0..$7F writes rts over pp')
add('w02b_816_sta_x_rts', "clc\n xce\n sep #$30\n ldx $300\n lda #$60\n sta base,x\n jmp go\nbase: .res $40,$EA\ngo: nop\npp: nop\n"+DB, why='65816: same as w01')
# ---------- RMW on opcode
add('r01_lsr_once', "lsr pp\npp: cpy #$EA\n"+DB, '6502', why='lsr $C0 -> $60 rts, runs once')
add('r02_lsr_loop', "ldx #1\nlp: lsr pp\n dex\n bpl lp\n jmp pp\npp: .byte $C0, <DEAD\n"+DB, '6502', why='lsr twice: $C0->$60->$30 (bmi DEAD+? ) ; real bmi taken/not unknown')
add('r03_rol_clc', "clc\n rol pp\npp: bmi DEAD\n nop\n"+DB, '6502', why='rol $30 C=0 -> $60 rts')
add('r04_rol_unkc', "lda $300\n lsr\n rol pp\npp: bmi DEAD\n nop\n"+DB, '6502', why='rol $30, C unknown -> $60/$61: must stop')
add('r05_dec_once', "dec pp\npp: adc ($EA,x)\n"+DB, '6502', why='dec $61 -> $60 rts')
add('r06_inc_two_callers', "jsr s\n jsr s\n rts\ns: inc pp\npp: .byte $5F\n rts\n nop\n"+DB, '65c02', why='inc twice: $5F->$60 (rts) ->$61')
add('r07_asl_once', "asl pp\npp: bmi DEAD\n"+DB, '6502', why='asl $30 -> $60 rts')
# ---------- union / dominance (6502).  encoded nop, store writes rts; MUST code after pp is real on alt path
UT = "pp: nop\nMUST: lda #$C1\n jsr $FDED\n rts\n"
add('u01_orig_then_patched', "ldx #1\nlp: dex\n bmi out\n lda #$60\n sta pp\n jmp pp\nout: jmp lp\n"+UT, '6502', why='first nop then rts? (orig never: store first) control')
add('u02_alt_branch', "lda $300\n bne pp\n lda #$60\n sta pp\n"+UT, '6502', why='alt path reaches pp unpatched: union')
add('u03_jmptab', "ldx $300\n jmp (tb)\nm: lda #$60\n sta pp\n"+UT+"tb: .word pp\n", '6502', why='jmp() table entry is pp')
add('u04_rts_trick', "lda #>(pp-1)\n pha\n lda #<(pp-1)\n pha\n lda $300\n beq q\n rts\nq: lda #$60\n sta pp\n"+UT, '6502', why='RTS trick to pp before store')
add('u05_backedge', "ldx #1\nlp: dex\n bmi done\n lda #$60\n sta pp\npp: nop\n jmp lp\ndone:\nMUST: rts\n", '6502', why='loop back-edge; pp runs after store each time (dominated) -> control')
add('u05b_backedge_pre', "ldx #1\ntop:\npp: nop\nMUST: dex\n bmi done\n lda #$60\n sta pp\n jmp top\ndone: rts\n", '6502', why='pp runs before store on 1st iteration: union')
add('u06_len_1to3_dom', "lda #$4C\n sta pp\npp: nop\nDEAD: .word oth\n .byte $8D,$00,$C0,$60\nDEADEND:\noth: rts\n", '6502', why='nop->jmp oth, dominates; DEAD bytes are operands')
add('u06b_len_1to3_union', "lda $300\n beq pp\n lda #$4C\n sta pp\npp: nop\nMUST: .byte $EA\n nop\n rts\noth: rts\n", '6502', why='union with overlapping boundaries (nop / jmp $EAEA)')
add('u07_nop_to_pld', "clc\n xce\n pea $2000\n lda #$2B\n sta pp\n ldx #$38\npp: nop\n .byte $86, <cc\ncc: clc\n xce\n rep #$20\n"+TAILM, why='nop->pld D=$2000: stx dp hits cc')
add('u07b_nop_to_pld_union', "clc\n xce\n pea $2000\n lda $300\n beq pp\n lda #$2B\n sta pp\n ldx #$38\npp: nop\n .byte $86, <cc\ncc: clc\n xce\n rep #$20\n"+TAILM, why='union: one path pld hits cc')
add('u08_nop_to_rti_816', "clc\n xce\n lda #$40\n sta pp\npp: nop\n"+DB, why='nop->rti 65816 runs as')
add('u08b_nop_to_rti_6502', "lda #$40\n sta pp\npp: nop\n"+DB, '6502', why='g03 retest')
add('u09_nop_to_xce_tcd', "clc\n xce\n lda #$FB\n sta pp\n sec\npp: nop\n rep #$20\n"+TAILM, why='nop->xce known (g01 dom)')
# ---------- D sets
def dset(k, hit_last=True):
    s="clc\n xce\n lda $300\n"; vals=[0x3000+0x100*i for i in range(k-1)]+[0x2000]
    for i,v in enumerate(vals[:-1]): s+=f" cmp #{i}\n bne n{i}\n pea ${v:04X}\n bra lb\nn{i}:\n"
    s+=f" pea ${vals[-1]:04X}\nlb: pld\n lda #$38\n .byte $85, <cc\n .res $10,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM
    return s
add('d01_D4', dset(4), why='4 D values, one hits cc')
add('d02_D5', dset(5), why='5 D values -> unknown D (assumed/stop)')
add('d03_D_loop', "clc\n xce\n pea $1000\n pld\n ldy #3\nlp: rep #$20\n .a16\n tdc\n clc\n adc #$0400\n tcd\n sep #$20\n .a8\n dey\n bne lp\n lda #$38\n .byte $85, <cc\n .res $10,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM, why='D changes in loop $1400..$2000: last = $2000 hits cc')
# ---------- table narrowing
TB = "\n lda #$38\n sta base,x\n jmp go\nbase: .res $40,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM+"go: jmp cc\n"
add('t01_tbl_y_unbounded', "clc\n xce\n ldy $300\n ldx tb,y"+TB+"tb: .byte 0,1,2\n .byte $40\n", why='Y unbounded: X can be $40 (byte after table)')
add('t02_tbl_y_past_end', "clc\n xce\n ldy #3\nlp: ldx tb,y"+TB.replace(" jmp go\n"," dey\n bpl lp\n jmp go\n",1)+"tb: .byte 0,1,2\n .byte $40\n", why='loop Y=3..0, table 3 + 1 past')
add('t03_tbl_stored', "clc\n xce\n lda #$40\n sta tb+1\n ldy $300\n cpy #3\n bcs go2\n ldx tb,y"+TB+"go2: rts\ntb: .byte 0,1,2\n", why='table entry patched to $40')
add('t04_tbl_y16', "clc\n xce\n rep #$10\n .i16\n ldy $300\n sep #$10\n .i8\n ldx tb,y"+TB+"tb: .byte 0,1,2\n .byte $40\n", why='16-bit Y loaded then truncated; Y unbounded')
add('t04b_tbl_y16_live', "clc\n xce\n rep #$10\n .i16\n ldy $300\n lda tb,y\n sep #$10\n .i8\n tax"+TB+"tb: .byte 0,1,2\n .byte $40\n", why='16-bit index into table, X from A')
add('t05_tbl_page_cross', "clc\n xce\n ldy $300\n cpy #4\n bcs go2\n ldx tb,y"+TB+"go2: rts\n .res $2100-*-2,$EA\ntb: .byte 0,1,2,$40\n", why='table crosses $20FF/$2100; $40 inside')
# ---------- cmp/cpx narrowing
CX = " lda #$38\n sta base,x\n jmp go\nbase: .res $40,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM+"go: jmp cc\nout: rts\n"
add('c01_cpx_bcc_ge', "clc\n xce\n ldx $300\n cpx #$40\n bcc out\n"+CX, why='X>=$40 edge: store hits cc')
add('c02_cpx_bpl_signed', "clc\n xce\n ldx $300\n cpx #$10\n bpl out\n"+CX, why='bpl is signed: X=$40 -> $30 N=0... X=$90 N=1 reaches; must not narrow')
add('c02b_cpx_bmi', "clc\n xce\n ldx $300\n cpx #$10\n bmi out\n"+CX, why='bmi: X=$40 falls through')
add('c03_cmp_A_not_X', "clc\n xce\n ldx $300\n lda $301\n cmp #4\n bcs out\n"+CX, why='narrowing A must not narrow X')
add('c04_cmp_patched', "clc\n xce\n lda #$41\n sta cp+1\n ldx $300\ncp: cpx #4\n bcs out\n"+CX, why='cpx operand patched to $41: X up to $40')
add('c05_cmp16', "clc\n xce\n rep #$30\n .a16\n .i16\n ldx $300\n cpx #$0004\n bcs out16\n sep #$30\n .a8\n .i8\n"+CX+"out16: sep #$30\n rts\n", why='CONTROL: X<4 never hits cc, so DEAD really runs (m16 lda #$6060); FALSE-CODE here is the correct answer')
add('c06_cmp_unk_width', "clc\n xce\n lda $302\n pha\n plp\n ldx $300\n cpx #4\n bcs out\n"+CX, why='X width unknown at cpx')
add('c07_cpx_beq', "clc\n xce\n ldx $300\n cpx #4\n beq out\n"+CX, why='beq does not bound')

CTRL = {'u01_orig_then_patched','u05_backedge','c05_cmp16'}
res = []
for n, cpu, src, org, extra, why in C:
    s = f"{OUT}/{n}.s"
    open(f"{OUT}/{n}.src.s", 'w').write(f'.setcpu "{"65816" if cpu=="65816" else ("65C02" if cpu=="65c02" else "6502")}"\n.smart -\n.org ${org:X}\n' + src)
    open(f"{OUT}/{n}.cfg0", 'w').write(f'MEMORY {{ M: start=${org:X}, size=$8000, file=%O; }}\nSEGMENTS {{ CODE: load=M; }}\n')
    r = subprocess.run(f'ca65 -g -o {OUT}/{n}.o {OUT}/{n}.src.s && ld65 -C {OUT}/{n}.cfg0 --dbgfile /dev/null -Ln {OUT}/{n}.lbl -o {OUT}/{n}.bin {OUT}/{n}.o', shell=True, capture_output=True, text=True)
    if r.returncode: res.append((n, cpu, 'BUILD-ERR', r.stderr.strip()[:200])); continue
    lab = {}
    for l in open(f"{OUT}/{n}.lbl"):
        p = l.split(); lab[p[2].lstrip('.')] = int(p[1], 16)
    rc = subprocess.run([DA, '-q', '--cpu', cpu, '--org', f'{org:X}'] + extra + MODE + ['-o', s, '--verify', f"{OUT}/{n}.bin"], capture_output=True, text=True)
    lst = open(s).read() if os.path.exists(s) else ''
    code = set(int(m.group(1)+m.group(2), 16) for m in re.finditer(r';\s*([0-9A-F]{2})/([0-9A-F]{4}):', lst))
    v = []
    for k, a in lab.items():
        if k.startswith('MUST') and a not in code: v.append(f'MISSED-CODE@{a:04X}')
    if 'DEAD' in lab:
        bad = [a for a in code if lab['DEAD'] <= a < lab['DEADEND']]
        if bad: v.append('FALSE-CODE@' + ','.join(f'{a:04X}' for a in sorted(bad)))
    flags = []
    if 'assumes stores with unknown targets' in lst: flags.append('HDR')
    if 'width unknown' in lst: flags.append('WUNK')
    verdict = 'OK' if not v else ' '.join(v)
    if n in CTRL: verdict = 'CTL:' + verdict
    res.append((n, cpu, f'verify rc={rc.returncode}', verdict, ','.join(flags), why))
with open(f"{OUT}/results.txt", 'w') as f:
    for r in res: print(' | '.join(map(str, r))); f.write(' | '.join(map(str, r)) + '\n')
