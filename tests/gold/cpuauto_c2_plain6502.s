; dumpapple 0.10.0 listing of tests/cpu_auto/c2_plain6502.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c2_plain6502.o cpuauto_c2_plain6502.s
;          ld65 -C cpuauto_c2_plain6502.cfg -o cpuauto_c2_plain6502.bin cpuauto_c2_plain6502.o

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $21
.segment "SEG1"
.org $002000
entry_002000:
    ldx #$00                    ; 00/2000: A2 00
L002002:
    lda a:$201B,x               ; 00/2002: BD 1B 20
    beq L00200D                 ; 00/2005: F0 06
    jsr $FDED                   ; 00/2007: 20 ED FD
    inx                         ; 00/200A: E8
    bne L002002                 ; 00/200B: D0 F5
L00200D:
    jsr $BF00                   ; 00/200D: 20 00 BF
    adc z:$14                   ; 00/2010: 65 14
    jsr $0460                   ; 00/2012: 20 60 04
    .byte $00,$00               ; 00/2015: 00 00 brk $00
    .byte $00,$00,$00,$00       ; 00/2017
    .byte "HELLO"               ; 00/201B
    .byte $00                   ; 00/2020
