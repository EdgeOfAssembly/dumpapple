; dumpapple 0.10.0 listing of tests/cpu_auto/c8_secxce.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c8_secxce.o cpuauto_c8_secxce.s
;          ld65 -C cpuauto_c8_secxce.cfg -o cpuauto_c8_secxce.bin cpuauto_c8_secxce.o

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $5
.segment "SEG1"
.org $002000
entry_002000:
    sec                         ; 00/2000: 38
; code flow reached here but decoding stopped: undefined 65C02 opcode
    .byte $FB,$64,$00,$60       ; 00/2001
