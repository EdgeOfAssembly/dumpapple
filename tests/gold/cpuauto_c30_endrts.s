; dumpapple 0.10.0 listing of tests/cpu_auto/c30_endrts.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c30_endrts.o cpuauto_c30_endrts.s
;          ld65 -C cpuauto_c30_endrts.cfg -o cpuauto_c30_endrts.bin cpuauto_c30_endrts.o

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $C
.segment "SEG1"
.org $002000
entry_002000:
    bbs7 $10,L002003            ; 00/2000: FF 10 00
L002003:
    lda #$01                    ; 00/2003: A9 01
    rts                         ; 00/2005: 60
    .byte $C2,$30,$00,$00,$00,$00 ; 00/2006
