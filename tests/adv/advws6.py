#!/usr/bin/env python3
"""Width-sound r6 probes (ff24ae4): callee must-store, outside calls. ca65 source at ORG (default $2000).
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
LB = "LIVE: .byte $8D,$00,$C0,$60\n"          # really executed on some path
PP = "pp: .byte $5F,$00,$00\n"+DB              # $5F bbr5 (off 0 -> falls into DEAD); patched to $60 = rts
PPL = "pp: .byte $5F,$00,$00\n"+LB             # same but the $5F form really runs on some path
ST = " lda #$60\n sta pp\n"
# --- must-store probes (65c02)
add('n01_recursive', "lda #2\n sta cnt\n jsr s\n jmp pp\ns:"+ST+" dec cnt\n bmi q\n jsr s\nq: rts\ncnt: .byte 0\n"+PP, '65c02', why='recursive callee stores on every path')
add('n02_two_returns_one_stores', "jsr s\n jmp pp\ns: lda $300\n beq q\n"+ST+" rts\nq: rts\n"+PPL, '65c02', why='2 returns, only one path stores: $5F form live')
add('n03_store_then_nested_patch', "jsr s\n jmp pp\ns: lda #$5D\n sta pp\n jsr s2\n rts\ns2:"+ST+" rts\n"+PP, '65c02', why='s stores $5D then calls s2 storing $60: last wins')
add('n03b_nested_then_store', "jsr s\n jmp pp\ns: jsr s2\n lda #$5D\n sta pp\n rts\ns2:"+ST+" rts\npp: .byte $5F,$00,$00\nLIVE:\n .byte $EA,$60\n", '65c02', why='s2 stores $60 then s stores $5D (eor abs,x 3B): $5D wins, LIVE runs')
add('n04_callee_fall_and_jsr', "lda $300\n beq ff\n jsr s\n jmp pp\nff: nop\ns:"+ST+" rts\n"+PP, '65c02', why='callee also entered by fall-through')
add('n05_pla_pla_path', "jsr s\n jmp pp\ns: lda $300\n beq k\n pla\n pla\n jmp pp\nk:"+ST+" rts\n"+PPL, '65c02', why='pla/pla path reaches pp without the store')
add('n05b_pla_pla_store', "jsr s\n brk\ns: pla\n pla\n"+ST+" jmp pp\n"+PP, '65c02', why='pulls return then stores and jmp pp (dominates)')
add('n06_rts_trick_path', "jsr s\n jmp pp\ns: lda $300\n beq k\n lda #>(pp-1)\n pha\n lda #<(pp-1)\n pha\n rts\nk:"+ST+" rts\n"+PPL, '65c02', why='rts-trick return reaches pp without store')
add('n07_jsr_mid', "jsr mid\n jmp pp\ns:"+ST+"mid: rts\n"+PPL, '65c02', why='jsr into middle, after the store')
add('n08_ptr_some_paths', "jsr s\n jmp pp\ns: lda $300\n beq o\n lda #<pp\n sta $FA\n lda #>pp\n sta $FB\n jmp w\no: lda #<buf\n sta $FA\n lda #>buf\n sta $FB\nw: ldy #0\n lda #$60\n sta ($FA),y\n rts\nbuf: .byte 0\n"+PPL, '65c02', why='pointer = pp on one path only')
add('n08b_ptr_all_paths', "jsr s\n jmp pp\ns: lda #<pp\n sta $FA\n lda #>pp\n sta $FB\n ldy #0\n lda #$60\n sta ($FA),y\n rts\n"+PP, '65c02', why='pointer = pp on every path')
add('n09_depth3', "jsr ra\n jmp pp\nra: jsr rb\n rts\nrb: jsr rc\n rts\nrc:"+ST+" rts\n"+PP, '65c02', why='nested jsr depth 3')
add('n10_rmw_in_callee2', "jsr ra\n jmp pp\nra: jsr s\n rts\ns: inc pp\n rts\n"+PP, '65c02', why='RMW in a depth-2 callee ($5F->$60)')
add('n11_benign_clc_sec', "lda $300\n beq n\n lda #$38\n sta pp\nn: jmp pp\npp: clc\n bcs MUSTX\n rts\nMUSTX: lda #$C1\n jsr $FDED\n rts\n", '6502', why='clc/sec same length, flags differ: bcs target live')
add('n12_rep_sep_width', "clc\n xce\n lda $300\n beq n\n lda #$E2\n sta pp\nn: jmp pp\npp: rep #$20\n .byte $A9,$EA\nMUST8: .byte $60\nMUST16: rts\n", '65816', why='rep/sep differ in width: both decodes live')
# --- calls outside the image (prodos8)
P8 = ['--platform','prodos8']
add('x01_mli_store_before', ST+" jsr $BF00\nDEAD2: .byte $C8\n .word parm\nDEAD2END:\npp: .byte $5F,$00,$00\n"+DB+"parm: .byte 1,0,0\n", '65c02', extra=P8, why='MLI inline: store before call, pp at jsr+6')
add('x02_mli_store_after', " jsr $BF00\nDEAD2: .byte $C8\n .word parm\nDEAD2END:\n"+ST+" jmp pp\n"+PP+"parm: .byte 1,0,0\n", '65c02', extra=P8, why='MLI inline: store after call at jsr+6')
add('x03_mli_param_looks_code', ST+" jsr $BF00\nDEAD2: .byte $20\n .word $5F5F\nDEAD2END:\n jmp pp\n"+PP, '65c02', extra=P8, why='MLI params look like jsr $5F5F; no fake fall-through at jsr+3')
add('x04_ff69_noreturn', "lda $300\n beq zz\n"+ST+" jmp pp\nzz: jsr $FF69\n"+PP, '65c02', extra=P8, why='jsr $FF69 (monitor) does not return; pp only via store path')
add('x05_ff59_noreturn', "lda $300\n beq zz\n"+ST+" jmp pp\nzz: jsr $FF59\n"+PP, '65c02', extra=P8, why='jsr $FF59 (monitor) does not return')
add('b09_recheck', "jsr s\n jmp pp\nm: nop\ns: inc pp\n rts\npp: .byte $5E,$00,$00\nLIVE: .byte $8D,$00,$C0,$60\n", '65c02', why='author: b09 is TP (one inc -> bbr5 off 0 -> next runs)')

CTRL = set()
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
    for dk in ('DEAD','DEAD2'):
        if dk in lab:
            bad = [a for a in code if lab[dk] <= a < lab[dk+'END']]
            if bad: v.append(('FALSE-CODE@' if dk=='DEAD' else 'FALSE-PARAM@') + ','.join(f'{a:04X}' for a in sorted(bad)))
    if 'LIVE' in lab and lab['LIVE'] not in code:
        v.append('MISSED-LIVE' if ('decoding stopped' in lst or 'may also run' in lst) else 'WRONG-DOM(no stop/union, live path hidden)')
    flags = []
    if 'assumes stores with unknown targets' in lst: flags.append('HDR')
    if 'width unknown' in lst: flags.append('WUNK')
    verdict = 'OK' if not v else ' '.join(v)
    if n in CTRL: verdict = 'CTL:' + verdict
    res.append((n, cpu, f'verify rc={rc.returncode}', verdict, ','.join(flags), why))
with open(f"{OUT}/results.txt", 'w') as f:
    for r in res: print(' | '.join(map(str, r))); f.write(' | '.join(map(str, r)) + '\n')
