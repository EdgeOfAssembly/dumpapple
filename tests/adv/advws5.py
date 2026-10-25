#!/usr/bin/env python3
"""Width-sound r5 probes (2dd4618): RMW runs-once, wide-store edges. ca65 source at ORG (default $2000).
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


DB = "DEAD: .byte $8D,$00,$C0,$60\nDEADEND:\n"
# inc twice: $5E (lsr abs,x) -> $5F (65c02 bbr5 zp,rel; offset 0 falls into DEAD) -> $60 (rts).  A wrong
# 'runs once' gives bbr5 and decodes DEAD = FALSE.  Real: the byte is $60 when pp runs.
PP = "pp: .byte $5E,$00,$00\n"+DB
S = "s: inc pp\n rts\n"
add('b00_once_ctl', "jsr s\n jmp pp\n"+S+"pp: .byte $5F,$00,$00\n"+DB, '65c02', why='CONTROL: one jsr, $5F->$60 runs as rts')
add('b01_two_jsr', "jsr s\n jsr s\n jmp pp\n"+S+PP, '65c02', why='two jsr callers')
add('b02_rts_trick_caller', "lda #>(r-1)\n pha\n lda #<(r-1)\n pha\n jmp s\nr: jsr s\n jmp pp\n"+S+PP, '65c02', why='RTS-trick (pushed return) + jsr')
add('b02b_computed_caller', "lda #>(r-1)\n pha\n lda #<(r-1)\n pha\n jmp (vec)\nr: jsr s\n jmp pp\nvec: .word s\n"+S+PP, '65c02', why='jmp (vec) to s + jsr')
add('b03_entry_and_flow', "jsr s\n jmp pp\n"+S+PP, '65c02', why='s is also an --entry (external call first)', extra=['--entry','2006'])
add('b04_recursive', "lda #1\n sta cnt\n jsr s\n jmp pp\ns: inc pp\n dec cnt\n bmi q\n jsr s\nq: rts\ncnt: .byte 0\n"+PP, '65c02', why='recursion: inc runs twice')
add('b05_also_sta', "lda #$5E\n sta pp\n jsr s\n jsr s2\n jmp pp\n"+S+"s2: lda #$5F\n sta pp\n jsr s\n rts\n"+PP, '65c02', why='byte also hit by sta: values $5F/$60...')
add('b05b_sta_then_inc', "lda #$5F\n sta pp\n inc pp\n jmp pp\n"+PP, '65c02', why='sta $5F then inc -> $60; encoded+1=$5F would be false')
add('b06_tsb_unknownA', "lda $300\n tsb pp\n jmp pp\npp: jsr ret\n"+DB+"ret: rts\n", '65c02', why='tsb unknown A (real $40): jsr->rts')
add('b07_rol_clc_one_path', "lda $300\n beq xx\n clc\nxx: rol pp\n jmp pp\npp: .byte $30,$00\nMUST: rts\n", '6502', why='carry unknown: $60 or $61 (adc then MUST)')
add('b08_sub_once_in_loop', "ldx #1\nlp: jsr s\n dex\n bpl lp\n jmp pp\n"+S+PP, '65c02', why='one jsr site, inside a loop')
add('b00s_sta_sub_ctl', "jsr s\n jmp pp\ns: lda #$60\n sta pp\n rts\npp: .byte $5F,$00,$00\n"+DB, '65c02', why='same as b00 with sta: union semantics')
add('b00j_once_fall', "jsr s\npp: .byte $5F,$00,$00\n"+DB+S, '65c02', why='one jsr, pp right after the jsr')
add('b09_jsr_and_fall', "jsr s\n jmp pp\nm: nop\n"+S+PP, '65c02', why='control-ish: s also reached by fall-through from dead m (not reached) = once')
add('b10_two_entries_tail', "jsr s\n jmp s2\ns2: jsr s\n jmp pp\n"+S+PP, '65c02', why='jsr then tail jmp + jsr: twice')
# ---------- wide-store edges
add('e01_4byte_loop', "ldx #3\nlp: lda #$60\n sta base,x\n dex\n bpl lp\n jmp pp\nbase: .res 3,$EA\npp: nop\n"+DB, '6502', why='exactly 4 bytes, last is pp')
add('e02_5byte_loop', "ldx #4\nlp: lda #$60\n sta base,x\n dex\n bpl lp\n jmp pp\nbase: .res 4,$EA\npp: nop\n"+DB, '6502', why='5 bytes, last is pp')
add('e03_mvn_known_len_src_stored', "clc\n xce\n lda #$60\n sta src+4\n rep #$30\n .a16\n .i16\n ldx #src\n ldy #dst\n lda #4\n mvn #0,#0\n sep #$30\n .a8\n .i8\ndst: .res 4,$EA\npp: nop\n"+DB+"src: .res 5,$EA\n", why='mvn len 5 known, source written by sta')
add('e03b_mvn4_src_stored', "clc\n xce\n lda #$60\n sta src+3\n rep #$30\n .a16\n .i16\n ldx #src\n ldy #dst\n lda #3\n mvn #0,#0\n sep #$30\n .a8\n .i8\ndst: .res 3,$EA\npp: nop\n"+DB+"src: .res 4,$EA\n", why='mvn len 4 known, source written by sta')
add('e04_setter_in_wide', "clc\n xce\n ldx $300\n lda #$38\n sta base,x\n jmp cc\nbase: .res $40,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM, why='clc setter inside 256-byte wide range')
add('e05_wide_16bit_y', "clc\n xce\n rep #$10\n .i16\n ldy $300\n lda #$60\n sta base,y\n sep #$10\n .i8\n jmp pp\nbase: .res $40,$EA\npp: nop\n"+DB, why='16-bit Y wide (whole bank -> assumed by default)')
add('e06_ptr_wide', "lda #<base\n sta $FA\n lda #>base\n sta $FB\n ldy $300\n lda #$60\n sta ($FA),y\n jmp pp\nbase: .res $40,$EA\npp: nop\n"+DB, '6502', why='(zp),y wide over pp')

CTRL = {'b00_once_ctl','b09_jsr_and_fall'}
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
