#!/usr/bin/env python3
"""Width-sound r8 probes (1425ae4): no-return calls, language card, QUIT, shorter patched forms. ca65 source at ORG (default $2000).
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

PPL2 = "pp: .byte $EA\n"+LB
PP2 = "pp: .byte $EA\n"+DB
HINTS = {}   # probe -> list of labels whose address gets "noreturn $addr"
TAGX = {}    # probe -> 'T' (pp line must carry the hint tag) / 'N' (no hint tag anywhere)
def H(n, src, cpu, hints, tag, why, extra=()):
    add(n, src, cpu, why=why, extra=['--hints','HINTFILE']+list(extra)); HINTS[n]=hints; TAGX[n]=tag
G0 = "lda $300\n beq zz\n"+ST+" jmp pp\nzz:"
# (a) hint tagging
H('h01_wrong_hint', G0+" jsr sub\n"+PPL2+"sub: rts\n", '65c02', ['zz'], 'T', 'wrong hint: call returns')
H('h02_correct_hint', G0+" jsr sub\n"+PP2+"sub: jmp $1234\n", '65c02', ['zz'], 'T', 'correct hint: sub never returns, tool cannot know')
H('h03_two_one_matters', " lda $301\n beq a1\nh03x: jsr sub\n rts\na1: "+G0[0:]+" jsr sub2\n"+PP2+"sub: jmp $1234\nsub2: jmp $1236\n", '65c02', ['zz','h03x'], 'T', 'two hints: only the one guarding pp matters')
H('h04_hint_not_needed', " lda $301\n beq a1\nh04x: jsr sub\n rts\na1: lda #$60\n sta pp\n jsr pp\n rts\n"+PP2+"sub: jmp $1234\n", '65c02', ['h04x'], 'N', 'unconditional store dominates pp; hinted call elsewhere')
H('h05_hint_in_callee', " jsr setp\n"+PPL2+"setp: lda $300\n bne yy\n lda #$60\n sta pp\n rts\nyy:\nh05x: jsr sub\n rts\nsub: rts\n", '65c02', ['h05x'], 'T', 'hint in callee makes store a must-store (wrong hint)')
H('h06c_hint_then_jmp', " lda $301\n beq r\nh06x: jsr sub\n jmp pp\nr: lda #$60\n sta pp\n jmp pp\n"+PPL2+"sub: rts\n", '65c02', ['h06x'], 'T', 'wrong hint; hinted call followed by jmp pp (no ROM)')
H('h06d_hint_then_jmp_p8', " lda $301\n beq r\nh06x: jsr sub\n jmp pp\nr: lda #$60\n sta pp\n jmp pp\n"+PPL2+"sub: rts\n", '65c02', ['h06x'], 'T', 'same, prodos8', extra=P8)
H('h06e_rom_then_jmp', " lda $301\n beq r\n jsr $FF69\n jmp pp\nr: lda #$60\n sta pp\n jmp pp\n"+PP2+"h06y: jsr sub\n rts\nsub: rts\n", '65c02', ['h06y'], 'N', 'ROM call then jmp pp; unrelated hint', extra=P8)
H('h08_hint_then_branch', " lda $301\n beq r\nh06x: jsr sub\n bra pp\nr: lda #$60\n sta pp\n bra pp\n"+PPL2+"sub: rts\n", '65c02', ['h06x'], 'T', 'wrong hint; hinted call then bra pp')
H('h06_hint_plus_rom', " lda $301\n beq r\nh06x: jsr sub\n jmp pp\nr: lda $300\n beq zz\n"+ST+" jmp pp\nzz: jsr $FF69\n"+PP2+"sub: jmp $1234\n", '65c02', ['h06x'], 'T', 'pp reached after hinted call and after ROM no-return call', extra=P8)
H('h06b_rom_only_guard', G0+" jsr $FF69\n"+PP2+"h06y: jsr sub\n rts\nsub: jmp $1234\n", '65c02', ['h06y'], 'N', 'ROM list alone guards pp; hinted call unrelated', extra=P8)
H('h07_hint_jsl', " clc\n xce\n rep #$30\n .a16\n .i16\n"+" lda $300\n beq zz\n sep #$20\n .a8\n lda #$60\n sta pp\n jmp pp\nzz: jsl $012000\n"+PP2, '65816', ['zz'], 'T', 'hint on a jsl')
# (b) indirect forms; jsr $FF69 under prodos8 then pp: LIVE when LC may be touched
def ind(pre, live=True, cpu='65c02'):
    return ("lda $300\n beq zz\n"+ST+" jmp pp\nzz: lda $302\n beq ok\n"+pre+"ok: jsr $FF69\n"+(PPL2 if live else PP2), cpu, P8)
A('i01_jmp_C080', ind(" jmp ($C080)\n"), 'jmp ($C080)')
A('i01b_jmp_C08E', ind(" jmp ($C08E)\n"), 'jmp ($C08E) reads $C08E/$C08F')
A('i01c_jmp_C07F', ind(" jmp ($C07F)\n"), 'jmp ($C07F) reads $C07F/$C080')
A('i02_jmpx_C07E', ind(" ldx $301\n jmp ($C07E,x)\n"), 'jmp (abs,x) X unknown reaching $C08x')
A('i02b_jmpx_ram', ind(" ldx #2\n jmp (tbl,x)\ntbl: .word ok,ok\n", live=False), 'jmp (tbl,x) RAM table, X known')
A('i02c_jmpx_ram_unkX', ind(" ldx $301\n jmp ($BF80,x)\n"), 'jmp ($BF80,x), X unknown: may read up to $C07F/$C080')
A('i03_jsrx', ind(" ldx $301\n jsr ($C07E,x)\n", cpu='65816'), 'jsr (abs,x)')
A('i04_jml_ind', ind(" jml [$C080]\n", cpu='65816'), 'jml [abs]')
A('i04b_jmp_ind_long_C08x', ind(" jmp [$C08C]\n", cpu='65816'), 'jmp [$C08C]')
A('i05_ptr_unknown', ind(" jmp ($03F0)\n"), 'jmp ($03F0) pointer unknown')
A('i06_ptr_known', ind(" lda #<ok\n sta $3F0\n lda #>ok\n sta $3F1\n jmp ($03F0)\n", live=False), 'jmp ($03F0) pointer known -> ok')
A('i07_dead_only', ("lda $300\n beq zz\n"+ST+" jmp pp\n rts\n jmp ($C080)\nzz: jsr $FF69\n"+PP2, '65c02', P8), 'jmp ($C080) only in unreachable bytes')

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
    if n in HINTS:
        open(f'{OUT}/{n}.hints','w').write(''.join(f"noreturn ${lab[h]:06X}\n" for h in HINTS[n]))
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
    if n in TAGX:
        ppl=[l for l in lst.splitlines() if re.search(r'00/%04X:' % lab['pp'], l)]
        tagged='(per noreturn hint)' in ' '.join(ppl); ntag=lst.count('(per noreturn hint)')
        if TAGX[n]=='T' and 'runs as' in ' '.join(ppl) and not tagged: v.append('TAG-MISSING')
        if TAGX[n]=='N' and ntag: v.append(f'TAG-SPURIOUS x{ntag}')
        if TAGX[n]=='T' and tagged and v and all(x.startswith(('WRONG-DOM','FALSE')) for x in v): v=['HINT-TAGGED:'+' '.join(v)]
    verdict = 'OK' if not v else ' '.join(v)
    if n in CTRL: verdict = 'CTL:' + verdict
    res.append((n, cpu, f'verify rc={rc.returncode}', verdict, ','.join(flags), why))
with open(f"{OUT}/results.txt", 'w') as f:
    for r in res: print(' | '.join(map(str, r))); f.write(' | '.join(map(str, r)) + '\n')
