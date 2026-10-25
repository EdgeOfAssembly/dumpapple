#!/bin/sh
# dumpapple test suite: round trip (byte-identical rebuild), gold listings,
# OMF loader expectations, da65 cross-check, CLI conventions.
# UPDATE_GOLD=1 ./tests/run_tests.sh   regenerates tests/gold/*.s
cd "$(dirname "$0")/.."
DA=${DA:-./dumpapple}
OUT=tests/out
rm -rf $OUT; mkdir -p $OUT $OUT/strict tests/gold tests/gold/strict tests/omf tests/progs   # no stale outputs
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "PASS $1"; }
bad() { fail=$((fail+1)); echo "FAIL $1"; }
# T1: a listing check only counts when every listing it reads exists and is non-empty.
nonempty() { for f; do [ -s "$f" ] || return 1; done; [ $# -gt 0 ]; }
# negative check: true ("bad") if a listing is missing/empty or the pattern is found
ngrep() { o=$1; pat=$2; shift 2; nonempty "$@" || return 0; grep $o -- "$pat" "$@" >/dev/null 2>&1; }

tests/build_progs.sh || { echo "cannot build test programs (need ca65/ld65)"; exit 1; }
python3 tests/gen_allops.py tests/progs
python3 tests/gen_disp.py tests/progs
python3 tests/mk_mvn_omf.py tests/progs/mvn_reloc.omf
python3 tests/mk_held_omf.py tests/progs/held_jsl.omf jsl
python3 tests/mk_held_omf.py tests/progs/held_data.omf data
python3 tests/mk_jt_omf.py tests/progs/jt.omf
python3 tests/mk_jt_omf.py tests/progs/jt_trunc.omf trunc
python3 tests/gen_allops_8bit.py tests/progs
python3 tests/gen_rules.py tests/progs
for v in v1 v2; do tools/mkomf $v tests/omf/fixture_$v.omf tests/omf/fixture_$v.expected; done
tools/mkomf v2 tests/omf/fixture_b.omf tests/omf/fixture_b.expected 058000

# name | input | extra args
cases() {
cat <<C
emu|tests/progs/emu.bin|--org 2000 --cpu 65816
native|tests/progs/native.bin|--cpu 65816 --org 2000
mixed|tests/progs/mixed.bin|--cpu 65816 --org 8000
bank|tests/progs/bank.bin|--cpu 65816 --org 021000 --state m8x8 --hints tests/src/bank.hints
allops|tests/progs/allops.bin|--cpu 65816 --org 030000 --hints tests/progs/allops.hints
omf_v1|tests/omf/fixture_v1.omf|
omf_v2|tests/omf/fixture_v2.omf|
omf_base|tests/omf/fixture_b.omf|--base 058000
r88|tests/progs/r88.bin|--cpu 65816 --org 2000
disp|tests/progs/disp.bin|--cpu 65816 --org 2000
disp_omf|tests/progs/disp.omf|
disp_omf_notables|tests/progs/disp.omf|--no-tables
allops_6502|tests/progs/allops_6502.bin|--cpu 6502 --org 0200 --hints tests/progs/allops_6502.hints
allops_65c02|tests/progs/allops_65c02.bin|--cpu 65c02 --org 0200 --hints tests/progs/allops_65c02.hints
emu_default|tests/progs/emu.bin|--org 2000
entry_state|tests/progs/disp2.bin|--cpu 65816 --org 2000 --no-org-entry --no-tables --entry 2050:m16x16 --entry 2058:m8x8
t9_overrun|tests/progs/t9_overrun.bin|--cpu 65816 --state m8x8 --org 2000
t9_overlap_hints|tests/progs/t9_overrun.bin|--cpu 65816 --state m8x8 --org 2000 --no-tables --hints tests/src/t9_overlap.hints
t6_cop|tests/progs/t6_cop.bin|--cpu 65816 --state m8x8 --org 2000
t5_6502push|tests/progs/t5_6502push.bin|--cpu 6502 --org 2000
gsos_inline|tests/progs/gsos_inline.bin|--cpu 65816 --org 2000 --platform gsos --hints tests/src/gsos_inline.hints
prodos8_mli|tests/progs/prodos8_mli.bin|--cpu 6502 --org 2000 --platform prodos8
gsos_omf|tests/progs/gsos.omf|
mvn_omf|tests/progs/mvn.omf|
mvn_reloc|tests/progs/mvn_reloc.omf|
dataseg_omf|tests/progs/dataseg.omf|
dataseg_all|tests/progs/dataseg.omf|--seg-entries
jt_omf|tests/progs/jt.omf|
rts_word|tests/progs/rts_word.bin|--cpu 6502 --org 2000
rts_tail|tests/progs/rts_tail.bin|--cpu 6502 --org 2000
brk1|tests/progs/brk1.bin|--cpu 6502 --org 2000
extstr|tests/progs/extstr.bin|--cpu 6502 --org 2000
held_jsl|tests/progs/held_jsl.omf|
held_data|tests/progs/held_data.omf|
len0|tests/progs/len0.bin|--cpu 6502 --org 2000
g1_sec|tests/progs/g1_sec.bin|--cpu 6502 --org 2000
g1_unk|tests/progs/g1_unk.bin|--cpu 6502 --org 2000
g1_hi1|tests/progs/g1_hi1.bin|--cpu 6502 --org 2000
g1_hisec|tests/progs/g1_hisec.bin|--cpu 6502 --org 2000
g1_bcs|tests/progs/g1_bcs.bin|--cpu 6502 --org 2000
g1_cmp|tests/progs/g1_cmp.bin|--cpu 6502 --org 2000
g1_ft2|tests/progs/g1_ft2.bin|--cpu 6502 --org 2000
g1_merge|tests/progs/g1_merge.bin|--cpu 6502 --org 2000
g1_merge_beq|tests/progs/g1_merge_beq.bin|--cpu 6502 --org 2000
g1_join2|tests/progs/g1_join2.bin|--cpu 6502 --org 2000
g1_bcs_ft|tests/progs/g1_bcs_ft.bin|--cpu 6502 --org 2000
g1_clc|tests/progs/g1_clc.bin|--cpu 6502 --org 2000
g1_wclc|tests/progs/g1_wclc.bin|--cpu 6502 --org 2000
g1_sec_ind|tests/progs/g1_sec_ind.bin|--cpu 6502 --org 2000
g1_sec_adc_ind|tests/progs/g1_sec_adc_ind.bin|--cpu 6502 --org 2000
g1_sec_br|tests/progs/g1_sec_br.bin|--cpu 6502 --org 2000
extjmp|tests/progs/extjmp.bin|--cpu 6502 --org 2000
extstr2|tests/progs/extstr2.bin|--cpu 6502 --org 2000
a1_inline_code|tests/progs/a1_inline_code.bin|--cpu 6502 --org 2000
a2_mismatch|tests/progs/a2_mismatch.bin|--cpu 6502 --org 2000 --entry 2009 --entry 2012 --entry 201B
a4_textbranch|tests/progs/a4_textbranch.bin|--cpu 6502 --org 2000 --entry 200D --entry 2016
b2_mismatch|tests/progs/b2_mismatch.bin|--cpu 6502 --org 2000 --entry 2009 --entry 2012
b4_textbranch|tests/progs/b4_textbranch.bin|--cpu 6502 --org 2000
lenpref|tests/progs/lenpref.bin|--cpu 6502 --org 2000
lenhint|tests/progs/lenhint.bin|--cpu 6502 --org 2000 --hints tests/progs/lenhint.hints
r2_len1|tests/progs/r2_len1.bin|--cpu 6502 --org 2000
r8_brk|tests/progs/r8_brk.bin|--cpu 65c02 --org 2000
rts_word_hint|tests/progs/rts_word.bin|--cpu 6502 --org 2000 --no-tables --hints tests/progs/rts_word.hints
rts_split|tests/progs/rts_split.bin|--cpu 65c02 --org 2000
rts_split_hint|tests/progs/rts_split.bin|--cpu 65c02 --org 2000 --no-tables --hints tests/progs/rts_split.hints
rts_tay|tests/progs/rts_tay.bin|--cpu 6502 --org 2000
rtl_long|tests/progs/rtl_long.bin|--cpu 65816 --state m8x8 --org 2000
rtl_phk|tests/progs/rtl_phk.bin|--cpu 65816 --state m8x8 --org 2000
rts_16|tests/progs/rts_16.bin|--cpu 65816 --state m16x8 --org 2000
rules_var|tests/progs/rules_var.bin|--cpu 6502 --org 2000
g2_iny|tests/progs/g2_iny.bin|--cpu 6502 --org 2000
g2_y1|tests/progs/g2_y1.bin|--cpu 6502 --org 2000
g3_bmi|tests/progs/g3_bmi.bin|--cpu 6502 --org 2000
g3_bpl|tests/progs/g3_bpl.bin|--cpu 6502 --org 2000
g2_jmpind|tests/progs/g2_jmpind.bin|--cpu 6502 --org 2000
g2_incptr|tests/progs/g2_incptr.bin|--cpu 6502 --org 2000
g2_page|tests/progs/g2_page.bin|--cpu 6502 --org 2000
g2n_ambig|tests/progs/g2n_ambig.bin|--cpu 6502 --org 2000
g2n_join|tests/progs/g2n_join.bin|--cpu 6502 --org 2000
g2n_adj|tests/progs/g2n_adj.bin|--cpu 6502 --org 2000
g2n_ind|tests/progs/g2n_ind.bin|--cpu 6502 --org 2000
g2n_off|tests/progs/g2n_off.bin|--cpu 6502 --org 2000
g2a_c17|tests/progs/g2a_c17.bin|--cpu 6502 --org 2000
g2a_c18|tests/progs/g2a_c18.bin|--cpu 6502 --org 2000
g2a_c20|tests/progs/g2a_c20.bin|--cpu 6502 --org 2000
g2a_c22|tests/progs/g2a_c22.bin|--cpu 6502 --org 2000
g2a_c28|tests/progs/g2a_c28.bin|--cpu 6502 --org 2000
g2a_c39|tests/progs/g2a_c39.bin|--cpu 6502 --org 2000
g2a_c40|tests/progs/g2a_c40.bin|--cpu 6502 --org 2000
g2a_c41|tests/progs/g2a_c41.bin|--cpu 6502 --org 2000
g2a_c42|tests/progs/g2a_c42.bin|--cpu 6502 --org 2000
g2a_c43|tests/progs/g2a_c43.bin|--cpu 6502 --org 2000
g2a_absx|tests/progs/g2a_absx.bin|--cpu 6502 --org 2000
g2s_ok|tests/progs/g2s_ok.bin|--cpu 6502 --org 2000
g2s_helper|tests/progs/g2s_helper.bin|--cpu 6502 --org 2000
g2s_ptr|tests/progs/g2s_ptr.bin|--cpu 6502 --org 2000
g2s_opc|tests/progs/g2s_opc.bin|--cpu 6502 --org 2000
g2s_range|tests/progs/g2s_range.bin|--cpu 6502 --org 2000
g2s_rngu|tests/progs/g2s_rngu.bin|--cpu 6502 --org 2000
g2s_816e|tests/progs/g2s_816e.bin|--cpu 65816 --org 2000
g2t_pp|tests/progs/g2t_pp.bin|--org 2000
g2t_p1|tests/progs/g2t_p1.bin|--org 2000
g2t_push|tests/progs/g2t_push.bin|--org 2000
g2t_disp|tests/progs/g2t_disp.bin|--org 2000
g2t_bal|tests/progs/g2t_bal.bin|--org 2000
g2t_swap|tests/progs/g2t_swap.bin|--org 2000
g2t_same|tests/progs/g2t_same.bin|--org 2000
g2t_xblk|tests/progs/g2t_xblk.bin|--org 2000
g2t_scr|tests/progs/g2t_scr.bin|--org 2000
g2t_s1hi|tests/progs/g2t_s1hi.bin|--org 2000
g2t_skok|tests/progs/g2t_skok.bin|--org 2000
g2t_skhit|tests/progs/g2t_skhit.bin|--org 2000
g2t_dpok|tests/progs/g2t_dpok.bin|--cpu 65816 --org 2000
g2t_dphit|tests/progs/g2t_dphit.bin|--cpu 65816 --org 2000
g2t_dpunk|tests/progs/g2t_dpunk.bin|--cpu 65816 --org 2000
g2w_long0|tests/progs/g2w_long0.bin|--cpu 65816 --org 2000
g2w_elong|tests/progs/g2w_elong.bin|--cpu 65816 --org 2000
g2w_elongff|tests/progs/g2w_elongff.bin|--cpu 65816 --org 2000
g2w_m16|tests/progs/g2w_m16.bin|--cpu 65816 --org 2000
g2w_k16|tests/progs/g2w_k16.bin|--cpu 65816 --org 2000
g2w_gs0ffe|tests/progs/g2w_gs0ffe.bin|--cpu 65816 --org 2000 --platform gsos
g2w_gs0120|tests/progs/g2w_gs0120.bin|--cpu 65816 --org 2000 --platform gsos
g2w_gsemu|tests/progs/g2w_gsemu.bin|--cpu 65816 --org 2000 --platform gsos
g2w_gsdp|tests/progs/g2w_gsdp.bin|--cpu 65816 --org 2000 --platform gsos
g2w_gscsw|tests/progs/g2w_gscsw.bin|--cpu 65816 --org 2000 --platform gsos
g2w_plb1|tests/progs/g2w_plb1.bin|--cpu 65816 --org 2000
g2w_plb0|tests/progs/g2w_plb0.bin|--cpu 65816 --org 2000
g2w_dbuf|tests/progs/g2w_dbuf.bin|--cpu 6502 --org 2000
g2w_d20|tests/progs/g2w_d20.bin|--cpu 65816 --org 2000
g2w_dpnat|tests/progs/g2w_dpnat.bin|--cpu 65816 --org 2000
g2w_srok|tests/progs/g2w_srok.bin|--cpu 65816 --org 2000
g2w_srhit|tests/progs/g2w_srhit.bin|--cpu 65816 --org 2000
g2w_sry|tests/progs/g2w_sry.bin|--cpu 65816 --org 2000
g2w_mvnok|tests/progs/g2w_mvnok.bin|--cpu 65816 --org 2000
g2w_mvnhit|tests/progs/g2w_mvnhit.bin|--cpu 65816 --org 2000
g2w_mvphit|tests/progs/g2w_mvphit.bin|--cpu 65816 --org 2000
g2w_mvnunk|tests/progs/g2w_mvnunk.bin|--cpu 65816 --org 2000
g2w_mvnwrap|tests/progs/g2w_mvnwrap.bin|--cpu 65816 --org 2000
g2w_mvndbr|tests/progs/g2w_mvndbr.bin|--cpu 65816 --org 2000
g2w_tsbhit|tests/progs/g2w_tsbhit.bin|--cpu 65c02 --org 2000
g2w_trbok|tests/progs/g2w_trbok.bin|--cpu 65c02 --org 2000
g2w_rmwhit|tests/progs/g2w_rmwhit.bin|--cpu 6502 --org 2000
g2w_rmwok|tests/progs/g2w_rmwok.bin|--cpu 6502 --org 2000
g2w_inchit|tests/progs/g2w_inchit.bin|--cpu 6502 --org 2000
g2w_stzhit|tests/progs/g2w_stzhit.bin|--cpu 65c02 --org 2000
g2w_stzok|tests/progs/g2w_stzok.bin|--cpu 65c02 --org 2000
g2w_stz16|tests/progs/g2w_stz16.bin|--cpu 65816 --org 2000
g2w_pea|tests/progs/g2w_pea.bin|--cpu 65816 --org 2000
g2w_peabal|tests/progs/g2w_peabal.bin|--cpu 65816 --org 2000
g2w_pei|tests/progs/g2w_pei.bin|--cpu 65816 --org 2000
g2w_per|tests/progs/g2w_per.bin|--cpu 65816 --org 2000
g2w_dpwrap|tests/progs/g2w_dpwrap.bin|--cpu 65816 --org 2000
g2w_dpnowrap|tests/progs/g2w_dpnowrap.bin|--cpu 65816 --org 2000
g2w_absxpg|tests/progs/g2w_absxpg.bin|--cpu 6502 --org 2000
g2w_absxpgh|tests/progs/g2w_absxpgh.bin|--cpu 6502 --org 2000
g2w_absxwrap|tests/progs/g2w_absxwrap.bin|--cpu 6502 --org 2000
g2w_absxbank|tests/progs/g2w_absxbank.bin|--cpu 65816 --org 2000
g2w_indybank|tests/progs/g2w_indybank.bin|--cpu 65816 --org 2000
g2w_ptrwrap|tests/progs/g2w_ptrwrap.bin|--cpu 6502 --org 2000
g2w_long16|tests/progs/g2w_long16.bin|--cpu 65816 --org 2000
g2w_srwrap|tests/progs/g2w_srwrap.bin|--cpu 65816 --org 2000
g2w_srwok|tests/progs/g2w_srwok.bin|--cpu 65816 --org 2000
g2t_tsx|tests/progs/g2t_tsx.bin|--org 2000
g2t_rti|tests/progs/g2t_rti.bin|--org 2000
g2t_plp|tests/progs/g2t_plp.bin|--cpu 65816 --org 2000
g2s_816|tests/progs/g2s_816.bin|--cpu 65816 --org 2000
g2s_nocout|tests/progs/g2s_nocout.bin|--cpu 6502 --org 2000
g2c_p01|tests/progs/g2c_p01.bin|--cpu 6502 --org 2000
g2c_p02|tests/progs/g2c_p02.bin|--cpu 6502 --org 2000
g2c_p03|tests/progs/g2c_p03.bin|--cpu 6502 --org 2000
g2c_p04|tests/progs/g2c_p04.bin|--cpu 6502 --org 2000
g2c_p05|tests/progs/g2c_p05.bin|--cpu 6502 --org 2000
g2c_p06|tests/progs/g2c_p06.bin|--cpu 6502 --org 2000
g2c_p07|tests/progs/g2c_p07.bin|--cpu 6502 --org 2000
g2c_p07b|tests/progs/g2c_p07b.bin|--cpu 6502 --org 2000
g2c_p08|tests/progs/g2c_p08.bin|--cpu 6502 --org 2000
g2c_p09|tests/progs/g2c_p09.bin|--cpu 6502 --org 2000
g2c_p10|tests/progs/g2c_p10.bin|--cpu 6502 --org 2000
g2c_p11|tests/progs/g2c_p11.bin|--cpu 6502 --org 2000
g2c_p12|tests/progs/g2c_p12.bin|--cpu 6502 --org 2000
g2c_p13|tests/progs/g2c_p13.bin|--cpu 6502 --org 2000
g2c_r01|tests/progs/g2c_r01.bin|--cpu 6502 --org 2000
g2c_r02|tests/progs/g2c_r02.bin|--cpu 6502 --org 2000
g2c_r03|tests/progs/g2c_r03.bin|--cpu 6502 --org 2000
g2c_r04|tests/progs/g2c_r04.bin|--cpu 6502 --org 2000
g2c_r05|tests/progs/g2c_r05.bin|--cpu 6502 --org 2000
g2c_r06|tests/progs/g2c_r06.bin|--cpu 6502 --org 2000
g2c_v01|tests/progs/g2c_v01.bin|--cpu 6502 --org 2000
g2c_s01|tests/progs/g2c_s01.bin|--cpu 65816 --org 2000
g2c_s02|tests/progs/g2c_s02.bin|--cpu 65816 --org 2000
g2c_s03|tests/progs/g2c_s03.bin|--cpu 65816 --org 2000
g2c_s04|tests/progs/g2c_s04.bin|--cpu 65816 --org 2000
g2c_s05|tests/progs/g2c_s05.bin|--cpu 65816 --org 2000
g2c_s06|tests/progs/g2c_s06.bin|--cpu 65816 --org 2000
g2c_s07|tests/progs/g2c_s07.bin|--cpu 65816 --org 2000
g2a_cld|tests/progs/g2a_cld.bin|--cpu 6502 --org 2000
g2a_plp|tests/progs/g2a_plp.bin|--cpu 6502 --org 2000
g2b_n01|tests/progs/g2b_n01.bin|--cpu 6502 --org 2000
g2b_n02|tests/progs/g2b_n02.bin|--cpu 6502 --org 2000
g2b_n03|tests/progs/g2b_n03.bin|--cpu 6502 --org 2000
g2b_n04|tests/progs/g2b_n04.bin|--cpu 6502 --org 2000
g2b_n05|tests/progs/g2b_n05.bin|--cpu 6502 --org 2000
g2b_n06|tests/progs/g2b_n06.bin|--cpu 6502 --org 2000
g2b_n07|tests/progs/g2b_n07.bin|--cpu 65c02 --org 2000
g2b_n08|tests/progs/g2b_n08.bin|--cpu 6502 --org 2000
g2b_n09|tests/progs/g2b_n09.bin|--cpu 6502 --org 2000
g2b_n10|tests/progs/g2b_n10.bin|--cpu 6502 --org 2000
g2b_n11|tests/progs/g2b_n11.bin|--cpu 6502 --org 2000
g2b_n12|tests/progs/g2b_n12.bin|--cpu 6502 --org 2000
g2b_n13|tests/progs/g2b_n13.bin|--cpu 65816 --org 2000
g2b_n14|tests/progs/g2b_n14.bin|--cpu 65816 --org 2000
g2b_n15|tests/progs/g2b_n15.bin|--cpu 65816 --org 2000
g2b_n16|tests/progs/g2b_n16.bin|--cpu 6502 --org 2000
g2b_n17|tests/progs/g2b_n17.bin|--cpu 6502 --org 2000
g2b_n18|tests/progs/g2b_n18.bin|--cpu 6502 --org 2000
g2b_n19|tests/progs/g2b_n19.bin|--cpu 6502 --org 2000
g2b_n20|tests/progs/g2b_n20.bin|--cpu 6502 --org 2000
g2b_n21|tests/progs/g2b_n21.bin|--cpu 6502 --org 2000
g2b_n22|tests/progs/g2b_n22.bin|--cpu 6502 --org 2000
g2b_n23|tests/progs/g2b_n23.bin|--cpu 6502 --org 2000
g2b_n24|tests/progs/g2b_n24.bin|--cpu 6502 --org 2000
g2b_n25|tests/progs/g2b_n25.bin|--cpu 6502 --org 2000
g2b_n26|tests/progs/g2b_n26.bin|--cpu 6502 --org 2000
g2b_n27|tests/progs/g2b_n27.bin|--cpu 6502 --org 2000
g2r_reloc|tests/progs/g2r_reloc.bin|--cpu 6502 --org 1000 --platform prodos8
g2r_reloc2000|tests/progs/g2r_reloc.bin|--cpu 6502 --org 2000 --platform prodos8
ba_secbcs|tests/progs/ba_secbcs.bin|--cpu 6502 --org 2000
ba_clcbcc|tests/progs/ba_clcbcc.bin|--cpu 6502 --org 2000
ba_lda1bne|tests/progs/ba_lda1bne.bin|--cpu 6502 --org 2000
ba_lda0beq|tests/progs/ba_lda0beq.bin|--cpu 65c02 --org 2000
ba_clcbcs|tests/progs/ba_clcbcs.bin|--cpu 6502 --org 2000
ba_join|tests/progs/ba_join.bin|--cpu 6502 --org 2000
ba_settgt|tests/progs/ba_settgt.bin|--cpu 6502 --org 2000
ba_rep816|tests/progs/ba_rep816.bin|--cpu 65816 --org 2000
ba_f12|tests/progs/ba_f12.bin|--cpu 6502 --org 2000
ba_f16|tests/progs/ba_f16.bin|--cpu 6502 --org 2000
ba_f17|tests/progs/ba_f17.bin|--cpu 6502 --org 2000
ba_s04|tests/progs/ba_s04.bin|--cpu 6502 --org 2000
ba_s04b|tests/progs/ba_s04b.bin|--cpu 6502 --org 2000
w01|tests/progs/w01.bin|--cpu 65816 --org 2000
w02|tests/progs/w02.bin|--cpu 65816 --org 2000
w03|tests/progs/w03.bin|--cpu 65816 --org 2000
w04|tests/progs/w04.bin|--cpu 65816 --org 2000
w05|tests/progs/w05.bin|--cpu 65816 --org 2000
u01|tests/progs/u01.bin|--cpu 6502 --org 2000
u02|tests/progs/u02.bin|--cpu 65816 --org 2000
r01|tests/progs/r01.bin|--cpu 65816 --org 2000
r02|tests/progs/r02.bin|--cpu 65816 --org 2000
r03|tests/progs/r03.bin|--cpu 6502 --org 2000
r04|tests/progs/r04.bin|--cpu 6502 --org 2000
r05|tests/progs/r05.bin|--cpu 65816 --org 2000
r06|tests/progs/r06.bin|--cpu 65816 --org 2000
r07|tests/progs/r07.bin|--cpu 65816 --org 2000
rmw_once|tests/progs/rmw_once.bin|--cpu 6502 --org 2000
rmw_loop|tests/progs/rmw_loop.bin|--cpu 6502 --org 2000
rmw_twocall|tests/progs/rmw_twocall.bin|--cpu 6502 --org 2000
rmw_jtab|tests/progs/rmw_jtab.bin|--cpu 65c02 --org 2000
dom_callee|tests/progs/dom_callee.bin|--cpu 65c02 --org 2000
dom_fall|tests/progs/dom_fall.bin|--cpu 65c02 --org 2000
noret_ff59|tests/progs/noret_ff59.bin|--cpu 65c02 --platform prodos8 --org 2000
noret_ff65|tests/progs/noret_ff65.bin|--cpu 65c02 --platform prodos8 --org 2000
noret_ff69|tests/progs/noret_ff69.bin|--cpu 65c02 --platform prodos8 --org 2000
noret_fa62|tests/progs/noret_fa62.bin|--cpu 65c02 --platform prodos8 --org 2000
noret_e000|tests/progs/noret_e000.bin|--cpu 65c02 --platform prodos8 --org 2000
noret_e003|tests/progs/noret_e003.bin|--cpu 65c02 --platform prodos8 --org 2000
noret_lc|tests/progs/noret_lc.bin|--cpu 65c02 --platform prodos8 --org 2000
noret_lcbit|tests/progs/noret_lcbit.bin|--cpu 6502 --platform prodos8 --org 2000
noret_lcread|tests/progs/noret_lcread.bin|--cpu 6502 --platform prodos8 --org 2000
noret_lcjmp|tests/progs/noret_lcjmp.bin|--cpu 6502 --platform prodos8 --org 2000
noret_lcjmpx|tests/progs/noret_lcjmpx.bin|--cpu 65c02 --platform prodos8 --org 2000
cpuauto_c10_strdata|tests/cpu_auto/c10_strdata.bin|--org 2000
cpuauto_c1_native|tests/cpu_auto/c1_native.bin|--org 2000
cpuauto_c2_plain6502|tests/cpu_auto/c2_plain6502.bin|--org 2000
cpuauto_c3_stray82|tests/cpu_auto/c3_stray82.bin|--org 2000
cpuauto_c4_nop02|tests/cpu_auto/c4_nop02.bin|--org 2000
cpuauto_c5_unknowncarry|tests/cpu_auto/c5_unknowncarry.bin|--org 2000
cpuauto_c6_rockwell|tests/cpu_auto/c6_rockwell.bin|--org 2000
cpuauto_c7_ptrdata|tests/cpu_auto/c7_ptrdata.bin|--org 2000
cpuauto_c8_secxce|tests/cpu_auto/c8_secxce.bin|--org 2000
cpuauto_c9_jsl|tests/cpu_auto/c9_jsl.bin|--org 2000
cpuauto_c11_straypea|tests/cpu_auto/c11_straypea.bin|--org 2000
cpuauto_c12_textrep|tests/cpu_auto/c12_textrep.bin|--org 2000
cpuauto_c13_three|tests/cpu_auto/c13_three.bin|--org 2000
cpuauto_c14_bbsdesync|tests/cpu_auto/c14_bbsdesync.bin|--org 2000
cpuauto_c15_bbrdesync|tests/cpu_auto/c15_bbrdesync.bin|--org 2000
cpuauto_c16_x3desync|tests/cpu_auto/c16_x3desync.bin|--org 2000
cpuauto_c17_midjump|tests/cpu_auto/c17_midjump.bin|--org 2000
cpuauto_c18_datastop|tests/cpu_auto/c18_datastop.bin|--org 2000
cpuauto_c19_textweak|tests/cpu_auto/c19_textweak.bin|--org 2000
cpuauto_c20_nativelong|tests/cpu_auto/c20_nativelong.bin|--org 2000
cpuauto_c21_tablejsl|tests/cpu_auto/c21_tablejsl.bin|--org 2000
cpuauto_c22_dpbefore|tests/cpu_auto/c22_dpbefore.bin|--org 2000
cpuauto_c23_longbefore|tests/cpu_auto/c23_longbefore.bin|--org 2000
cpuauto_c24_longjsl|tests/cpu_auto/c24_longjsl.bin|--org 2000
cpuauto_c25_bbsmulti|tests/cpu_auto/c25_bbsmulti.bin|--org 2000
cpuauto_s01_bbscpx|tests/cpu_auto/s01_bbscpx.bin|--org 2000
cpuauto_s02_bbssbc|tests/cpu_auto/s02_bbssbc.bin|--org 2000
cpuauto_s03_bbsora|tests/cpu_auto/s03_bbsora.bin|--org 2000
cpuauto_s06_bbrwait|tests/cpu_auto/s06_bbrwait.bin|--org 2000
cpuauto_c26_longsta|tests/cpu_auto/c26_longsta.bin|--org 2000
cpuauto_c27_longxjsl|tests/cpu_auto/c27_longxjsl.bin|--org 2000
cpuauto_c28_phkplb|tests/cpu_auto/c28_phkplb.bin|--org 2000
cpuauto_c29_txyrep|tests/cpu_auto/c29_txyrep.bin|--org 2000
cpuauto_c30_endrts|tests/cpu_auto/c30_endrts.bin|--org 2000
cpuauto_c30_endjmp|tests/cpu_auto/c30_endjmp.bin|--org 2000
cpuauto_c30_endbra|tests/cpu_auto/c30_endbra.bin|--org 2000
cpuauto_c30_endrti|tests/cpu_auto/c30_endrti.bin|--org 2000
cpuauto_c30_endjmpi|tests/cpu_auto/c30_endjmpi.bin|--org 2000
cpuauto_n06b_phkplb16|tests/cpu_auto/n06b_phkplb16.bin|--org 2000
cpuauto_n06c_phkplbx16|tests/cpu_auto/n06c_phkplbx16.bin|--org 2000
cpuauto_d01_txy16|tests/cpu_auto/d01_txy16.bin|--org 2000
cpuauto_d02_phbrep16|tests/cpu_auto/d02_phbrep16.bin|--org 2000
cpuauto_x07_emuclcxce|tests/cpu_auto/x07_emuclcxce.bin|--org 2000
cpuauto_x07_emuclcxce_p8|tests/cpu_auto/x07_emuclcxce.bin|--org 2000 --platform prodos8
cpuauto_x08_xce16|tests/cpu_auto/x08_xce16.bin|--org 2000
cpuauto_x09_emuclcxcex|tests/cpu_auto/x09_emuclcxcex.bin|--org 2000
cpuauto_x10_emurep|tests/cpu_auto/x10_emurep.bin|--org 2000
cpuauto_x11_unkxce|tests/cpu_auto/x11_unkxce.bin|--org 2000
cpuauto_x12_emuplp|tests/cpu_auto/x12_emuplp.bin|--org 2000
cpuauto_y06_cmpxce|tests/cpu_auto/y06_cmpxce.bin|--org 2000
cpuauto_c1_override|tests/cpu_auto/c1_native.bin|--cpu 65c02 --org 2000
hint_h05_hint_in_callee|tests/src/hint_h05_hint_in_callee.bin|--cpu 65c02 --org 2000 --hints tests/src/hint_h05_hint_in_callee.hints
hint_h06c_hint_then_jmp|tests/src/hint_h06c_hint_then_jmp.bin|--cpu 65c02 --org 2000 --hints tests/src/hint_h06c_hint_then_jmp.hints
hint_h06d_hint_then_jmp_p8|tests/src/hint_h06d_hint_then_jmp_p8.bin|--cpu 65c02 --platform prodos8 --org 2000 --hints tests/src/hint_h06d_hint_then_jmp_p8.hints
hint_h08_hint_then_branch|tests/src/hint_h08_hint_then_branch.bin|--cpu 65c02 --org 2000 --hints tests/src/hint_h08_hint_then_branch.hints
hint_h06_hint_plus_rom|tests/src/hint_h06_hint_plus_rom.bin|--cpu 65c02 --platform prodos8 --org 2000 --hints tests/src/hint_h06_hint_plus_rom.hints
hint_h04_hint_not_needed|tests/src/hint_h04_hint_not_needed.bin|--cpu 65c02 --org 2000 --hints tests/src/hint_h04_hint_not_needed.hints
hint_h06b_rom_only_guard|tests/src/hint_h06b_rom_only_guard.bin|--cpu 65c02 --platform prodos8 --org 2000 --hints tests/src/hint_h06b_rom_only_guard.hints
hint_h06e_rom_then_jmp|tests/src/hint_h06e_rom_then_jmp.bin|--cpu 65c02 --platform prodos8 --org 2000 --hints tests/src/hint_h06e_rom_then_jmp.hints
noret_sysfail|tests/progs/noret_sysfail.bin|--cpu 65816 --platform gsos --state m8x16 --org 2000
quit_err|tests/progs/quit_err.bin|--cpu 6502 --platform prodos8 --org 2000
t01|tests/progs/t01.bin|--cpu 6502 --org 2000
t02|tests/progs/t02.bin|--cpu 6502 --org 2000
t03|tests/progs/t03.bin|--cpu 6502 --org 2000
b01|tests/progs/b01.bin|--cpu 6502 --org 2000
wrap01|tests/progs/wrap01.bin|--cpu 65816 --org 7F0000 --no-org-entry --entry 7FFFF0
g2r_reloc_again|tests/progs/g2r_reloc_again.bin|--cpu 6502 --org 1000 --platform prodos8
rules_var_off|tests/progs/rules_var.bin|--cpu 6502 --org 2000 --no-auto-inline
rules_varhint|tests/progs/rules_varhint.bin|--cpu 6502 --org 2000 --hints tests/progs/rules_varhint.hints
rules_davexlib|tests/progs/rules_davex.bin|--cpu 6502 --org 9000 --hints-lib davex
rules_twohints|tests/progs/rules_davex.bin|--cpu 6502 --org 9000 --hints tests/progs/rules_varhint.hints --hints tests/progs/rules_noret2.hints
rules_tblload|tests/progs/rules_tblload.bin|--cpu 65c02 --org 2000
rules_split|tests/progs/rules_split.bin|--cpu 65c02 --org 2000
rules_p8quit|tests/progs/rules_p8quit.bin|--cpu 6502 --platform prodos8 --org 2000
rules_gsquit|tests/progs/rules_gsquit.bin|--cpu 65816 --platform gsos --state m8x8 --org 2000
rules_noret|tests/progs/rules_noret.bin|--cpu 6502 --org 2000 --hints tests/progs/rules_noret.hints
rules_imm|tests/progs/rules_imm.bin|--cpu 6502 --org 2000
rules_imm_off|tests/progs/rules_imm.bin|--cpu 6502 --org 2000 --no-imm-pointers
rules_region|tests/progs/rules_region.bin|--cpu 6502 --org 2000 --hints tests/progs/rules_region.hints
jt_all|tests/progs/jt.omf|--seg-entries
jt_trunc|tests/progs/jt_trunc.omf|
rsplit_omf|tests/progs/rsplit.omf|
gsos_omf_none|tests/progs/gsos.omf|--platform none
bitskip|tests/progs/bitskip.bin|--cpu 65816 --state m8x8 --org 2000
brk_ret|tests/progs/brk_ret.bin|--cpu 65816 --state m8x8 --org 2000 --hints tests/src/brk_ret.hints
disp2|tests/progs/disp2.bin|--cpu 65816 --org 2000
disp2_hint|tests/progs/disp2.bin|--cpu 65816 --org 2000 --hints tests/src/disp2.hints
disp_hints|tests/progs/disp.bin|--cpu 65816 --org 2000 --hints tests/src/disp.hints
C
}
rm -f $OUT/coverage.txt
cases | while IFS='|' read name in args; do
    # shellcheck disable=SC2086
    if $DA -q $args -o $OUT/$name.s --verify "$in" && nonempty $OUT/$name.s; then ok "roundtrip $name"; else bad "roundtrip $name"; fi
    # independent rebuild using the emitted cfg
    if ca65 --cpu 65816 -t none -o $OUT/$name.o $OUT/$name.s && ld65 -C $OUT/$name.cfg -o $OUT/$name.bin $OUT/$name.o; then
        $DA -q $args --dump-image $OUT/$name.img -o /dev/null "$in" 2>/dev/null
        if cmp -s $OUT/$name.bin $OUT/$name.img; then ok "rebuild $name"; else bad "rebuild $name"; fi
        case "$in" in *.omf) if cmp -s $OUT/$name.img "${in%.omf}.expected"; then ok "omf-load $name"; else bad "omf-load $name"; fi;; esac
    else bad "rebuild $name"; fi
    # coverage baseline: instruction count and code bytes (table following is future work)
    cov=$($DA $args -o /dev/null "$in" 2>&1 | sed -n 's/.* \([0-9]*\) instructions (\([0-9]*\) bytes code).*/\1 \2/p')
    echo "$name $cov" >> $OUT/coverage.txt
    if [ "${UPDATE_GOLD:-}" = 1 ]; then cp $OUT/$name.s tests/gold/$name.s; fi
    if diff -u tests/gold/$name.s $OUT/$name.s > $OUT/$name.diff; then ok "gold $name"; else bad "gold $name (see $OUT/$name.diff)"; fi
    # the same listing under --strict-smc (stores with unknown targets may modify code)
    # shellcheck disable=SC2086
    if $DA -q $args --strict-smc -o $OUT/strict/$name.s --verify "$in" && nonempty $OUT/strict/$name.s; then ok "strict roundtrip $name"; else bad "strict roundtrip $name"; fi
    if [ "${UPDATE_GOLD:-}" = 1 ]; then cp $OUT/strict/$name.s tests/gold/strict/$name.s; fi
    if diff -u tests/gold/strict/$name.s $OUT/strict/$name.s > $OUT/strict/$name.diff; then ok "strict gold $name"; else bad "strict gold $name (see $OUT/strict/$name.diff)"; fi
done > $OUT/results.txt
cat $OUT/results.txt
pass=$(grep -c '^PASS' $OUT/results.txt); fail=$(grep -c '^FAIL' $OUT/results.txt)

if [ "${UPDATE_GOLD:-}" = 1 ]; then cp $OUT/coverage.txt tests/baseline/coverage.txt; fi
if diff -u tests/baseline/coverage.txt $OUT/coverage.txt; then pass=$((pass+1)); echo "PASS coverage baseline"; else fail=$((fail+1)); echo "FAIL coverage baseline changed (update tests/baseline/coverage.txt if intended)"; fi
# the self-modifying-code fixpoint must settle on every gold image (both modes) without the pass cap
rm -f $OUT/passes.txt
cases | while IFS='|' read name in args; do
    for m in "" --strict-smc; do
        # shellcheck disable=SC2086
        DUMPAPPLE_PASSES=1 $DA -q $args $m -o /dev/null "$in" 2>&1 | sed -n "s/^dumpapple: fixpoint \(.*\)/$name$m \1/p" >> $OUT/passes.txt
    done
done
maxp=$(sed -n 's/.* passes \([0-9]*\)$/\1/p' $OUT/passes.txt | sort -n | tail -1)
if ! grep -q 'cap hit' $OUT/passes.txt && [ -n "$maxp" ]; then pass=$((pass+1)); echo "PASS fixpoint settles on every gold (max $maxp passes)"; else fail=$((fail+1)); echo "FAIL fixpoint pass cap: $(grep 'cap hit' $OUT/passes.txt | tr '\n' ';')"; fi

# expected analysis facts
chk() { if nonempty "$OUT/$1.s" && grep -q -- "$2" "$OUT/$1.s"; then pass=$((pass+1)); echo "PASS fact $1: $2"; else fail=$((fail+1)); echo "FAIL fact $1: $2"; fi; }
nchk() { if nonempty "$OUT/$1.s" && ! grep -q -- "$2" "$OUT/$1.s"; then pass=$((pass+1)); echo "PASS nofact $1: $2"; else fail=$((fail+1)); echo "FAIL nofact $1: $2"; fi; }
chk native "decoding stopped: accumulator width unknown"
chk native "lda #\$BEEF"
chk native "mvn #\$01,#\$02"
chk native "per D002051"
chk native "brl L00203F"
chk native "jml L002062"
chk mixed  "ldy #\$ABCD"
chk mixed  "ldx #\$12 "
chk emu    'hi-ascii "HI THERE"'
chk bank   "jmp (\$1036,x)"
chk bank   "handler0:"
chk omf_v2 "jsl sub_030000"
chk r88    "lda #\$12 .*A9 12$"
chk r88    "ldx #\$34 .*A2 34$"
chk disp   "jmp (\$2020,x)"
chk disp2  "pea+rts dispatch -> \$002020"
chk disp2  "phk+pea+rtl dispatch -> \$002028"
chk disp2  "lda#hi/pha/lda#lo/pha+rts dispatch -> \$002031"
chk disp2  ".word .loword(L002058)"
chk disp2  ".faraddr L00205C"
chk disp2_hint "jump table (hint): 1 word entry, used by \$002007"
chk entry_state "lda #\$1111"
chk entry_state "ldx #\$22 "
chk emu_default '.setcpu "65C02"'
chk allops_6502 '.setcpu "6502"'
chk allops_65c02 "bbr0 \$12,"
chk allops_65c02 "smb7 z:\$12"
chk disp_hints "lda #\$1111"
chk disp_omf_notables ".byte \$30,\$00,\$38,\$00       ; 02/0020 \[reloc 2@+0 -> seg 1+\$30\]"
# F10: no data line may start inside a relocated field (shows as a negative reloc offset)
if ngrep -l "\[reloc [0-9]@-" $OUT/*.s; then fail=$((fail+1)); echo "FAIL relocated field split across data lines"; else pass=$((pass+1)); echo "PASS no relocated field split across data lines"; fi
if ngrep -q "FFFFFFFF" $OUT/*.s; then fail=$((fail+1)); echo "FAIL reloc offset +FFFFFFFF in a listing"; else pass=$((pass+1)); echo "PASS no +FFFFFFFF reloc offsets"; fi
rm -f /dev/null.cfg 2>/dev/null
if $DA --org 2000 -o /dev/null tests/progs/emu.bin 2>&1 | grep -q " instructions" && [ ! -e /dev/null.cfg ]; then pass=$((pass+1)); echo "PASS -o /dev/null"; else fail=$((fail+1)); echo "FAIL -o /dev/null"; fi
chk omf_v2 "reloc inter 2@+1 -> seg 3+\$0\] >>16"

# da65 cross-check (da65 2.18 has no 65816 mode: compare the 8-bit emu program as 65C02)
da65 --cpu 65c02 --start-addr 0x2000 tests/progs/emu.bin 2>/dev/null | awk '{m=$1; if (m ~ /:$/) m=$2; if (m ~ /^[a-z][a-z][a-z]$/) print m}' | head -23 > $OUT/da65.mn
awk '/^    [a-z][a-z][a-z]( |$)/{print $1}' $OUT/emu.s | head -23 > $OUT/ours.mn
if cmp -s $OUT/da65.mn $OUT/ours.mn; then pass=$((pass+1)); echo "PASS da65 cross-check (23 instructions)"; else fail=$((fail+1)); echo "FAIL da65 cross-check"; diff $OUT/da65.mn $OUT/ours.mn; fi

# F1: table length (not just byte identity): exactly 2 entries, code at $2009 kept
if [ "$(grep -c '^    \.word .loword' $OUT/t9_overrun.s)" = 2 ]; then pass=$((pass+1)); echo "PASS t9 table has 2 entries"; else fail=$((fail+1)); echo "FAIL t9 table length"; fi
chk t9_overrun "auto table \$002005: 2 entries used by \$002002 (stopped: code reached later at \$002009)"
chk t9_overrun "jsr .loword(sub_002020)     ; 00/2009"
chk t9_overlap_hints "warning: table hint at \$002006 overlaps another table; ignored"
chk t6_cop "lda #\$01 "
chk t6_cop "rts                         ; 00/2004"
chk t5_6502push "NMOS jmp (\$xxFF) page wrap: pointer bytes \$0020FF/\$002000 -> \$00A980"
chk t5_6502push "lda#hi/pha/lda#lo/pha+rts dispatch -> \$002007"
chk gsos_inline "GS/OS call number"
chk gsos_inline "jsl f:\$E10000               ; 00/2013: 22 00 00 E1\$"
chk gsos_inline "inline hint after call to \$002022"
chk gsos_inline "lda #\$0000 "
chk prodos8_mli "MLI command"
chk prodos8_mli "bcs L00200A"
chk gsos_omf "parameter block \[reloc 3@+0"
chk gsos_omf_none "relocation misaligned with operand"
chk mvn_omf "mvn #\$02,#\$02               ; 02/000B: 54 02 02 \[reloc 1@+1 -> seg 1+\$20\] >>16 \[reloc 1@+2 -> seg 1+\$24\] >>16"
chk mvn_omf "mvp #\$02,#\$02 "
chk mvn_omf "rtl                         ; 02/0011"
if ngrep -q "misaligned" $OUT/mvn_omf.s; then fail=$((fail+1)); echo "FAIL mvn reloc flagged misaligned"; else pass=$((pass+1)); echo "PASS mvn relocs accepted"; fi
chk dataseg_omf ".byte \$A9,\$55,\$00,\$60,\$12,\$34 ; 04/0000"
chk dataseg_omf ".byte \$A9,\$02,\$00,\$6B       ; 03/0000"
if ngrep -q "entry_04" $OUT/dataseg_omf.s $OUT/dataseg_all.s; then fail=$((fail+1)); echo "FAIL data segment ENTRY seeded code"; else pass=$((pass+1)); echo "PASS data segment ENTRY not seeded"; fi
chk dataseg_all "entry_030000:"
# RTS/RTL dispatch tables
chk rts_word "jump table (auto): 2 rts (addr-1) entries, used by \$00200D"
chk rts_word ".word .loword(L002019-1)    ; 00/2012 -> \$002019"
chk rts_word "nop                         ; 00/2019: EA"
chk rts_tail "jump table (auto): 2 rts (addr-1) entries, used by \$00200E"
chk brk1 ".byte \$00                   ; 00/2002"
chk brk1 "nop                         ; 00/2003: EA"
chk extstr "suggested hint: inline \$003000 z (3 call sites look like strings)"
nchk extstr "returns past"
chk extstr "jsr \$3000                   ; 00/2010: 20 00 30 ; unknown: possible inline data after jsr \$003000; see suggested hint"
nchk extstr "eor"
chk held_data "relocated pointer at \$020030 -> \$020023 points into held-back bytes"
chk held_data "unknown: possible inline data after jsr \$023000"
nchk held_data "eor z:\$46"
chk held_jsl "eor z:\$46                   ; 02/0023: 45 46"
nchk held_jsl "relocated pointer at"
chk len0 "returns past 2 inline bytes (length-prefixed)"
chk len0 "ora (\$60,x)                 ; 00/200C: 01 60"
chk g1_sec "00/2000: 20 0E 20 ; returns past 5 inline bytes (length-prefixed)"
chk g1_sec "lda #\$01                    ; 00/200B: A9 01"
chk g1_unk "length-prefixed helper \$00200E: carry unknown at the return-address add; inline length not applied"
nchk g1_unk "returns past"
chk g1_hi1 "length-prefixed helper \$00200E: high-byte add adds 1 page(s); inline length not applied"
nchk g1_hi1 "returns past"
chk g1_hisec "length-prefixed helper \$00200E: high-byte add adds 1 page(s); inline length not applied"
nchk g1_hisec "returns past"
nchk len0 "length-prefixed helper"
nchk g1_unk "decoding stopped"
chk g1_unk "00/2000: 20 0E 20 ; unknown: inline length after jsr \$00200E depends on the carry"
chk g1_bcs "00/2000: 20 0E 20 ; returns past 5 inline bytes (length-prefixed)"
chk g1_bcs "lda #\$01                    ; 00/200B: A9 01"
nchk g1_bcs "length-prefixed helper"
chk g1_cmp "length-prefixed helper \$00200E: carry unknown at the return-address add; inline length not applied"
nchk g1_cmp "returns past"
nchk g1_cmp "decoding stopped"
chk g1_hi1 "00/2000: 20 0E 20 ; unknown: inline length after jsr \$00200E depends on the high-byte add"
nchk g1_hisec "decoding stopped"
chk g1_ft2 "length-prefixed helper \$00200E: carry unknown at the return-address add; inline length not applied"
nchk g1_ft2 "returns past"
nchk g1_ft2 "decoding stopped"
chk g1_merge "length-prefixed helper \$00200E: carry unknown at the return-address add; inline length not applied"
nchk g1_merge "returns past"
nchk g1_merge "decoding stopped"
chk g1_merge_beq "length-prefixed helper \$00200E: carry unknown at the return-address add; inline length not applied"
nchk g1_merge_beq "returns past"
nchk g1_merge_beq "decoding stopped"
chk g1_join2 "length-prefixed helper \$002012: carry unknown at the return-address add; inline length not applied"
nchk g1_join2 "returns past"
nchk g1_join2 "decoding stopped"
chk g1_bcs_ft "length-prefixed helper \$00200E: carry unknown at the return-address add; inline length not applied"
nchk g1_bcs_ft "returns past"
nchk g1_bcs_ft "decoding stopped"
chk g1_clc "00/2000: 20 11 20 ; returns past 4 inline bytes (length-prefixed)"
chk g1_clc "00/2007: 20 11 20 ; returns past 4 inline bytes (length-prefixed)"
chk g1_clc "lda #\$01                    ; 00/200E: A9 01"
nchk g1_clc "length-prefixed helper"
chk g1_wclc "length-prefixed helper \$00200D: a call site does not fit the length rule; inline length not applied"
nchk g1_wclc "returns past"
chk g1_sec_ind "length-prefixed helper \$002010: carry unknown at the return-address add; inline length not applied"
nchk g1_sec_ind "returns past"
chk g1_sec_ind "00/2000: 20 10 20 ; unknown: inline length after jsr \$002010 depends on the carry"
chk g1_sec_adc_ind "length-prefixed helper \$002010: carry unknown at the return-address add; inline length not applied"
nchk g1_sec_adc_ind "returns past"
chk g1_sec_adc_ind "00/2000: 20 10 20 ; unknown: inline length after jsr \$002010 depends on the carry"
chk g1_sec_br "length-prefixed helper \$00200D: carry unknown at the return-address add; inline length not applied"
nchk g1_sec_br "returns past"
chk g1_sec_br "00/2000: 20 0D 20 ; unknown: inline length after jsr \$00200D depends on the carry"
chk extjmp "eor z:\$46                   ; 00/2023: 45 46"
chk extjmp "00/2018: 20 00 30 ; unknown: possible inline data"
nchk extstr2 "unknown:"
nchk a2_mismatch "suggested hint"
nchk a2_mismatch "unknown:"
nchk extstr2 "every call to external"
nchk a1_inline_code "returns past"
chk a1_inline_code "lda #\$C1                    ; 00/200A: A9 C1"
nchk a2_mismatch "returns past"
chk a2_mismatch "lda #\$01                    ; 00/201E: A9 01"
chk a4_textbranch "lda #\$C1                    ; 00/2019: A9 C1"
nchk a4_textbranch "returns past"
chk b2_mismatch "lda #\$01                    ; 00/2015: A9 01"
nchk b2_mismatch "returns past"
chk b4_textbranch "lda #\$C1                    ; 00/2010: A9 C1"
chk lenpref "returns past 4 inline bytes (length-prefixed)"
chk lenpref "returns past 2 inline bytes (length-prefixed)"
chk lenhint "returns past 3 inline bytes (length-prefixed)"
chk r2_len1 "1 entry used by \$00200A (stopped: index guard)"
nchk r2_len1 "lda #\$EA"
chk r8_brk "target inside the instruction at \$00200B"
nchk r8_brk "lda #\$FF"
chk rts_word_hint "jump table (hint): 2 rts (addr-1) entries"
chk rts_split ".byte <(L002034-1)          ; 00/2019"
chk rts_split ".byte >(L002034-1)          ; 00/2021"
chk rts_split "2 split rts (addr-1) entries, low bytes; high bytes at \$002020, used by \$00200A"
chk rts_split_hint "jump table (hint): 2 split rts (addr-1) entries, high bytes"
if ngrep -q "jump table" $OUT/rts_tay.s; then fail=$((fail+1)); echo "FAIL rts_tay: index changed between loads but table taken"; else pass=$((pass+1)); echo "PASS rts_tay: index change blocks the pattern"; fi
chk rtl_long ".faraddr L002024-1          ; 00/2013 -> \$002024"
chk rtl_long "2 rtl long (addr-1) entries"
chk rtl_phk ".word .loword(L002020-1)    ; 00/2010 -> \$002020"
chk rts_16 ".word .loword(L002020-1)    ; 00/2010 -> \$002020"
printf 'rtstable split $2018 $2019 2\n' > $OUT/rtsovl.hints
printf 'rtstable split $2018 2\n' > $OUT/rtsbad.hints
if $DA --cpu 65c02 --org 2000 --no-tables --hints $OUT/rtsovl.hints -o $OUT/rtsovl.s tests/progs/rts_split.bin 2>/dev/null && grep -q "table hint at \$002019 overlaps another table; ignored" $OUT/rtsovl.s; then pass=$((pass+1)); echo "PASS overlapping split halves rejected"; else fail=$((fail+1)); echo "FAIL overlapping split halves"; fi
# gold-set rules (synthetic repros)
chk rules_davexlib "jsr .loword(xmess)          ; 00/9000: 20 06 B0 ; returns past 3 inline bytes (zero-terminated)"
chk rules_davexlib "jmp .loword(xerr)"
chk rules_davexlib "^xmess = \$00B006"
chk rules_twohints "returns past 3 inline bytes (zero-terminated)"
chk rules_twohints "does not return (assumed by noreturn hint)"
$DA -q --cpu 6502 --org 9000 -o $OUT/rules_davex_nolib.s tests/progs/rules_davex.bin
if ngrep -q "returns past" $OUT/rules_davex_nolib.s; then fail=$((fail+1)); echo "FAIL hints library applied without --hints-lib"; else pass=$((pass+1)); echo "PASS no hints library unless asked"; fi
chk rules_var "jsr .loword(sub_002010)     ; 00/2000: 20 10 20 ; returns past 3 inline bytes (zero-terminated)"
chk rules_var "returns past 2 inline bytes (bit-7-set-terminated)"
chk rules_var "rts                         ; 00/200E: 60"
if ngrep -q "00/200B: 20 70 20 ; returns" $OUT/rules_var.s; then fail=$((fail+1)); echo "FAIL rules_var: routine without the +1 taken as inline"; else pass=$((pass+1)); echo "PASS rules_var: no +1, no inline"; fi
# G2/G3: inline-string helpers proven per call site by emulation
chk g2_iny "00/2000: 20 40 20 ; returns past 6 inline bytes (zero-terminated)"
chk g2_iny "00/2009: 20 40 20 ; returns past 3 inline bytes (zero-terminated)"
chk g2_y1 "00/2000: 20 40 20 ; returns past 6 inline bytes (zero-terminated)"
chk g2_y1 "00/2009: 20 40 20 ; returns past 1 inline byte (zero-terminated)"
chk g3_bmi "00/2000: 20 40 20 ; returns past 5 inline bytes (bit-7-set-terminated)"
chk g3_bmi "00/2008: 20 40 20 ; returns past 2 inline bytes (bit-7-set-terminated)"
chk g3_bpl "00/2000: 20 40 20 ; returns past 4 inline bytes (bit-7-clear-terminated)"
chk g3_bpl "00/2007: 20 40 20 ; returns past 2 inline bytes (bit-7-clear-terminated)"
chk g2_jmpind "00/2000: 20 40 20 ; returns past 6 inline bytes (zero-terminated)"
chk g2_incptr "00/2000: 20 40 20 ; returns past 4 inline bytes (zero-terminated)"
chk g2_incptr "00/2007: 20 40 20 ; returns past 1 inline byte (zero-terminated)"
chk g2_page "00/20F8: 20 40 20 ; returns past 11 inline bytes (zero-terminated)"
chk g2n_ambig "called at \$002000: paths return to different places"
chk g2n_join "called at \$002000: paths return to different places"
chk g2n_adj "called at \$002000: return to \$200A does not land right after the last byte read (\$2008)"
chk g2n_ind "called at \$002000: unresolved indirect jump; bytes after the call left undecoded"
chk g2n_off "called at \$002040: string runs past the end of the image (read at \$2045)"
for n in g2n_ambig g2n_join g2n_adj g2n_ind g2n_off; do nchk $n "returns past"; done
# review of 008a3ec: shapes found by emulation (c17 c20 c28), D flag (c22, cld, plp), CSW (c39-c43)
chk g2a_c17 "00/2000: 20 40 20 ; returns past 6 inline bytes (zero-terminated)"
chk g2a_c17 "assumes CSW hook preserves X/Y"; chk g2a_c17 "assumes decimal mode clear at entry"
chk g2a_c18 "called at \$002000: return to \$2008 does not land right after the last byte read"
chk g2a_c20 "00/2000: 20 40 20 ; returns past 6 inline bytes (zero-terminated)"
chk g2a_c28 "00/2000: 20 40 20 ; returns past 6 inline bytes (zero-terminated)"
chk g2a_c22 "called at \$002106: adds in decimal mode (sed)"
chk g2a_cld "returns past 6 inline bytes"; nchk g2a_cld "assumes decimal mode clear at entry"; chk g2a_cld "assumes CSW hook preserves X/Y"
chk g2a_plp "called at \$002106: decimal mode not known at an add"
for n in g2a_c39 g2a_c40 g2a_c41 g2a_c43; do chk $n "COUT \$FDED goes through CSW (\$36/\$37), which the image may change"; done
chk g2a_c42 "the helper sets CSW (\$36/\$37) before calling COUT \$FDED"
# round 5: sta $2000,x with an unknown 8-bit X writes an unknown value over the helper and the entry: a stop
chk g2a_absx "opcode may be changed by a store to an unknown value"
for n in g2a_c18 g2a_c22 g2a_plp g2a_c39 g2a_c40 g2a_c41 g2a_c42 g2a_c43 g2a_absx; do nchk $n "returns past"; nchk $n "assumes CSW hook preserves X/Y"; done
# round 9: write classifier golds
nchk g2w_long0 "returns past 6 inline bytes"; chk g2w_long0 "not a caller's frame"
nchk g2w_elong "returns past 6 inline bytes"; chk g2w_elong "not a caller's frame"
nchk g2w_elongff "returns past 6 inline bytes"; chk g2w_elongff "not a caller's frame"
nchk g2w_m16 "returns past 6 inline bytes"; chk g2w_m16 "not a caller's frame"
nchk g2w_k16 "returns past 6 inline bytes"; chk g2w_k16 "not a caller's frame"
nchk g2w_gs0ffe "returns past 6 inline bytes"; chk g2w_gs0ffe "not a caller's frame"
nchk g2w_gs0120 "returns past 6 inline bytes"; chk g2w_gs0120 "not a caller's frame"
chk g2w_gsemu "returns past 6 inline bytes"
nchk g2w_gsdp "returns past 6 inline bytes"; chk g2w_gsdp "helper code at \$2040 may be changed by the store at \$2182"; chk strict/g2w_gsdp "opcode may be changed by a store to an unknown value"
nchk g2w_gscsw "returns past 6 inline bytes"; chk g2w_gscsw "helper code at \$2040 may be changed by the store at \$2182"; chk strict/g2w_gscsw "opcode may be changed by a store to an unknown value"
chk g2w_plb1 "returns past 6 inline bytes"
nchk g2w_plb0 "returns past 6 inline bytes"; chk g2w_plb0 "not a caller's frame"
chk g2w_dbuf "returns past 6 inline bytes"
chk g2w_d20 "returns past 6 inline bytes"
chk g2w_dpnat "returns past 6 inline bytes"
chk g2w_srok "returns past 6 inline bytes"
nchk g2w_srhit "returns past 6 inline bytes"; chk g2w_srhit "not a caller's frame"
nchk g2w_sry "returns past 6 inline bytes"; chk g2w_sry "helper code at \$2040 may be changed by the store at \$2186"
chk g2w_mvnok "returns past 6 inline bytes"
nchk g2w_mvnhit "returns past 6 inline bytes"; chk g2w_mvnhit "not a caller's frame"
nchk g2w_mvphit "returns past 6 inline bytes"; chk g2w_mvphit "not a caller's frame"
nchk g2w_mvnunk "returns past 6 inline bytes"; chk g2w_mvnunk "helper code at \$2040 may be changed by the store at \$218D"
nchk g2w_mvnwrap "returns past 6 inline bytes"; chk g2w_mvnwrap "store that may reach CSW at \$218D"
chk g2w_mvndbr "returns past 6 inline bytes"
nchk g2w_tsbhit "returns past 6 inline bytes"; chk g2w_tsbhit "not a caller's frame"
chk g2w_trbok "returns past 6 inline bytes"
nchk g2w_rmwhit "returns past 6 inline bytes"; chk g2w_rmwhit "not a caller's frame"
chk g2w_rmwok "returns past 6 inline bytes"
nchk g2w_inchit "returns past 6 inline bytes"; chk g2w_inchit "not a caller's frame"
nchk g2w_stzhit "returns past 6 inline bytes"; chk g2w_stzhit "not a caller's frame"
chk g2w_stzok "returns past 6 inline bytes"
nchk g2w_stz16 "returns past 6 inline bytes"; chk g2w_stz16 "not a caller's frame"
nchk g2w_pea "returns past 6 inline bytes"; chk g2w_pea "not a caller's frame"
chk g2w_peabal "returns past 6 inline bytes"
nchk g2w_pei "returns past 6 inline bytes"; chk g2w_pei "not a caller's frame"
nchk g2w_per "returns past 6 inline bytes"; chk g2w_per "not a caller's frame"
nchk g2w_dpwrap "returns past 6 inline bytes"; chk g2w_dpwrap "not a caller's frame"
chk g2w_dpnowrap "returns past 6 inline bytes"
chk g2w_absxpg "returns past 6 inline bytes"
nchk g2w_absxpgh "returns past 6 inline bytes"; chk g2w_absxpgh "not a caller's frame"
nchk g2w_absxwrap "returns past 6 inline bytes"; chk g2w_absxwrap "store that may reach CSW at \$2184"
chk g2w_absxbank "returns past 6 inline bytes"
chk g2w_indybank "returns past 6 inline bytes"
chk g2w_ptrwrap "returns past 6 inline bytes"
chk g2w_long16 "returns past 6 inline bytes"
nchk g2w_srwrap "returns past 6 inline bytes"; chk g2w_srwrap "not a caller's frame"
chk g2w_srwok "returns past 6 inline bytes"
# immediate-operand SMC exception (exact store onto an immediate operand; the operand is unknown)
chk g2s_ok "returns past 6 inline bytes"; chk g2s_ok "assumes CSW hook preserves X/Y"; chk g2s_816e "returns past 6 inline bytes"
chk g2t_pp "returns past 6 inline bytes"; chk g2t_bal "returns past 6 inline bytes"; chk g2t_same "returns past 6 inline bytes"
chk g2t_scr "returns past 6 inline bytes"; chk g2t_skok "returns past 6 inline bytes"; chk g2t_dpok "returns past 6 inline bytes"; for t in s1hi skhit dphit; do nchk g2t_$t "returns past 6 inline bytes"; chk g2t_$t "not a caller's frame"; done; nchk g2t_tsx "returns past 6 inline bytes"; chk g2t_tsx "not a caller's frame"; nchk g2t_rti "returns past 6 inline bytes"; chk g2t_rti "not a caller's frame"; nchk g2t_plp "returns past 6 inline bytes"; chk g2t_plp "not a caller's frame"
nchk g2t_xblk "returns past 6 inline bytes"; chk g2t_xblk "not a caller's frame"; nchk g2t_p1 "returns past 6 inline bytes"; nchk g2t_push "returns past 6 inline bytes"; nchk g2t_disp "returns past 6 inline bytes"; nchk g2t_swap "returns past 6 inline bytes"
chk g2t_disp "not a caller's frame"; chk g2t_swap "not a caller's frame"; chk g2t_p1 "not a caller's frame"
chk g2s_helper "the helper's immediate operand at \$002047 is modified by a store elsewhere"
chk g2s_ptr "may be changed by the store at \$218C"
chk g2s_opc "store that may modify code (self-modifying code) at \$2182"
chk g2s_range "returns past 6 inline bytes"; chk g2s_rngu "decoding stopped at \$218A"; nchk g2s_rngu "returns past"; chk g2t_dpunk "returns past 6 inline bytes"
chk g2s_816 "decoding stopped at \$2188"
chk g2s_nocout "the helper's immediate operand at \$00204D is modified by a store elsewhere"; nchk g2s_nocout "returns past"
for n in g2s_helper g2s_ptr g2s_opc g2s_816; do nchk $n "returns past"; nchk $n "assumes CSW hook preserves X/Y"; done
# review of 8217ea8: adv3 cases (note = not proven, ok = resolved)
nchk g2c_p01 "returns past"; chk g2c_p01 "not proven"
nchk g2c_p02 "returns past"; chk g2c_p02 "not proven"
nchk g2c_p03 "returns past"; chk g2c_p03 "not proven"
nchk g2c_p04 "returns past"; chk g2c_p04 "not proven"
nchk g2c_p05 "returns past"; chk g2c_p05 "not proven"
nchk g2c_p06 "returns past"; chk g2c_p06 "not proven"
nchk g2c_p07 "returns past"; chk g2c_p07 "not proven"
chk g2c_p07b "returns past"; nchk g2c_p07b "not proven"
nchk g2c_p08 "returns past"; chk g2c_p08 "not proven"
nchk g2c_p09 "returns past"; chk g2c_p09 "not proven"
nchk g2c_p10 "returns past"; chk g2c_p10 "not proven"
chk g2c_p11 "returns past"; nchk g2c_p11 "not proven"
chk g2c_p12 "returns past"; nchk g2c_p12 "not proven"
nchk g2c_p13 "returns past"; chk g2c_p13 "not proven"
nchk g2c_r01 "returns past"; chk g2c_r01 "opcode may be changed by a store to an unknown value"
nchk g2c_r02 "returns past"; chk g2c_r02 "opcode may be changed by a store to an unknown value"
nchk g2c_r03 "returns past"; chk g2c_r03 "not proven"
nchk g2c_r04 "returns past"; chk g2c_r04 "opcode may be changed by a store to an unknown value"
nchk g2c_r05 "returns past"; chk g2c_r05 "opcode may be changed by a store to an unknown value"
nchk g2c_r06 "returns past"; chk g2c_r06 "opcode may be changed by a store to an unknown value"
nchk g2c_v01 "returns past"; chk g2c_v01 "not proven"
nchk g2c_s01 "returns past"; chk g2c_s01 "not proven"
nchk g2c_s02 "returns past"; chk g2c_s02 "not proven"
nchk g2c_s03 "returns past"; chk g2c_s03 "not proven"
nchk g2c_s04 "returns past"; chk g2c_s04 "not proven"
chk g2c_s05 "returns past"; nchk g2c_s05 "not proven"
nchk g2c_s06 "returns past"; chk g2c_s06 "not proven"
nchk g2c_s07 "returns past"; chk g2c_s07 "not proven"
chk g2c_p13 "rts dispatch) at \$2128";  chk g2c_s07 "stack pointer set by tcs"
# review of 0267bff: adv2 n-cases (note = not proven, ok = resolved), relocation loop
nchk g2b_n01 "returns past"; chk g2b_n01 "not proven"
nchk g2b_n02 "returns past"; chk g2b_n02 "not proven"
nchk g2b_n03 "returns past"; chk g2b_n03 "not proven"
nchk g2b_n05 "returns past"; chk g2b_n05 "not proven"
nchk g2b_n06 "returns past"; chk g2b_n06 "not proven"
nchk g2b_n07 "returns past"; chk g2b_n07 "not proven"
chk g2b_n08 "returns past"; nchk g2b_n08 "not proven"
chk g2b_n09 "returns past"; nchk g2b_n09 "not proven"
nchk g2b_n10 "returns past"; chk g2b_n10 "not proven"
chk g2b_n12 "returns past"; nchk g2b_n12 "not proven"
nchk g2b_n13 "returns past"; chk g2b_n13 "not proven"
chk g2b_n14 "returns past"; nchk g2b_n14 "not proven"
nchk g2b_n15 "returns past"; chk g2b_n15 "not proven"
nchk g2b_n16 "returns past"; chk g2b_n16 "not proven"
nchk g2b_n17 "returns past"; chk g2b_n17 "not proven"
nchk g2b_n18 "returns past"; chk g2b_n18 "not proven"
nchk g2b_n19 "returns past"; chk g2b_n19 "not proven"
chk g2b_n21 "returns past"; nchk g2b_n21 "not proven"
chk g2b_n22 "returns past"; nchk g2b_n22 "not proven"
chk g2b_n23 "returns past"; nchk g2b_n23 "not proven"
nchk g2b_n24 "returns past"; chk g2b_n24 "opcode may be changed by a store to an unknown value"
chk g2b_n25 "returns past"; nchk g2b_n25 "not proven"
chk g2b_n26 "returns past"; nchk g2b_n26 "not proven"
chk g2b_n27 "returns past"; nchk g2b_n27 "not proven"
chk g2b_n20 "returns past"
chk g2r_reloc "00/1023: 20 80 10 ; returns past 6 inline bytes"; nchk g2r_reloc "not proven"
chk g2r_reloc2000 "relocation loop at \$2012 copies 2 page(s) from \$2000 to \$1000"
for t in ba_secbcs ba_clcbcc ba_lda1bne ba_lda0beq ba_settgt ba_rep816; do chk $t '.byte $48,$49,$00'; nchk $t "decoding stopped"; done
chk ba_clcbcs "nop"
nchk ba_clcbcs "decoding stopped"
nchk ba_clcbcs "L002005"
chk ba_join "bcs L00200B"
chk ba_join "rts                         ; 00/200A"
chk ba_join "rts                         ; 00/200B"
for t in ba_f12 ba_f16 ba_f17; do chk $t 'lda #\$C1'; chk $t 'jsr \$FDED'; done
for t in ba_s04 ba_s04b; do chk $t 'lda #\$01                    ; 00/2003'; done
for t in w02 w04 strict/w02 strict/w04; do chk $t 'lda #\$60                    ; 00/2009'; chk $t 'changed by a store before it runs'; done   # known value, store dominates: the patched form is decoded (sec / rep #0 in emulation)
for t in w01 w02 w03 w04 strict/w01 strict/w02 strict/w03 strict/w04 strict/w05; do case $t in *w02|*w04) ;; *w01|*w05) chk $t 'opcode may be changed by a store to an unknown value';; *) chk $t 'accumulator width unknown';; esac; nchk $t 'lda #\$6060'; nchk $t 'sta \$C000'; done
# w05: sta dp with D unknown is a fully unknown target: assumed (and said so) by default, a stop under --strict-smc
chk w05 '; assumes stores with unknown targets do not modify code'; chk w05 'sta z:\$10                   ; 00/2004: 85 10 ; unknown-target store (assumed not to modify code)'; nchk w05 'decoding stopped'
for t in w01 w02 w03 w04 strict/w05; do nchk $t 'assumes stores with unknown targets'; done
# u01/u02: the assumption covers code and widths only; CSW, return frames and inline helpers stay tainted
for t in u01 u02 strict/u01 strict/u02; do nchk $t 'returns past'; nchk $t 'assumes CSW hook'; case $t in strict/*) chk $t 'opcode may be changed by a store to an unknown value';; *) chk $t 'not proven (helper code at \$2040 may be changed';; esac; done
for t in u01 u02; do chk $t '; assumes stores with unknown targets do not modify code'; chk $t 'COUT \$FDED is not trusted'; chk $t "not a caller's frame (rts dispatch)"; chk $t 'unknown-target store (assumed not to modify code)'; done
chk u02 'store that may reach CSW at \$218E'
for t in strict/u01 strict/u02; do nchk $t 'assumes stores with unknown targets'; nchk $t 'unknown-target store'; done
# round 3: greatest fixpoint, counted loop bounds, operand/branch-offset hits, whole-bank ranges
for t in r01 strict/r01; do nchk $t 'decoding stopped'; chk $t 'lda #\$6060                  ; 00/200D'; nchk $t 'unknown-target'; done   # 8-bit ring buffer: the sep stays trusted
for t in r02 strict/r02; do chk $t 'opcode may be changed by a store to an unknown value'; nchk $t 'unknown-target'; done   # $1F00-$2101 really covers the sep
for t in r03 strict/r03; do chk $t '00/2006: 90 02 ; changed by a store before it runs: runs as bcc (90 05)'; nchk $t 'lda #\$01'; done   # patched offset: new target only
chk r04 'runs as sta (8D 00 C1)'; nchk r04 'unknown-target store'; nchk r04 'store whose address operand may be modified'
nchk strict/r04 'unknown-target store'; nchk strict/r04 'assumes stores with unknown targets'
for t in r05 strict/r05; do nchk $t 'decoding stopped'; chk $t 'lda #\$60                    ; 00/2013'; nchk $t 'store that may modify code'; done   # ldx #254 loop: $1F00-$1FFF
for t in r06 strict/r06; do nchk $t 'width unknown'; chk $t 'lda #\$00                    ; 00/2010'; done   # known-value flag-only patch (advba2 h06)
for t in r07 strict/r07; do chk $t 'clc                         ; 00/200B: 18 ; changed by a store before it runs: runs as sec (38)'; chk $t 'lda #\$00                    ; 00/200F: A9 00$'; nchk $t 'lda #\$0000'; done   # clc->sec before xce: emulation mode, 8-bit (not the flag-only exemption)
chk mvn_omf 'unknown-target store'; chk strict/g2w_mvnunk 'decoding stopped'   # whole-bank range = unknown target
chk g2r_reloc_again "self-modifying code"; nchk g2r_reloc_again "returns past"; chk g2r_reloc_again "COUT \$FDED is not trusted"
if ngrep -q "returns past" $OUT/rules_var_off.s; then fail=$((fail+1)); echo "FAIL --no-auto-inline"; else pass=$((pass+1)); echo "PASS --no-auto-inline"; fi
chk rules_varhint "rts                         ; 00/2006: 60"
chk rules_tblload "jump table (auto): 2 word entries, used by \$002000, heuristic stopped: read by a load at \$00200A"
chk rules_split "2 word entries, used by \$002002, heuristic stopped: another dispatch site's table starts at \$00200C"
chk rules_split "2 word entries, used by \$002014"
chk rules_p8quit "QUIT returns only on error (C=1)"
chk rules_gsquit "QUIT returns only on error (C=1)"
chk rules_gsquit ".dword params_00200C"
chk rules_gsquit "^params_00200C:"
chk rules_noret "does not return (assumed by noreturn hint)"
chk rules_imm "lda #\$01                    ; 00/2018"
chk rules_imm '.byte "HELLO"'
if ngrep -q "00/2018: A9" $OUT/rules_imm_off.s; then fail=$((fail+1)); echo "FAIL --no-imm-pointers"; else pass=$((pass+1)); echo "PASS --no-imm-pointers"; fi
# round 5: the copy loop writes the region from bytes whose values are not tracked: a stop (caution)
chk rules_region "opcode may be changed by a store to an unknown value"
chk rules_region "jmp .loword(L000280)        ; 00/200B"
chk prodos8_mli ".word .loword(params_00200B)"
# J1: a short remainder is a truncated entry, a 4-byte zero tail is the terminator
chk jt_trunc "; OMF jump table truncated entry (6 of 14 bytes)"
chk jt_trunc ".byte \$00,\$00,\$01,\$00,\$04,\$00 ; 04/0024"
chk jt_omf "; OMF jump table end (load-file number 0)"
if ngrep -q "end (load-file number 0)" $OUT/jt_trunc.s; then fail=$((fail+1)); echo "FAIL jt_trunc: truncated entry called terminator"; else pass=$((pass+1)); echo "PASS jt_trunc: not called terminator"; fi
# OMF KIND $02 jump table: entries are data, their targets in the dynamic segment are code
for t in jt_omf jt_all; do
chk $t "jt_040008:"
chk $t ".dword \$00000000            ; 04/000E segment offset -> entry_050000"
chk $t ".dword \$00000006            ; 04/001C segment offset -> entry_050006"
chk $t ".byte \$22,\$00,\$00,\$00       ; 04/0020 JSL to loader (data, unpatched)"
chk $t "lda #\$0001                  ; 05/0000"
chk $t "lda #\$0002                  ; 05/0006"
chk $t ".byte \$A9,\$00,\$00,\$8D,\$00,\$10,\$60,\$00"
if ngrep -qE "^ +(jsl|brk|lda|sta)\b.*; 0[24]/" $OUT/$t.s; then fail=$((fail+1)); echo "FAIL $t: code listed in jump table or ~ExpressLoad"; else pass=$((pass+1)); echo "PASS $t: no code in jump table or ~ExpressLoad"; fi
done
chk rsplit_omf ".byte \$10,\$00,\$02,.* ; 02/000F \[reloc 3@+0"
chk bitskip "overlapping entry point at \$002009 (BIT-skip style"
chk bitskip "sub_002009 = \$002009"
chk brk_ret "lda #\$01 "
chk allops_6502 "rebuild: ca65 --cpu 6502 "
if ngrep -q "dropped overlapping" $OUT/bitskip.s; then fail=$((fail+1)); echo "FAIL bitskip reported as dropped"; else pass=$((pass+1)); echo "PASS bitskip not an error"; fi

# reviewer MVN repro: 6 instructions (b5925fb listed 3)
if $DA tests/progs/mvn_reloc.omf -o /dev/null 2>&1 | grep -q " 6 instructions"; then pass=$((pass+1)); echo "PASS mvn_reloc 6 instructions"; else fail=$((fail+1)); echo "FAIL mvn_reloc instruction count"; fi
# inline N=0 is rejected by the hints parser (the analyzer also ignores it)
printf 'inline $2000 0\n' > $OUT/inl0.hints
# H1: a rejection passes only with a non-zero exit AND the expected error message
rejects() { what=$1; re=$2; shift 2
    if "$@" >$OUT/rej.out 2>$OUT/rej.err; then fail=$((fail+1)); echo "FAIL $what: accepted (exit 0)"
    elif grep -qE -- "$re" $OUT/rej.err; then pass=$((pass+1)); echo "PASS $what rejected: $(head -1 $OUT/rej.err)"
    else fail=$((fail+1)); echo "FAIL $what: wrong/missing error message (want /$re/)"; fi; }
rejects "inline N=0" 'hints:1: usage: inline ADDR N \(1\.\.255\)' $DA -q --cpu 65816 --org 2000 --hints $OUT/inl0.hints tests/progs/r88.bin -o /dev/null
if $DA --cpu 65c02 --platform gsos --org 2000 tests/progs/emu.bin -o /dev/null 2>&1 | grep -q "warning: --platform gsos"; then pass=$((pass+1)); echo "PASS gsos on 8-bit warns"; else fail=$((fail+1)); echo "FAIL gsos on 8-bit warning"; fi

# 6502 must not decode 65C02-only opcodes (inc a = $1A)
printf '\032\140' > $OUT/c02only.bin
if $DA -q --cpu 6502 --org 0200 -o $OUT/c02only.s --verify $OUT/c02only.bin && grep -q "decoding stopped" $OUT/c02only.s; then pass=$((pass+1)); echo "PASS 6502 rejects 65C02 opcode"; else fail=$((fail+1)); echo "FAIL 6502 rejects 65C02 opcode"; fi

printf 'region $0 4 $2002\n' > $OUT/regovl.hints
rejects "overlapping region" 'overlaps \$002002-\$002005 in the load map' $DA --cpu 6502 --org 2000 --hints $OUT/regovl.hints tests/progs/rules_region.bin -o /dev/null
rejects "unknown --hints-lib" 'hints-lib nosuch: no nosuch.hints' $DA --hints-lib nosuch tests/progs/emu.bin
printf 'bogus $2000\n' > $OUT/bad2.hints
rejects "error names the 2nd hints file" 'bad2.hints:1: unknown directive' $DA --hints tests/progs/rules_varhint.hints --hints $OUT/bad2.hints tests/progs/emu.bin
rejects "rtstable split usage" 'usage: rtstable split HI LO N' $DA --cpu 6502 --org 2000 --hints $OUT/rtsbad.hints tests/progs/rts_split.bin

# table narrowing (t01-t03), both-ways patch (b01), bank wrap (wrap01)
for t in t01 strict/t01; do chk $t 'returns past 12 inline bytes'; nchk $t 'not proven'; done
for t in t02 strict/t02 t03 strict/t03; do chk $t 'not proven (COUT .FDED goes through CSW (.36/.37), which the image may change (store that may reach CSW'; done
for t in b01 strict/b01; do chk $t 'clc                         ; 00/200A: 18 ; may also run as sec (38)'; chk $t 'lda #\$01                    ; 00/200D'; chk $t 'lda #\$02                    ; 00/2010'; done
for t in wrap01 strict/wrap01; do chk $t '\.byte \$AD,\$34               ; 7F/FFFE: AD 34 12 lda a:\$1234 (operand wraps to \$7F/0000)'; chk $t 'rts                         ; 7F/0001: 60'; done

# read-modify-write on a code byte: one known result only when it provably runs once
chk rmw_once 'ldx #\$10                    ; 00/2004: A2 10 ; changed by a store before it runs: runs as eor (51 10)'; nchk rmw_once 'decoding stopped'
for t in rmw_loop rmw_twocall rmw_jtab strict/rmw_loop strict/rmw_twocall strict/rmw_jtab; do chk $t 'opcode may be changed by a store to an unknown value'; nchk $t 'runs as eor'; done
nchk a2_mismatch 'runs as'
# a callee's must-store summary proves the order: only the stored form (rts) runs, $200F/$2006 stay data
for t in dom_callee strict/dom_callee; do chk $t 'runs as rts (60)'; nchk $t 'sta a:\$C000'; done
for n in ff59 ff65 ff69 fa62 e000 e003; do for t in noret_$n strict/noret_$n; do chk $t 'does not return (Apple II ROM'; chk $t 'runs as rts (60)'; nchk $t 'sta a:\$C000'; done; done
# a result that rests on a noreturn hint is tagged, however the hinted call reaches the patch point
for t in hint_h05_hint_in_callee strict/hint_h05_hint_in_callee hint_h06c_hint_then_jmp strict/hint_h06c_hint_then_jmp hint_h06d_hint_then_jmp_p8 strict/hint_h06d_hint_then_jmp_p8 hint_h08_hint_then_branch strict/hint_h08_hint_then_branch hint_h06_hint_plus_rom strict/hint_h06_hint_plus_rom; do chk $t 'runs as rts (60) (per noreturn hint)'; done
for t in hint_h04_hint_not_needed strict/hint_h04_hint_not_needed hint_h06b_rom_only_guard strict/hint_h06b_rom_only_guard hint_h06e_rom_then_jmp strict/hint_h06e_rom_then_jmp; do nchk $t 'per noreturn hint'; done
for t in noret_lc strict/noret_lc noret_lcbit strict/noret_lcbit noret_lcread strict/noret_lcread noret_lcjmp strict/noret_lcjmp noret_lcjmpx strict/noret_lcjmpx; do chk $t 'sta a:\$C000'; chk $t 'followed as an ordinary call: decoded code may switch the language card'; nchk $t 'does not return'; done
for t in noret_sysfail strict/noret_sysfail; do chk $t 'does not return (_SysFailMgr)'; nchk $t 'sta a:\$C000'; done
for t in quit_err strict/quit_err; do chk $t 'QUIT returns only on error (C=1)'; chk $t 'lda #\$C1'; nchk $t 'sta a:\$C000'; done
# CPU auto-detect for raw input (built from tests/cpu_auto/*.s; --verify on each)
if DA=$DA sh tests/test_cpu_auto.sh > $OUT/cpu_auto.txt 2>&1; then pass=$((pass+1)); echo "PASS cpu_auto ($(tail -1 $OUT/cpu_auto.txt))"; else fail=$((fail+1)); echo "FAIL cpu_auto: $(grep FAIL $OUT/cpu_auto.txt | tr "\n" ";")"; fi
for t in dom_fall strict/dom_fall; do chk $t 'runs as rts (60)'; nchk $t 'sta a:\$C000'; done

# review probe sets (tests/adv, ca65/ld65): advws3 must be clean except the four by-design default-mode
# cases that the listing header covers ("assumes stores with unknown targets"); adv9 has two LOW over-notes
if command -v ca65 >/dev/null; then
  for m in "" --strict-smc; do
    python3 tests/adv/advws3.py $DA $OUT/advws3$m $m > $OUT/advws3$m.txt 2>&1
    n=$(grep -c ' | ' $OUT/advws3$m.txt); badl=$(grep ' | ' $OUT/advws3$m.txt | grep -v ' | OK | \| | CTL:OK | ' | grep -v '^f08_full_bank_16 .*HDR\|^f08b_16_base0100 .*HDR\|^f10d_dp_lda_tcd_patched .*HDR\|^f11b_ptr_operand_patched .*HDR')
    if [ "$n" = 50 ] && [ -z "$badl" ] && { [ -z "$m" ] || ! grep ' | ' $OUT/advws3$m.txt | grep -qv ' | OK | \| | CTL:OK | '; }; then pass=$((pass+1)); echo "PASS advws3 $m ($n probes)"; else fail=$((fail+1)); echo "FAIL advws3 $m: $badl"; fi
    python3 tests/adv/advws4.py $DA $OUT/advws4$m $m > $OUT/advws4$m.txt 2>&1
    # by design: m03/d02/d03 unknown-target stores the default header discloses; m07/m08 missed code (caution)
    n=$(grep -c ' | ' $OUT/advws4$m.txt); badl=$(grep ' | ' $OUT/advws4$m.txt | grep -v ' | OK | \| | CTL:' | grep -v '^m07_\|^m08_\|^u04_rts_trick .*MISSED-CODE')
    [ -z "$m" ] && badl=$(echo "$badl" | grep -v '^m03_mvn_unk_len .*HDR\|^d02_D5 .*HDR\|^d03_D_loop .*HDR')
    if [ "$n" = 50 ] && [ -z "$badl" ]; then pass=$((pass+1)); echo "PASS advws4 $m ($n probes)"; else fail=$((fail+1)); echo "FAIL advws4 $m: $(echo "$badl" | tr "\n" ";")"; fi
    python3 tests/adv/advws5.py $DA $OUT/advws5$m $m > $OUT/advws5$m.txt 2>&1
    # by design: e05 (whole-bank 16-bit Y store, header-disclosed in default mode); b07 missed code (carry
    # unknown, caution); b09's DEAD block really runs (control)
    n=$(grep -c ' | ' $OUT/advws5$m.txt); badl=$(grep ' | ' $OUT/advws5$m.txt | grep -v ' | OK | \| | CTL:OK | \|^b09_jsr_and_fall .*CTL:' | grep -v '^b07_rol_clc_one_path .*MISSED-CODE')
    [ -z "$m" ] && badl=$(echo "$badl" | grep -v '^e05_wide_16bit_y .*HDR')
    if [ "$n" = 22 ] && [ -z "$badl" ]; then pass=$((pass+1)); echo "PASS advws5 $m ($n probes)"; else fail=$((fail+1)); echo "FAIL advws5 $m: $(echo "$badl" | tr "\n" ";")"; fi
    python3 tests/adv/advws6.py $DA $OUT/advws6$m $m > $OUT/advws6$m.txt 2>&1
    # conservative stops (live code missed, never false): n03b, n12 (width union), n08 under --strict-smc
    n=$(grep -c ' | ' $OUT/advws6$m.txt); badl=$(grep ' | ' $OUT/advws6$m.txt | grep -v ' | OK | ' | grep -v '^n03b_nested_then_store .*| MISSED-LIVE |\|^n12_rep_sep_width .*| MISSED-CODE@[0-9A-F]* MISSED-CODE@[0-9A-F]* |')
    [ -n "$m" ] && badl=$(echo "$badl" | grep -v '^n08_ptr_some_paths .*| MISSED-LIVE |')
    if [ "$n" = 21 ] && [ -z "$badl" ]; then pass=$((pass+1)); echo "PASS advws6 $m ($n probes)"; else fail=$((fail+1)); echo "FAIL advws6 $m: $(echo "$badl" | tr "\n" ";")"; fi
    python3 tests/adv/advws7.py $DA $OUT/advws7$m $m > $OUT/advws7$m.txt 2>&1
    # cautious (never false code): l09b slot-6 stop, missed live code, h01 tagged as hint-dependent
    n=$(grep -c ' | ' $OUT/advws7$m.txt); badl=$(grep ' | ' $OUT/advws7$m.txt | grep -v ' | OK | \| | MISSED-LIVE | \| | HINT-TAGGED | \|^l09b_slot6 .*| FALSE-CODE@2018,201B |')
    if [ "$n" = 39 ] && [ -z "$badl" ]; then pass=$((pass+1)); echo "PASS advws7 $m ($n probes)"; else fail=$((fail+1)); echo "FAIL advws7 $m: $(echo "$badl" | tr "\n" ";")"; fi
    python3 tests/adv/advws8.py $DA $OUT/advws8$m $m > $OUT/advws8$m.txt 2>&1
    # conservative stops only: i03 (jsr (abs,x) target unknown), i05 (pointer unknown); wrong hints must be tagged
    n=$(grep -c ' | ' $OUT/advws8$m.txt); badl=$(grep ' | ' $OUT/advws8$m.txt | grep -v ' | OK | \| | HINT-TAGGED:[^|]* | \|^i03_jsrx .*| MISSED-LIVE |\|^i05_ptr_unknown .*| MISSED-LIVE |')
    if [ "$n" = 24 ] && [ -z "$badl" ]; then pass=$((pass+1)); echo "PASS advws8 $m ($n probes)"; else fail=$((fail+1)); echo "FAIL advws8 $m: $(echo "$badl" | tr "\n" ";")"; fi
    python3 tests/adv/adv9.py $DA $OUT/adv9$m $m > $OUT/adv9$m.txt 2>&1
    badl=$(grep ' | ' $OUT/adv9$m.txt | grep -v ' | OK | ' | grep -v '^p25_loop_safe .*OVER-NOTE\|^e03_dbr0_absx_cross .*OVER-NOTE')
    if grep -q '^== 45 cases' $OUT/adv9$m.txt && [ -z "$badl" ]; then pass=$((pass+1)); echo "PASS adv9 $m"; else fail=$((fail+1)); echo "FAIL adv9 $m: $(echo "$badl" | tr "\n" ";")"; fi
  done
fi

# CLI conventions
if $DA 2>&1 | grep -qi "usage" && $DA >/dev/null 2>&1; then pass=$((pass+1)); echo "PASS no-args exits 0"; else fail=$((fail+1)); echo "FAIL no-args"; fi
if tools/mkomf >/dev/null 2>&1; then pass=$((pass+1)); echo "PASS mkomf no-args exits 0"; else fail=$((fail+1)); echo "FAIL mkomf no-args"; fi
rejects "bad OMF" '^dumpapple: OMF: unsupported OMF version' $DA --omf tests/progs/emu.bin
rejects "bad --cpu" '^dumpapple: bad --cpu z80' $DA --cpu z80 tests/progs/emu.bin
rejects "missing input" '^dumpapple: cannot read tests/progs/nonexist\.bin' $DA tests/progs/nonexist.bin

echo "== $pass passed, $fail failed"
[ "$fail" -eq 0 ]
