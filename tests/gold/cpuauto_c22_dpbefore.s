; dumpapple 0.10.0 listing of tests/cpu_auto/c22_dpbefore.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_c22_dpbefore.o cpuauto_c22_dpbefore.s
;          ld65 -C cpuauto_c22_dpbefore.cfg -o cpuauto_c22_dpbefore.bin cpuauto_c22_dpbefore.o

; cpu: 65816 (auto: 65816-only rep at $2002 on flow from the entry (2 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $A
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    lda [$10],y                 ; 00/2000: B7 10
    rep #$30                    ; 00/2002: C2 30
    sta a:$1000                 ; 00/2004: 8D 00 10
    sep #$30                    ; 00/2007: E2 30
    rts                         ; 00/2009: 60
