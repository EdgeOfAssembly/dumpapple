; dumpapple 0.9.0 listing of tests/cpu_auto/c30_endjmpi.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c30_endjmpi.o cpuauto_c30_endjmpi.s
;          ld65 -C cpuauto_c30_endjmpi.cfg -o cpuauto_c30_endjmpi.bin cpuauto_c30_endjmpi.o

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $E
.segment "SEG1"
.org $002000
entry_002000:
    bbs7 $10,L002003            ; 00/2000: FF 10 00
L002003:
    lda #$01                    ; 00/2003: A9 01
    jmp ($03F0)                 ; 00/2005: 6C F0 03
    .byte $C2,$30,$00,$00,$00,$00 ; 00/2008
