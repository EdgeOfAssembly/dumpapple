; dumpapple 0.10.0 listing of tests/cpu_auto/c1_native.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c1_override.o cpuauto_c1_override.s
;          ld65 -C cpuauto_c1_override.cfg -o cpuauto_c1_override.bin cpuauto_c1_override.o

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $14
.segment "SEG1"
.org $002000
entry_002000:
; code flow reached here but decoding stopped: undefined 65C02 opcode
    .byte $82,$07,$00,$71,$77,$04 ; 00/2000
    .byte "main"                ; 00/2006
    .byte $18,$FB,$C2,$30,$A9,$34,$12,$38,$FB,$60 ; 00/200A
