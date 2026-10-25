; dumpapple 0.9.0 listing of tests/cpu_auto/d01_txy16.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_d01_txy16.o cpuauto_d01_txy16.s
;          ld65 -C cpuauto_d01_txy16.cfg -o cpuauto_d01_txy16.bin cpuauto_d01_txy16.o

; cpu: 65816 (auto: 65816-only rep at $2001 on flow from the entry (2 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $B
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    txy                         ; 00/2000: 9B
    rep #$20                    ; 00/2001: C2 20
    lda #$01                    ; 00/2003: A9 01
    .byte $00,$A2               ; 00/2005: 00 A2 brk $A2
    .byte $00,$E2,$20,$60       ; 00/2007
