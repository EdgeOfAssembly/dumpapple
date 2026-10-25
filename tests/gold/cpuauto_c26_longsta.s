; dumpapple 0.9.0 listing of tests/cpu_auto/c26_longsta.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_c26_longsta.o cpuauto_c26_longsta.s
;          ld65 -C cpuauto_c26_longsta.cfg -o cpuauto_c26_longsta.bin cpuauto_c26_longsta.o

; cpu: 65816 (auto: 65816-only rep at $2007 on flow from the entry (2 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $C
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    lda f:$E10000               ; 00/2000: AF 00 00 E1
    sta a:$0300                 ; 00/2004: 8D 00 03
    rep #$30                    ; 00/2007: C2 30
    sep #$30                    ; 00/2009: E2 30
    rts                         ; 00/200B: 60
