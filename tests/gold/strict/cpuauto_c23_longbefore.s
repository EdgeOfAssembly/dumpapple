; dumpapple 0.10.0 listing of tests/cpu_auto/c23_longbefore.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_c23_longbefore.o cpuauto_c23_longbefore.s
;          ld65 -C cpuauto_c23_longbefore.cfg -o cpuauto_c23_longbefore.bin cpuauto_c23_longbefore.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

; cpu: 65816 (auto: 65816-only rep at $2004 on flow from the entry; --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $C
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    lda f:$E10000               ; 00/2000: AF 00 00 E1
    rep #$30                    ; 00/2004: C2 30
    sta a:$1000                 ; 00/2006: 8D 00 10
    sep #$30                    ; 00/2009: E2 30
    rts                         ; 00/200B: 60
