#!/bin/sh
# CPU auto-detect for raw files (no --cpu).
# Rule: 65816 only on flow evidence (clc;xce with known carry, or a 65816-only opcode
# such as BRL/JSL/REP/SEP/PEA reached on flow). COP/WDM ($02/$42) are not evidence.
# A hit counts only where a 65C02 decode of the same flow reaches the same address as an
# instruction start (no slip after a length-differing opcode, no jump into data).
# Tie -> 65C02 plus a note. --cpu always overrides. Listing must state the choice:
#   ; cpu: <cpu> (auto: <reason>)   and the matching .setcpu line.
DA=${DA:-./dumpapple}; T=tests/cpu_auto; O=tests/out/cpu_auto
mkdir -p $O; pass=0; fail=0
ok(){ pass=$((pass+1)); echo "ok   $1"; }; ko(){ fail=$((fail+1)); echo "FAIL $1"; }
for s in $T/*.s; do n=$(basename $s .s)
  ca65 -o $O/$n.o $s && ld65 -t none -o $O/$n.bin $O/$n.o || { ko "$n build"; continue; }; done
chk(){ # name expected-setcpu [extra args]
  n=$1; want=$2; shift 2
  "$DA" --org 0x2000 --verify "$@" -o $O/$n.lst $O/$n.bin >$O/$n.log 2>&1 \
    && ok "$n verify" || ko "$n verify"
  grep -q "^\.setcpu \"$want\"" $O/$n.lst && ok "$n setcpu $want" || ko "$n setcpu $want (got: $(grep -m1 '^\.setcpu' $O/$n.lst))"
  if [ $# -eq 0 ]; then grep -qi "; cpu: $want (auto" $O/$n.lst && ok "$n note" || ko "$n note"; fi; }
chk c1_native       65816
chk c2_plain6502    65C02
chk c3_stray82      65C02
chk c4_nop02        65C02
chk c5_unknowncarry 65C02
chk c6_rockwell     65C02
chk c7_ptrdata      65C02
chk c8_secxce       65C02
chk c9_jsl          65816
chk c10_strdata     65C02
chk c11_straypea    65C02
chk c12_textrep     65C02
chk c13_three       65816
chk c14_bbsdesync   65C02
chk c15_bbrdesync   65C02
chk c16_x3desync    65C02
chk c17_midjump     65C02
chk c18_datastop    65C02
chk c19_textweak    65C02
chk c20_nativelong  65816
chk c21_tablejsl    65816
chk c22_dpbefore    65816
chk c23_longbefore  65816
chk c24_longjsl     65816
chk c25_bbsmulti    65C02
chk s01_bbscpx      65C02
chk s02_bbssbc      65C02
chk s03_bbsora      65C02
chk s06_bbrwait     65C02
chk c26_longsta     65816
chk c27_longxjsl    65816
chk c28_phkplb      65816
chk c29_txyrep      65816
chk c30_endjmpi 65C02
chk n06b_phkplb16   65816
chk n06c_phkplbx16  65816
chk d01_txy16       65816
chk d02_phbrep16    65816
chk x07_emuclcxce   65816
chk x08_xce16       65816
chk x09_emuclcxcex  65816
chk x10_emurep      65816
chk x11_unkxce      65816
chk x12_emuplp      65816
chk y06_cmpxce      65816
"$DA" --org 0x2000 --platform prodos8 -o $O/x07p8.lst $O/x07_emuclcxce.bin >$O/x07p8.log 2>&1 && grep -qi "; cpu: 65816 (auto" $O/x07p8.lst && ok "x07 prodos8 (E starts emulation) 65816" || ko "x07 prodos8 65816"
chk c30_endrti 65C02
chk c30_endbra 65C02
chk c30_endjmp 65C02
chk c30_endrts 65C02
# c1 under auto must decode the native code after the debug header
grep -q "rep" $O/c1_native.lst 2>/dev/null && ok "c1 decodes native code" || ko "c1 decodes native code"
cp $O/c1_native.bin $O/c1_override.bin
chk c1_override     65C02 --cpu 65c02      # override wins
grep -q '^; cpu:' $O/c1_override.lst && ko 'override has no auto note' || ok 'override has no auto note'
echo "cpu_auto: $pass passed, $fail failed"; [ $fail -eq 0 ]
