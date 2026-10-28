#!/usr/bin/env python3
"""Synthetic edge-case probes (store classification, --entry, patched transfers, ...).
Every image is built here from a few hand-written 6502 bytes; no third-party code.
Usage: edge_synth.py DUMPAPPLE OUTDIR
Each case: id, org, {addr: hex bytes}, extra args, expected stop count, strings the listing
must contain, strings it must not contain. Every case also has to pass --verify."""
import sys, os, re, subprocess
DA, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
H = bytes.fromhex
CALL = {0x0300: '2010034C2003', 0x0320: '4C0804', 0x0408: 'A90160'}
def img(org, parts):
    end = max(a + len(H(b)) for a, b in parts.items())
    buf = bytearray(end - org)
    for a, b in parts.items(): buf[a - org:a - org + len(H(b))] = H(b)
    return bytes(buf)
C = []
def case(n, org, parts, args, stops, has=(), hasnt=()): C.append((n, org, parts, args, stops, has, hasnt))
# 1: indexed stores into a code page
case('s1a_bounded_x_full_page', 0x300, {**CALL, 0x310: 'A9EAA2009D0004E8D0FA60'}, [], 1)          # X=0..255 really writes $0408
case('s1b_unknown_x', 0x300, {**CALL, 0x310: 'A9EA9D000460'}, [], 0, ['lda #$01'])
case('s1b_unknown_x_strict', 0x300, {**CALL, 0x310: 'A9EA9D000460'}, ['--strict-smc'], 1)
case('s1c_inx_cpx_bne', 0x300, {**CALL, 0x310: 'A9EAA2009D0004E8E004D0F860'}, [], 0, ['lda #$01'])
case('s1c_inx_cpx_bne_strict', 0x300, {**CALL, 0x310: 'A9EAA2009D0004E8E004D0F860'}, ['--strict-smc'], 0, ['lda #$01'])
case('s1d_dex_cpx_bne', 0x300, {**CALL, 0x310: 'A9EAA2079D0004CAE003D0F860'}, ['--strict-smc'], 0, ['lda #$01'])   # X=7..4: $0404-$0407
case('s1e_cpx_reaches', 0x300, {**CALL, 0x310: 'A9EAA2009D0004E8E009D0F860'}, [], 1)       # X=0..8 writes $0408
# 2: on-disk entry
case('s2a_entry_jmp_unknown_y', 0x3FD, {0x3FD: '4C1004', 0x410: 'A400A900990003' + '60'}, [], 0, ['jmp'])
case('s2b_entry_jmp_bounded_y', 0x3FD, {0x3FD: '4C1004', 0x410: 'A00FA9009900038810FA60'}, [], 0, ['jmp'])
case('s2c_strict_entry_wins', 0x3FD, {0x3FD: '4C1004', 0x410: 'A400A900990003' + '60'}, ['--strict-smc', '--entry', '3FD'], 0, ['jmp', 'decoded as on disk although a store may change it'])
case('s2d_strict_no_entry', 0x3FD, {0x3FD: '4C1004', 0x410: 'A400A900990003' + '60'}, ['--strict-smc'], 0, ['jmp'])
# strict: the entry run stays code up to the questionable point; a run a branch re-enters is not trusted
case('s2g_strict_entry_run', 0x300, {0x300: 'A5008D0503EA60'}, ['--strict-smc'], 1, ['sta a:$0305'], ['nop'])
case('s2i_strict_entry_patched', 0x300, {0x300: 'A5008D0003EA60'}, ['--strict-smc'], 0, ['sta a:$0300', 'nop'])
# strict: the entry run follows jmp abs (same rules there); a call, also to ROM, ends it
case('s2j_strict_jmp_run', 0x300, {0x300: 'A5004C1003', 0x310: 'A600EA20180360', 0x318: 'A900910060'}, ['--strict-smc'], 2, ['ldx z:$00', 'nop', 'jmp', 'runs from the entry before any store'])
case('s2k_strict_jmp_join', 0x300, {0x300: 'A500F00C4C1003', 0x310: 'A600EA20180360', 0x318: 'A900910060'}, ['--strict-smc'], None, ['beq'], ['ldx', 'nop'])
case('s2l_strict_rom_call_ends', 0x300, {0x300: 'A5002058FC8D050360'}, ['--strict-smc'], 1, ['jsr'], ['sta'])
case('s2m_strict_header_off', 0x300, {0x300: 'A90160'}, ['--strict-smc'], 0, ['seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)'])
case('s2n_strict_header_one', 0x300, {0x300: 'A90160'}, ['--strict-smc', '--no-auto-region'], 0, ['seed targets are off (--seed-targets turns them back on)'], ['auto regions are off'])
# --strict-smc entry run: a re-entered site is dropped only when a store's range covers it
case('s4h_strict_loop_body_kept', 0x300, {0x300: 'A000A9EA990003C8C002D0F660'}, ['--strict-smc'], 0, ['lda #$EA                    ; 00/0302', 'iny                         ; 00/0307', 'bne L000302'], ['code flow reached here but decoding stopped'])
case('s4i_strict_loop_body_hit', 0x300, {0x300: 'A000A9EA990203C8C002D0F660'}, ['--strict-smc'], 1, ['decoding stopped: opcode may be changed by a store'], ['lda #$EA                    ; 00/0302'])
case('s4j_strict_join_chain', 0x300, {0x300: 'A200A510EAA5118D0403CAD0F560'}, ['--strict-smc'], 1, ['lda z:$10                   ; 00/0302'], ['nop                         ; 00/0304'])
case('s2h_strict_run_rejoined', 0x300, {0x300: 'A200E8E00AD0FB8D0203' + '60'}, ['--strict-smc'], 1, ['ldx #$00'], ['inx'])
case('s2e_entry_wins_overlap', 0x300, {0x300: '2CA90160'}, ['--entry', '301'], 0, ['lda #$01', 'overlaps --entry'])
case('s2f_overlap_no_entry', 0x300, {0x300: '2CA90160'}, [], 0, ['bit'], ['overlaps --entry'])
# 3: patched operands
case('s3a_imm_known', 0x300, {0x300: 'A9058D11034C1003', 0x310: 'A9008D000460'}, [], 0)
case('s3f_patched_jsr', 0x300, {0x300: 'A5008D1103A5018D12034C1003', 0x310: '202003A90160', 0x320: '60'}, [], 0, ['jsr', 'lda #$01', 'return path followed'])
case('s3g_patched_jmp', 0x300, {0x300: 'BD00048D1103BD01048D12034C1003', 0x310: '4C0000'}, [], 0, ['jmp', 'jmp target may be modified'])
# 8: constant indirect targets
case('s8a_jmp_ind_const', 0x300, {0x300: 'A91085DEA90385DF6CDE00', 0x310: 'A90160'}, [], 0, ['lda #$01', 'constant pointer'])
case('s8b_jmp_ind_stub', 0x300, {0x300: 'A91085DEA90385DF200C0360', 0x30C: '6CDE00', 0x310: 'A90160'}, [], 0, ['lda #$01', 'constant pointer'])
case('s8c_jmp_ind_hi_mem', 0x300, {0x300: 'A91085DEA50085DF6CDE00', 0x310: 'A90160'}, [], 0, [], ['constant pointer'])
case('s8d_jmp_ind_join', 0x300, {0x300: 'A500F004A910D002A92085DEA90385DF6CDE00'}, [], 0, [], ['constant pointer'])
case('s8e_jmp_ind_clobbered', 0x300, {0x300: 'A91085DEA90385DFE6DE6CDE00', 0x310: 'A90160'}, [], 0, [], ['constant pointer'])
# 4: copy-then-jump becomes a region
case('s4a_monitor_move', 0x4B00, {0x4B00: 'A92085 3CA94B853DA92F853EA94B853FA9008542A90C8543A000202CFE4C000C'.replace(' ', ''), 0x4B20: 'A90160', 0x4B2F: '00'}, [], 0, ['auto region', 'lda #$01'])
case('s4b_page_copy', 0x400, {0x400: 'A000B90005990003C8D0F74C0303', 0x503: 'A90160', 0x5FF: '00'}, [], 0, ['auto region', 'lda #$01'])
case('s4c_no_auto_region', 0x400, {0x400: 'A000B90005990003C8D0F74C0303', 0x503: 'A90160', 0x5FF: '00'}, ['--no-auto-region'], 0, [], ['auto region'])
case('s4d_dest_in_file', 0x400, {0x400: 'A000B90005998004C8D0F74C8304', 0x5FF: '00'}, [], None, [], ['auto region'])
# 5: flow leaves the image: in-image call targets are seeded
case('s5a_seed_after_exit', 0x4000, {0x4000: '4C1040002008406' + '0A90160', 0x4010: '4C2000'}, [], 0, ['auto entry', 'lda #$01'])
case('s5b_no_seed', 0x4000, {0x4000: '4C10400020084060A90160', 0x4010: '4C2000'}, ['--no-seed-targets'], 0, [], ['auto entry'])
case('s5c_fill_target', 0x4000, {0x4000: '4C10400020084060' + '8D' * 8, 0x4010: '4C2000'}, [], 0, [], ['auto entry'])
case('s5d_no_exit', 0x4000, {0x4000: '4C10400020084060A90160', 0x4010: '60'}, [], 0, [], ['auto entry'])
# follow-up: down-counting loops through 0, Y loops, X- and Y-indexed page copies onto an auto region
case('s1f_dex_cpx_ff', 0x300, {**CALL, 0x310: 'A9EAA2039D0004CAE0FFD0F860'}, ['--strict-smc'], 0, ['lda #$01'])     # X=3..0: $0400-$0403
case('s1g_dey_cpy_ff', 0x300, {**CALL, 0x310: 'A9EAA003990004' '88C0FFD0F860'}, ['--strict-smc'], 0, ['lda #$01'])
case('s1h_dex_cpx_ff_reaches', 0x300, {**CALL, 0x310: 'A9EAA2089D0004CAE0FFD0F860'}, ['--strict-smc'], 1)          # X=8..0 writes $0408
case('s1i_iny_cpy', 0x300, {**CALL, 0x310: 'A9EAA000990004C8C004D0F860'}, ['--strict-smc'], 0, ['lda #$01'])
for m in ([], ['--strict-smc', '--auto-region']):
    t = '_strict' if m else ''
    case('s4e_page_copy_x' + t, 0x400, {0x400: 'A200BD00059D0003E8D0F74C0303', 0x503: 'A90160', 0x5FF: '00'}, m, 0, ['auto region', 'lda #$01'])
    case('s4f_page_copy_y' + t, 0x400, {0x400: 'A000B90005990003C8D0F74C0303', 0x503: 'A90160', 0x5FF: '00'}, m, 0, ['auto region', 'lda #$01'])
