; dumpapple 0.10.0 listing of tests/cpu_auto/c3_stray82.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c3_stray82.o cpuauto_c3_stray82.s
;          ld65 -C cpuauto_c3_stray82.cfg -o cpuauto_c3_stray82.bin cpuauto_c3_stray82.o

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $C
.segment "SEG1"
.org $002000
entry_002000:
    stz z:$00                   ; 00/2000: 64 00
    lda #$01                    ; 00/2002: A9 01
    rts                         ; 00/2004: 60
    .byte $82,$07,$00,$18,$FB,$C2,$30 ; 00/2005
