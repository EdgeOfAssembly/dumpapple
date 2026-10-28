; dumpapple 0.10.0 listing of tests/progs/b4_textbranch.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o b4_textbranch.o b4_textbranch.s
;          ld65 -C b4_textbranch.cfg -o b4_textbranch.bin b4_textbranch.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $31
.segment "SEG1"
.org $002000
entry_002000:
    ldx #$00                    ; 00/2000: A2 00
    beq L002010                 ; 00/2002: F0 0C
    .byte $20,$15               ; 00/2004
    .byte " HELLO"              ; 00/2006
    .byte $00,$20,$15,$20       ; 00/200C
L002010:
    lda #$C1                    ; 00/2010: A9 C1
    bne L002014                 ; 00/2012: D0 00
L002014:
    rts                         ; 00/2014: 60
    .byte $68,$85,$F0,$68,$85,$F1,$A0,$00,$E6,$F0,$D0,$02 ; 00/2015
    .byte $E6,$F1,$B1,$F0,$F0   ; 00/2021 hi-ascii "fq1pp"
    .byte $03,$4C,$1D,$20,$A5,$F1,$48,$A5,$F0,$48,$60 ; 00/2026
