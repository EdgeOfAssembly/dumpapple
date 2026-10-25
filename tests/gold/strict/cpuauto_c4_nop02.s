; dumpapple 0.9.0 listing of tests/cpu_auto/c4_nop02.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c4_nop02.o cpuauto_c4_nop02.s
;          ld65 -C cpuauto_c4_nop02.cfg -o cpuauto_c4_nop02.bin cpuauto_c4_nop02.o

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $9
.segment "SEG1"
.org $002000
entry_002000:
    stz z:$00                   ; 00/2000: 64 00
; code flow reached here but decoding stopped: undefined 65C02 opcode
    .byte $02,$EA,$42,$EA,$A9,$01,$60 ; 00/2002
