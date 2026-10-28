; dumpapple 0.10.0 listing of tests/cpu_auto/c16_x3desync.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c16_x3desync.o cpuauto_c16_x3desync.s
;          ld65 -C cpuauto_c16_x3desync.cfg -o cpuauto_c16_x3desync.bin cpuauto_c16_x3desync.o

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $4
.segment "SEG1"
.org $002000
entry_002000:
; code flow reached here but decoding stopped: undefined 65C02 opcode
    .byte $03,$A2,$C2,$60       ; 00/2000
