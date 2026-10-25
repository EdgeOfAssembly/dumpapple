#!/usr/bin/env python3
"""Width-sound r7 probes (768e67d): no-return calls, language card, QUIT, shorter patched forms. ca65 source at ORG (default $2000).
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
LB = "LIVE: .byte $8D,$00,$C0,$60\n"
ST = " lda #$60\n sta pp\n"
PP = "pp: .byte $5F,$00,$00\n"+DB
PPL = "pp: .byte $5F,$00,$00\n"+LB
P8 = ['--platform','prodos8']; GS = ['--platform','gsos']
def nr(pre, call, tailpp, cpu='65c02', extra=P8):
    return ("lda $300\n beq zz\n"+ST+" jmp pp\nzz:"+pre+" "+call+"\n"+tailpp, cpu, extra)
def A(n, t, why): src,cpu,ex=t; add(n, src, cpu, why=why, extra=ex)
# (c) ROM list, prodos8 (list applies) vs no platform (must not)
for r in ('FF59','FF65','FF69','FA62','E000','E003'):
    A(f'r_{r}_p8', nr('', f'jsr ${r}', PP), f'prodos8: jsr ${r} never returns')
    A(f'r_{r}_none', nr('', f'jsr ${r}', PPL, extra=[]), f'no platform: ${r} must keep fall-through')
A('r_jmp_FF69_none', nr('', 'jmp $FF69', PP, extra=[]), 'jmp: no fall-through anyway')
# (b) language card (prodos8): list must be off -> fall-through live
A('l01_bit_C08B_x2', nr(' bit $C08B\n bit $C08B\n', 'jsr $FF69', PPL), 'RAM mapped over ROM: $FF69 may return')
A('l02_lda_C081', nr(' lda $C081\n', 'jsr $FF69', PPL), 'read $C081')
A('l03_sta_C080x', nr(' ldx $301\n sta $C080,x\n', 'jsr $FF69', PPL), 'sta $C080,x X unknown')
A('l04_ptr', nr(' ldy #0\n lda ($00),y\n', 'jsr $FF69', PPL), 'lda ($00),y may reach $C08x')
A('l05_dead_only', ("lda $300\n beq zz\n"+ST+" jmp pp\n rts\n bit $C08B\n bit $C08B\n rts\nzz: jsr $FF69\n"+PP, '65c02', P8), 'LC access only in unreachable bytes (call really does not return)')
A('l06_tcd_dp', nr(' clc\n xce\n rep #$20\n .a16\n lda #$C000\n tcd\n sep #$20\n .a8\n lda z:$83\n rep #$20\n .a16\n lda #0\n tcd\n sep #$20\n .a8\n sec\n xce\n', 'jsr $FF69', PPL, cpu='65816'), 'tcd D=$C000, lda dp $83')
A('l07_mvn_C0', nr(' clc\n xce\n rep #$30\n .a16\n .i16\n ldx #$2000\n ldy #$C08B\n lda #0\n mvn #0,#0\n sep #$30\n .a8\n .i8\n sec\n xce\n', 'jsr $FF69', PPL, cpu='65816'), 'mvn into $C08B')
A('l08_long', nr(' lda f:$00C083\n', 'jsr $FF69', PPL, cpu='65816'), 'lda $00C083 long')
A('l09_slot_y', nr(' ldy #$8B\n lda $C000,y\n', 'jsr $FF69', PPL), 'indexed base $C000 reaches $C08B')
A('l09b_slot6', nr(' ldx #$60\n lda $C08C,x\n', 'jsr $FF69', PP), 'Disk II $C08C,x X=$60 -> $C0EC (not LC): either way acceptable')
A('l10_after_call', ("lda $300\n beq zz\n"+ST+" jmp pp\nzz: jsr $FF69\n bit $C08B\n bit $C08B\n jmp pp\n"+PP, '65c02', P8), 'LC access only after the call (never runs)')
A('l11_hidden_jmpind', ("lda $300\n beq zz\n"+ST+" jmp pp\nzz: lda $301\n beq cc\n jmp ($03F0)\nhid: bit $C08B\n bit $C08B\ncc: jsr $FF69\n"+PPL, '65c02', P8), 'LC access only via unresolved jmp ($03F0)')
A('l12_jmpind_C080', nr(' lda $302\n beq ok\n jmp ($C080)\nok:', 'jsr $FF69', PPL), 'jmp ($C080) reads $C080/$C081')
A('l13_lc_in_smc_stopped_callee', ("lda $300\n beq zz\n"+ST+" jmp pp\nzz: ldx $301\n stx sm\n jsr lcsub\n jsr $FF69\n"+PPL+"lcsub:\nsm: nop\n bit $C08B\n bit $C08B\n rts\n", '65c02', P8), 'LC access inside a callee whose first opcode is patched by an unknown store (not decoded)')
A('l14_lc_after_unknown_operand', ("lda $300\n beq zz\n"+ST+" jmp pp\nzz: lda $301\n sta op+1\nop: bit $C000\n bit $C08B\n jsr $FF69\n"+PPL, '65c02', P8), 'operand patched: bit $C0xx with unknown low byte')
# QUIT ($65)
QP = "parm: .byte 4,0,0,0,0,0,0\n"
add('q01_quit_bcs', " jsr $BF00\n .byte $65\n .word parm\n bcs MUST\nDEAD: .byte $8D,$00,$C0,$60\nDEADEND:\nMUST: brk\n .byte 0\n"+QP, '65c02', extra=P8, why='QUIT returns only with C=1: bcs taken, fall-through dead')
add('q02_quit_bcc', " jsr $BF00\n .byte $65\n .word parm\n bcc DEAD\nMUST: brk\n .byte 0\nDEAD: .byte $8D,$00,$C0,$60\nDEADEND:\n"+QP, '65c02', extra=P8, why='QUIT: bcc never taken')
add('q03_quit_brk', " jsr $BF00\n .byte $65\n .word parm\nMUST: brk\n .byte 0\n"+QP, '65c02', extra=P8, why='QUIT then brk (runs on failure)')
add('q04_quit_unknown_cmd', " lda $300\n sta cb\n jsr $BF00\ncb: .byte $65\n .word parm\nMUST: lda #$C1\n jsr $FDED\n rts\n"+QP, '65c02', extra=P8, why='call byte unknown: ordinary return')
# GS/OS
N = " clc\n xce\n rep #$30\n .a16\n .i16\n"
add('g01_quit_inline', N+" jsl $E100A8\n .word $2029\n .dword parm\nMUST: brk\n .byte 0\nparm: .word 0,0,0\n", '65816', extra=GS, why='GS/OS Quit inline: returns with C=1 on error')
add('g02_quit_stack', N+" pea parm>>16\n pea parm\n pea $2029\n jsl $E100B0\nMUST: brk\n .byte 0\nparm: .word 0,0,0\n", '65816', extra=GS, why='GS/OS Quit stack form')
add('g03_sysfail', N+" lda $300\n beq zz\n sep #$20\n .a8\n lda #$60\n sta pp\n jmp pp\n .a16\nzz: ldx #$1503\n jsl $E10000\n"+PP, '65816', extra=GS, why='_SysFailMgr never returns')
add('g04_sysfail_jumped', N+" lda $300\n beq zz\n ldx $302\n lda $304\n beq j\n sep #$20\n .a8\n lda #$60\n sta pp\n jmp pp\n .a16\nzz: ldx #$1503\nj: jsl $E10000\n"+PPL, '65816', extra=GS, why='jump into the jsl: X unknown, ordinary call')
# wrong user hint on a call that returns
add('h01_wrong_noreturn_hint', "lda $300\n beq zz\n"+ST+" jmp pp\nzz: jsr sub\n"+PPL+"sub: rts\n", '65c02', extra=['--hints','HINTFILE'], why='user hint noreturn on a returning call (user claim)')
# (d) shorter patched form that falls through
add('d01_shorter_form', " lda #$C8\n sta pp\n jsr h\n rts\nh:\npp: ldy #$00\nDEAD: lda #$C1\n jsr $FDED\n rts\nDEADEND:\n", '6502', why='ldy #0 patched to iny: next byte $00 is brk; pp+2 never runs')
add('d02_shorter_form_union', " lda $300\n beq q\n lda #$C8\n sta pp\nq: jsr h\n rts\nh:\npp: ldy #$00\nLIVE: lda #$C1\n jsr $FDED\n rts\n", '6502', why='patched on one path only: both forms live')

CTRL = set()
res = []
for n, cpu, src, org, extra, why in C:
    s = f"{OUT}/{n}.s"
    open(f"{OUT}/{n}.src.s", 'w').write(f'.setcpu "{"65816" if cpu=="65816" else ("65C02" if cpu=="65c02" else "6502")}"\n.smart -\n.org ${org:X}\n' + src)
    open(f"{OUT}/{n}.cfg0", 'w').write(f'MEMORY {{ M: start=${org:X}, size=$8000, file=%O; }}\nSEGMENTS {{ CODE: load=M; }}\n')
    r = subprocess.run(f'ca65 -g -o {OUT}/{n}.o {OUT}/{n}.src.s && ld65 -C {OUT}/{n}.cfg0 --dbgfile /dev/null -Ln {OUT}/{n}.lbl -o {OUT}/{n}.bin {OUT}/{n}.o', shell=True, capture_output=True, text=True)
    if r.returncode: res.append((n, cpu, 'BUILD-ERR', r.stderr.strip()[:200])); continue
    lab = {}
    pass
    for l in open(f"{OUT}/{n}.lbl"):
        p = l.split(); lab[p[2].lstrip('.')] = int(p[1], 16)
    extra=[ (os.path.abspath(f'{OUT}/{n}.hints') if e=='HINTFILE' else e) for e in extra]
    if 'HINTFILE' in [x for x in extra if False] : pass
    if n.startswith('h01'):
        open(f'{OUT}/{n}.hints','w').write(f"noreturn ${lab['zz']:06X}\n")
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
        v.append('MISSED-LIVE' if ('decoding stopped' in lst or 'may also run' in lst) else 'HINT-TAGGED' if 'per noreturn hint' in lst else 'WRONG-DOM(no stop/union, live path hidden)')
    flags = []
    if 'assumes stores with unknown targets' in lst: flags.append('HDR')
    if 'width unknown' in lst: flags.append('WUNK')
    verdict = 'OK' if not v else ' '.join(v)
    if n in CTRL: verdict = 'CTL:' + verdict
    res.append((n, cpu, f'verify rc={rc.returncode}', verdict, ','.join(flags), why))
with open(f"{OUT}/results.txt", 'w') as f:
    for r in res: print(' | '.join(map(str, r))); f.write(' | '.join(map(str, r)) + '\n')
