#!/usr/bin/env python3
"""Round-9 probes (page-1 store rule, S/D tracking). Expectations are hand-derived truth.
Usage: adv9.py DUMPAPPLE OUTDIR [--strict-smc]
(from the RetroCodeMess round-9 review; strict expectations added)"""
import sys, os, re, subprocess
H = bytes.fromhex
DA, OUT = sys.argv[1], sys.argv[2]; MODE = sys.argv[3:]; os.makedirs(OUT, exist_ok=True)
# --strict-smc stops decoding the helper in these (its code bytes are reachable by a store): no
# claim either way ('plain') is the expected, sound result there
STRICT_PLAIN = {'p05_m16_overlap', 'p06_mvn_cover', 'p07_mvp_cover', 'e18_sta_srind_y', 'p01_unk_x_zpx', 'p02_unk_y_absy',
    # round 5: under --strict-smc a store with a fully unknown target stops every byte it may reach
    'p03_unk_ptr_store', 'p08_jsr_callee', 'p09_jsr_unknown', 'p10_inc', 'p11_asl', 'p12_rol', 'p13_dec', 'p14_tsb',
    'p15_trb', 'p16_rmb1', 'p17_smb7', 'p21_loop_widen', 'p22_smc_set'}
ORG = 0x2000
HLP = '6885F06885F1' + 'A000C8B1F0F00620EDFD4C4820' + '981865F085F0A5F1690048A5F04860'
HW = b'HELLO WORLD\0'
CS = (0x21C0, H('A9008536A922853760'))   # CSW store, reached only if the frame is rewritten
C = []
def add(n, sub, exp, cpu='65816', plat='none', pre='', why='', call='208021', extra=()):
    parts = [(0x2000, H('4C0021')), (0x2040, H(HLP)),
             (0x2100, H(pre) + H(call) + H('204020') + HW + H('00' if pre.endswith('9A') else '60')), (0x2180, H(sub)), CS, (0x2200, H('C860'))] + list(extra)
    C.append((n, cpu, plat, parts, exp, why))

