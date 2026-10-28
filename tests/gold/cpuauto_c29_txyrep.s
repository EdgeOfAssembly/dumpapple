; dumpapple 0.10.0 listing of tests/cpu_auto/c29_txyrep.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_c29_txyrep.o cpuauto_c29_txyrep.s
;          ld65 -C cpuauto_c29_txyrep.cfg -o cpuauto_c29_txyrep.bin cpuauto_c29_txyrep.o

; cpu: 65816 (auto: 65816-only rep at $2005 on flow from the entry (3 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $C
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    txy                         ; 00/2000: 9B
    lda #$01                    ; 00/2001: A9 01
    sta z:$10                   ; 00/2003: 85 10
    rep #$20                    ; 00/2005: C2 20
    lda z:$10                   ; 00/2007: A5 10
    sep #$20                    ; 00/2009: E2 20
    rts                         ; 00/200B: 60
