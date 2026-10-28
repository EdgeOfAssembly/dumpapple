; dumpapple 0.10.0 listing of tests/progs/a4_textbranch.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o a4_textbranch.o a4_textbranch.s
;          ld65 -C a4_textbranch.cfg -o a4_textbranch.bin a4_textbranch.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $1E
.segment "SEG1"
.org $002000
entry_002000:
    ldx #$00                    ; 00/2000: A2 00
    beq L002019                 ; 00/2002: F0 15
    .byte $20,$00,$FD           ; 00/2004
    .byte "HELLO"               ; 00/2007
    .byte $00                   ; 00/200C
entry_00200D:
    jsr $FD00                   ; 00/200D: 20 00 FD
; code flow reached here but decoding stopped: undefined 6502 opcode or truncated
    .byte "WORLD"               ; 00/2010
    .byte $00                   ; 00/2015
entry_002016:
    jsr $FD00                   ; 00/2016: 20 00 FD
L002019:
    lda #$C1                    ; 00/2019: A9 C1
    bne L00201D                 ; 00/201B: D0 00
L00201D:
    rts                         ; 00/201D: 60