N=''
KS='A2FF9A'
SET='A90085E0A90385E1'          # ptr $E0 -> $0300 (harmless)
TAIL='A000A9BF91E060'           # sta ($E0),y Y=0 -> frame lo if ptr=$01FE
E=lambda *a: None
# controls
add('c00_ptr_harmless', SET+TAIL, 'ok', cpu='6502', pre=KS, why='ptr $0300 (control)')
add('c01_ptr_frame', 'A9FE85E0A90185E1'+TAIL, 'note', cpu='6502', pre=KS, why='ptr $01FE directly')
# pointer clobber family (truth: pointer may/does point to $01FE -> note)
add('p01_unk_x_zpx', SET+'AE0003A9FE9500A9019501'+TAIL, 'note', cpu='6502', pre=KS, why='sta $00,x / $01,x with X from memory')
add('p02_unk_y_absy', SET+'AC0003A9FE990000A901990100'+TAIL, 'note', cpu='6502', pre=KS, why='sta $0000,y Y unknown')
add('p03_unk_ptr_store', SET+'AD000385E2AD010385E3A000A9FE91E2A90185E1'+TAIL, 'note', cpu='6502', pre=KS, why='indirect store through unknown ptr $E2 may hit $E0')
add('p04_known_ptr2_store', SET+'A9E085E2A90085E3A000A9FE91E2A90185E1'+TAIL, 'note', cpu='6502', pre=KS, why='store through ptr2=$00E0 writes $FE into $E0')
add('p05_m16_overlap', SET+'18FBC220A900FE8DDF00E22038FBA90185E1'+TAIL, 'note', pre=KS, why='m16 sta $00DF writes $E0=$FE')
add('p06_mvn_cover', SET+'A9FE8D0003A9018D010318FBC230A90100A20003A0E000540000E23038FB'+TAIL, 'note', pre=KS, why='mvn $0300->$00E0 2 bytes')
add('p07_mvp_cover', SET+'A9FE8D0003A9018D010318FBC230A90100A20103A0E100440000E23038FB'+TAIL, 'note', pre=KS, why='mvp $0301->$00E1 down 2 bytes')
add('p08_jsr_callee', SET+'200024'+TAIL, 'note', cpu='6502', pre=KS, extra=[(0x2400,H('A9FE85E0A90185E160'))], why='callee writes ptr')
add('p09_jsr_unknown', SET+'201024'+TAIL, 'note', cpu='6502', pre=KS, extra=[(0x2410,H('6C0003'))], why='callee is jmp ($0300) (unknown)')
add('p10_inc', 'A9FD85E0A90185E1E6E0'+TAIL, 'note', cpu='6502', pre=KS, why='ptr $01FD, inc $E0 -> $01FE')
add('p11_asl', 'A97F85E0A90185E106E0'+TAIL, 'note', cpu='6502', pre=KS, why='ptr $017F, asl -> $01FE')
add('p12_rol', 'A97F85E0A90185E11826E0'+TAIL, 'note', cpu='6502', pre=KS, why='clc; rol -> $FE')
add('p13_dec', 'A9FE85E0A90285E1C6E1'+TAIL, 'note', cpu='6502', pre=KS, why='ptr $02FE, dec $E1 -> $01FE')
add('p14_tsb', 'A90085E0A90185E1A9FE04E0'+TAIL, 'note', cpu='65c02', pre=KS, why='tsb $E0 A=$FE -> $01FE')
add('p15_trb', 'A9FE85E0A90385E1A90214E1'+TAIL, 'note', cpu='65c02', pre=KS, why='trb $E1 A=2 -> $01')
add('p16_rmb1', 'A9FE85E0A90385E117E1'+TAIL, 'note', cpu='65c02', pre=KS, why='RMB1 $E1 $03->$01')
add('p17_smb7', 'A97E85E0A90185E1F7E0'+TAIL, 'note', cpu='65c02', pre=KS, why='SMB7 $E0 $7E->$FE')
add('p18_stz_csw', 'A93685E0A90385E164E1'+TAIL, 'note', cpu='65c02', pre=KS, why='ptr $0336, stz $E1 -> $0036 CSW')
add('p19_pea_onto_ptr', SET+'18FBC2303B8D0203A9E1001BF4FE01AD02031BE23038FB'+TAIL, 'note', pre=KS, why='S=$00E1 native, pea $01FE writes $E0/$E1')
add('p20_dp_Dchanged', SET+'18FBC230A9E0005BE23038FBA9FE8500A901850118FBC230A900005BE23038FB'+TAIL, 'note', pre=KS, why='D=$00E0, sta $00/$01 -> $E0/$E1')
add('p21_loop_widen', SET+'A210A9FE95D0CA10F9A90185E1'+TAIL, 'note', cpu='6502', pre=KS, why='loop writes $D0..$E0, then $E1=$01')
add('p22_smc_set', 'A9FE8D8B21A9018D8F21A90085E0A90385E1'+TAIL, 'note', cpu='6502', pre=KS, why='SMC patches SET immediates to $01FE')
add('p23_loop_frame', 'A200A9BF9DF001E8E010D0F860', 'note', cpu='6502', pre=KS, why='loop $01F0..$01FF covers frame')
add('p24_loop_ptr_y', 'A9E085E0A90185E1A000A9BF91E0C8C020D0F960', 'note', cpu='6502', pre=KS, why='(ptr $01E0),y Y 0..$1F covers frame')
add('p25_loop_safe', 'A200A9BF9DA001E8E010D0F860', 'ok', cpu='6502', pre=KS, why='loop $01A0..$01AF below S (LOW if note)')
# classifier edges
add('e01_dbrFF_absx_wrap_csw', '18FBE230A9FF48ABA237A9BFFFFFFF'[:0]+'18FBA9FF48ABA237A9BF9DFFFFA90048AB38FB60', 'note', pre=KS, why='DBR=$FF sta $FFFF,x X=$37 -> $00:0036 CSW')
add('e02_longx_wrap_csw', '18FBA237A9BF9FFFFFFF38FB60', 'note', pre=KS, why='sta $FFFFFF,x X=$37 -> $000036 CSW')
add('e03_dbr0_absx_cross', '18FBA237A9BF9DFFFF38FB60', 'ok', pre=KS, why='DBR=0 sta $FFFF,x X=$37 -> $01:0036 (not CSW; LOW if note)')
add('e04_long_00FFFF_m16', '18FBC220A9BFBF8FFFFF00E22038FB60', 'ok', pre=KS, why='m16 sta $00FFFF -> $00FFFF,$010000 (LOW if note)')
add('e05_long_0035_m16', '18FBC220A9BFBF8F350000E22038FB60', 'note', pre=KS, why='m16 sta $000035 writes $0036 CSW')
add('e06_emu_dpx_wrap_csw', 'A237A9BF95FF60', 'note', cpu='6502', pre=KS, why='emu sta $FF,x X=$37 -> $36 CSW')
add('e07_nat_dpx_nowrap', '18FBA237A9BF95FF38FB60', 'any', pre=KS, why='native sta $FF,x X=$37 -> $0136')
add('e08_emu_dpind_wrap', 'A9FE85FFA90185008D0001'[:0]+'A9FE85FFA9018500A9038D0001A000A9BF91FF60', 'note', cpu='6502', pre=KS, why='(dp $FF) hi from $00 -> $01FE')
add('e09_emu_sr_01', '18FB38FBA9BF830160', 'note', pre=KS, why='emu sta $01,s S=$FD -> $01FE')
add('e10_mvn_dest1_dbr', '18FBC230A90000A20003A00003540100E23038FBA9BF8DFE01A90048AB60', 'ok', pre=KS, why='after mvn dst=1 DBR=1: sta $01FE is $01:01FE (LOW if note)')
add('e11_mvn_cover_frame', '18FBC230A90F00A20003A0F001540000E23038FB60', 'note', pre=KS, why='mvn dest $01F0..$01FF')
add('e12_mvp_cover_frame', '18FBC230A90100A20103A0FF01440000E23038FB60', 'note', pre=KS, why='mvp dest $01FE..$01FF')
add('e13_mvp_below', '18FBC230A90100A20103A0FC01440000E23038FB60', 'ok', pre=KS, why='mvp dest $01FB..$01FC (LOW if note)')
add('e14_mvn_wrap64k', '18FBC230A9FF01A20003A0FFFF540000E23038FB60', 'note', pre=KS, why='mvn dest $FFFF then wraps $0000..$01FE')
add('e15_sta_dlong_y', 'A9FE85E0A90185E1A90085E2A000A9BF97E060', 'note', pre=KS, why='$97 sta [$E0],y -> $00:01FE')
add('e16_sta_dlong_csw', 'A93685E0A90085E185E2A000A9BF97E060', 'note', pre=KS, why='$97 sta [$E0],y -> $000036 CSW')
add('e17_sta_dlong_bank1', 'A9FE85E0A90185E185E2A000A9BF97E060', 'ok', pre=KS, why='sta [$E0],y -> $01:01FE (LOW if note)')
add('e18_sta_srind_y', '18FBC230A9FE0148A90000 '[:0]+'18FBC230F4FE01A00000A9BF00E2309301686838FB60', 'note', pre=KS, why='pea $01FE; sta ($01,s),y -> $01FE (known-open: always unknown)')
def image(parts):
    img = bytearray()
    for a, b in parts:
        o = a - ORG
        if len(img) < o + len(b): img.extend(bytes(o + len(b) - len(img)))
        img[o:o+len(b)] = b
    return bytes(img)
bad = 0; rows = []
for n, cpu, plat, parts, exp, why in C:
    img = image(parts); b = f'{OUT}/{n}.bin'; open(b, 'wb').write(img); s = f'{OUT}/{n}.s'
    args = [DA, '-q', '--cpu', cpu, '--org', '2000', '--platform', plat] + MODE + ['-o', s, '--verify', b]
    rc = subprocess.run(args, capture_output=True, text=True)
    t = open(s).read() if os.path.exists(s) else ''
    res = 'note' if 'not proven' in t else ('resolved' if 'returns past' in t else 'plain')
    prob = []
    if MODE and n in STRICT_PLAIN and exp == 'note' and res == 'plain': exp = 'any'
    if exp == 'note' and res != 'note': prob.append('FALSE-CLAIM' if res == 'resolved' else 'expected note, got ' + res)
    if exp == 'ok' and res != 'resolved': prob.append('OVER-NOTE')
    if rc.returncode: prob.append(f'rc={rc.returncode} {rc.stderr.strip()[:80]}')
    bad += bool(prob); rows.append(' | '.join([n, cpu, plat, res, 'OK' if not prob else ';'.join(prob), why]))
print('\n'.join(rows)); print(f'== {len(rows)} cases, {bad} with problems')
