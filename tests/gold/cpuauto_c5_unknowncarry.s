; dumpapple 0.10.0 listing of tests/cpu_auto/c5_unknowncarry.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c5_unknowncarry.o cpuauto_c5_unknowncarry.s
;          ld65 -C cpuauto_c5_unknowncarry.cfg -o cpuauto_c5_unknowncarry.bin cpuauto_c5_unknowncarry.o

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $5
.segment "SEG1"
.org $002000
entry_002000:
    lda z:$00                   ; 00/2000: A5 00
    ror a                       ; 00/2002: 6A
; code flow reached here but decoding stopped: undefined 65C02 opcode
    .byte $FB,$60               ; 00/2003
