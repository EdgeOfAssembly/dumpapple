#!/usr/bin/env python3
"""Width-sound r3 probes (5e8dcc3). ca65 source at ORG (default $2000).
MUST* labels: truly executed, must be an instruction start.  DEAD..DEADEND: never
executed as an opcode; an instruction start inside = FALSE-CODE.
Usage: advws3.py DUMPAPPLE OUTDIR [--strict-smc]
(from the RetroCodeMess verify-5e8dcc3 review, 50 probes)"""
import sys, os, re, subprocess
DA, OUT = sys.argv[1], sys.argv[2]; MODE = sys.argv[3:]; os.makedirs(OUT, exist_ok=True)
C = []
def add(n, src, cpu='65816', why='', org=0x2000, extra=()): C.append((n, cpu, src, org, list(extra), why))
FALL = "MUST: lda #$C1\n jsr $FDED\n rts\n"
TAIL = " lda #$60\nDEAD: .byte $60,$A9,$00,$8D,$00,$C0,$60\nDEADEND:\n"   # m8: lda #$60;rts  m16: lda #$6060 then DEAD
TAILM = " lda #$60\n .byte $60\nDEAD: .byte $A9,$00,$8D,$00,$C0,$60\nDEADEND:\n"  # real path m8 (rts at .byte $60)
# ---------- exception (g): known-value patches to one-byte ops
add('g01_nop_to_xce', "clc\n xce\n lda #$FB\n sta pp\n rep #$20\n sec\npp: nop\n"+TAILM, why='nop->xce with C=1: E=1, m8; real lda #$60;rts')
add('g02_nop_to_plp', "clc\n xce\n lda #$28\n sta pp\n php\n rep #$20\npp: nop\n"+TAILM, why='nop->plp pulls m8 P')
add('g03_nop_to_rti', "lda #$40\n sta pp\npp: nop\nDEAD: .byte $A9,$00,$8D,$00,$C0,$60\nDEADEND:\n", '65c02', 'nop->rti: nothing after pp executes')
add('g03b_nop_to_rtl', "clc\n xce\n lda #$6B\n sta pp\npp: nop\nDEAD: .byte $A9,$00,$8D,$00,$C0,$60\nDEADEND:\n", why='nop->rtl')
add('g04_nop_to_xba', "clc\n xce\n lda #$EB\n sta pp\n rep #$20\npp: nop\n .a16\n lda #$6060\n .a8\nMUST: rts\n", why='nop->xba: width unchanged (stop or keep both fine)')
add('g05_nop_to_tcd', "clc\n xce\n lda #$5B\n sta pp\n rep #$20\n .a16\n lda #$2000\n sep #$20\n .a8\n ldx #$38\npp: nop\n .byte $86, <cc\ncc: clc\n xce\n rep #$20\n"+TAILM, why='nop->tcd (A=$2000): stx dp then hits cc (clc->sec)')
add('g06_nop_to_tcs', "clc\n xce\n lda #$1B\n sta pp\n rep #$20\n .a16\n lda #$01F0\n .a8\n sep #$20\npp: nop\n rts\n", why='nop->tcs: stack moved, rts frame unknown (check notes)')
add('g07_nop_to_php_rts', "jsr sub\nMUST0: nop\n rts\nsub: lda #$08\n sta pp\npp: nop\n rts\n", '6502', 'nop->php: rts returns elsewhere (INFO, pre-existing)')
add('g08_clc_to_sec_xce', "lda #$38\n sta cc\ncc: clc\n xce\n rep #$20\n"+TAILM, why='clc->sec ahead of xce (both flag-only): carry must be unknown')
add('g08b_clc_nop_xce', "lda #$38\n sta cc\n clc\ncc: nop\n xce\n rep #$20\n"+TAILM, why='nop->sec between clc and xce')
add('g08d_sec_in_callee', "lda #$38\n sta cc\n clc\n jsr sub\n xce\n rep #$20\n"+TAILM+"sub:\ncc: nop\n rts\n", why='nop->sec inside callee before xce')
add('g08e_sec_to_clc_xce', "lda #$18\n sta cc\ncc: sec\n xce\n rep #$20\n lda #$60\nDEAD: .byte $60\nDEADEND:\n rts\n", why='sec->clc: real native m16 lda #$6060; rts. rts at DEAD = false')
add('g08f_cld_to_sec_xce', "lda #$38\n sta cc\n clc\ncc: cld\n xce\n rep #$20\n"+TAILM, why='cld->sec')
add('g09_nop_sec_bcc', "clc\n lda #$38\n sta pp\npp: nop\n bcc ov\n"+FALL+"ov: rts\n", '6502', 'nop->sec ahead of bcc: bcc not taken, MUST runs')
add('g09b_nop_clc_bcs', "sec\n lda #$18\n sta pp\npp: nop\n bcs ov\n"+FALL+"ov: rts\n", '6502')
add('g09c_clv_bvc', "lda #$40\n bit kk\n lda #$B8\n sta pp\npp: nop\n bvs ov\n"+FALL+"ov: rts\nkk: .byte $40\n", '6502', 'nop->clv ahead of bvs')
add('g10_nop_to_lda_imm', "lda #$A9\n sta pp\n clc\npp: nop\n xce\n rep #$20\n"+TAILM, why='nop->lda # eats xce: E=1 m8')
add('g10b_nop_to_sep', "clc\n xce\n lda #$E2\n sta pp\n rep #$20\npp: nop\n clv\n"+TAILM, why='nop->sep eats clv: sep #$B8 sets m')
add('g11_unknown_value', "lda $300\n sta pp\n clc\npp: nop\n xce\n rep #$20\n"+TAILM, why='unknown value: must stop')
add('g11b_unknown_value_x', "ldx $300\n stx pp\n clc\npp: nop\n xce\n rep #$20\n"+TAILM, why='unknown value via stx')
add('g12_two_values', "ldx $300\n beq b\n lda #$EA\n sta cc\n jmp go\nb: lda #$38\n sta cc\ngo: clc\ncc: nop\n xce\n rep #$20\n"+TAILM, why='same byte, nop or sec on two paths')
add('g12b_two_values_seq', "lda #$EA\n sta cc\n lda #$38\n sta cc\n clc\ncc: nop\n xce\n rep #$20\n"+TAILM, why='two sequential stores, last is sec')
add('g12c_two_vals_loop', "ldy #1\nlp: lda tb,y\n sta cc\n dey\n bpl lp\n clc\ncc: nop\n xce\n rep #$20\n"+TAILM+"tb: .byte $38,$EA\n", why='value from table (unknown) twice')
add('g13_overlap_rep_operand', "clc\n xce\n sep #$30\n lda #$38\n sta rr+1\n ldx $300\n beq b\nrr: rep #$18\n lda #$60\nDEAD: .byte $60\nDEADEND:\n rts\nb: rep #$20\n jmp rr+1\n", why='byte is clc opcode on one path and rep operand on other; clc->sec flips rep #$18->#$38 (m16)')
add('g14_stz_known', "clc\n xce\n stz cc\n sec\ncc: nop\n xce\n rep #$20\n"+TAILM.replace(' lda #$60',' lda #$60',1), why='stz: nop->brk (not flag-only)')
add('g15_mvn_known', "clc\n xce\n rep #$30\n .a16\n .i16\n ldx #src\n ldy #cc\n lda #0\n mvn #0,#0\n sep #$30\n .a8\n .i8\n bra cc\ncc: clc\n xce\n rep #$20\n"+TAILM+"src: .byte $38\n", why='mvn (known source byte) writes sec over clc that feeds xce')
# ---------- fixpoint / operand / offset
add('f01_jmp_operand', "lda #<oth\n sta jj+1\n lda #>oth\n sta jj+2\njj: jmp orig\noth: rts\norig:\nDEAD: .byte $A9,$00,$8D,$00,$C0,$60\nDEADEND:\n", '6502', 'jmp operand patched: orig never runs')
add('f02_branch_offset_mid', "lda #1\n sta br+1\n clc\nbr: bcc ov\n .byte $A9\nMUST: rts\nov:\nDEAD: .byte $FF\nDEADEND:\n", '6502', 'offset->1 lands mid; ov never')
add('f03_imm16_hi', "clc\n xce\n rep #$20\n .a16\n lda #$1234\n sep #$20\n .a8\n lda #$60\n sta li+2\n rep #$20\n .a16\nli: lda #$1234\n .a8\nMUST: rts\n", why='store hits 16-bit imm high byte only (operand): ok to keep')
add('f04_loop_counter_patched', "clc\n xce\n lda #$40\n sta lx+1\nlx: ldx #2\nlp: lda #$38\n sta base,x\n dex\n bpl lp\n bra go\nbase: .res $40,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM+"go: jmp cc\n", why='ldx #imm operand patched to $40: store reaches base+$40 = cc')
add('f05_loop_unknown_start', "clc\n xce\n ldx $300\nlp: lda #$38\n sta base,x\n dex\n bpl lp\n bra go\nbase: .res $40,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM+"go: jmp cc\n", why='dex/bpl X unknown')
add('f06_loop_extra_inx', "clc\n xce\n ldx #3\nlp: lda #$38\n sta base,x\n inx\n inx\n dex\n bpl lp\n bra go\nbase: .res $40,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM+"go: jmp cc\n", why='net +1 per iter: X 3..$7F hits base+$40')
add('f06b_loop_inx_bne', "clc\n xce\n ldx #3\nlp: lda #$38\n sta base,x\n dex\n inx\n inx\n bne lp\n bra go\nbase: .res $40,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM+"go: jmp cc\n", why='X 3..$FF')
add('f07_loop_second_entry', "clc\n xce\n ldx $301\n bne ent\n ldx #3\nlp: lda #$38\nent: sta base,x\n dex\n bpl lp\n bra go\nbase: .res $40,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM+"go: jmp cc\n", why='jump into loop with other X')
add('f07b_loop_self_patch', "clc\n xce\nouter: ldx #2\nlp: lda #$40\n sta outer+1-2,x\n dex\n bpl lp\n lda $300\n bne outer\n jmp go\n .res $3B,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM+"go: lda #$38\n ldx #0\n jmp cc\n", why='store patches its own loop counter (2nd pass X=$40)')
add('f08_full_bank_16', "clc\n xce\n rep #$10\n ldx $300\n lda #$38\n sta $0000,x\n sep #$10\ncc: clc\n xce\n rep #$20\n"+TAILM, why='16-bit unknown X over $0000: whole bank -> assumed')
add('f08b_16_base0100', "clc\n xce\n rep #$10\n ldx $300\n lda #$38\n sta $0100,x\n sep #$10\ncc: clc\n xce\n rep #$20\n"+TAILM, why='16-bit unknown X over $0100: 64K but not aligned')
add('f08c_99pct_loop', "clc\n xce\n rep #$10\n .i16\n ldx #$FF00\nlp: lda #$38\n sta $0000,x\n dex\n bne lp\n sep #$10\n .i8\ncc: clc\n xce\n rep #$20\n"+TAILM, why='counted 16-bit loop $0001..$FF00 (99.6%): bounded, must hit cc')
add('f08d_99pct_y8_long', "clc\n xce\n ldx $300\n lda #$38\n sta f:$001F80,x\ncc: clc\n xce\n rep #$20\n"+TAILM, why='8-bit X over $1F80: bounded, hits cc')
add('f09_bank_cross', "clc\n xce\n lda #1\n pha\n plb\n ldx $300\n lda #$38\n sta $FF80,x\ncc: clc\n xce\n rep #$20\n"+TAILM, org=0x020000, why='DBR=1, 8-bit X over $FF80 crosses to $02xxxx (code at $020000)')
add('f10_dp_known', "clc\n xce\n pea $2000\n pld\n ldx $300\n lda #$38\n sta $10,x\n nop\n .res $40,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM, why='D=$2000, sta $10,x reaches $2010..$210F')
add('f10b_dp_pea_patched', "clc\n xce\n lda #$20\n sta pp+2\npp: pea $1000\n pld\n lda #$38\n .byte $85, <cc\n .res $40,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM, why='pea operand patched: D=$2000, sta $60 hits $2060?')
add('f10c_dp_two_D', "clc\n xce\n lda $300\n beq la\n pea $2000\n bra lb\nla: pea $3000\nlb: pld\n lda #$38\n .byte $85, <cc\n .res $10,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM, why='D in {$2000,$3000}; sta dp hits cc on one')
add('f04b_ldx_operand_patched', "clc\n xce\n lda #$40\n sta lx+1\nlx: ldx #0\n lda #$38\n sta base,x\n bra go\nbase: .res $40,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM+"go: jmp cc\n", why='ldx #0 operand patched to $40 (no loop)')
add('f10d_dp_lda_tcd_patched', "clc\n xce\n lda #$20\n sta li+2\n rep #$20\n .a16\nli: lda #$1000\n tcd\n sep #$20\n .a8\n lda #$38\n .byte $85, <cc\n .res $10,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM, why='lda #imm16 operand patched then tcd')
add('f10e_dp_pea_patched_unk', "clc\n xce\n lda $300\n sta pp+2\npp: pea $1000\n pld\n lda #$38\n .byte $85, <cc\n .res $10,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM, why='pea operand patched with unknown value')
add('f10f_dp_one_D_join', "clc\n xce\n lda $300\n beq la\n pea $2000\n bra lb\nla: pea $2000\nlb: pld\n lda #$38\n .byte $85, <cc\n .res $10,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM, why='same D on both paths')
add('f11b_ptr_operand_patched', "lda #$20\n sta lp+1\nlp: lda #$10\n sta $FB\n lda #<cc\n sta $FA\n ldy #0\n lda #$38\n sta ($FA),y\n clc\n xce\n bra go\n .res $10,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM+"go: jmp cc\n", why='pointer hi from patched lda # operand: real ptr=cc')
add('f11_ptr_known_range', "lda #<base\n sta $FA\n lda #>base\n sta $FB\n ldy $300\n lda #$38\n sta ($FA),y\n clc\n xce\n bra go\nbase: .res $20,$EA\ncc: clc\n xce\n rep #$20\n"+TAILM+"go: jmp cc\n", why='(zp),y known pointer, Y unknown')
add('f12_mutual', "clc\n xce\ns1: sep #$10\n ldx $300\n lda #$C2\n sta s2-$80,x\ns2: sep #$10\n ldy $301\n lda #$C2\n sta s1,y\n sep #$20\n"+TAILM, why='two stores/setters mutually reachable')
CTRL = {'g08c_clc_nop_ctl','f03_imm16_hi','g04_nop_to_xba'}
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