# --strict-smc: auto regions are off unless asked for
case('s4g_strict_region_off', 0x400, {0x400: 'A200BD00059D0003E8D0F74C0303', 0x503: 'A90160', 0x5FF: '00'}, ['--strict-smc'], 0, [], ['note: auto region:'])
fails = 0
for n, org, parts, args, stops, has, hasnt in C:
    b = os.path.join(OUT, n + '.bin'); s = os.path.join(OUT, n + '.s')
    open(b, 'wb').write(img(org, parts))
    cmd = [DA, '--raw', '--cpu', '6502', '--org', '%X' % org, '--verify', '-o', s] + args + [b]
    r = subprocess.run(cmd, capture_output=True, text=True)
    m = re.search(r'(\d+) instructions \((\d+) bytes code\), \d+ labels, (\d+) stop', r.stderr)
    lst = open(s).read() if os.path.exists(s) else ''
    why = []
    if r.returncode != 0: why.append('rc=%d' % r.returncode)
    if not m: why.append('no summary')
    elif stops is not None and int(m.group(3)) != stops: why.append('stops %s != %d' % (m.group(3), stops))
    for t in has:
        if t not in lst: why.append('missing %r' % t)
    for t in hasnt:
        if t in lst: why.append('unexpected %r' % t)
    print('%s | %s | %s' % (n, 'OK' if not why else 'BAD', '; '.join(why) or (m.group(0) if m else '')))
    fails += bool(why)
print('== %d cases, %d bad' % (len(C), fails))
sys.exit(1 if fails else 0)
