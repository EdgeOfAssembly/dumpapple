; dumpapple 0.9.0 listing of tests/progs/ba_lda0beq.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o ba_lda0beq.o ba_lda0beq.s
;          ld65 -C ba_lda0beq.cfg -o ba_lda0beq.bin ba_lda0beq.o

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $8
.segment "SEG1"
.org $002000
entry_002000:
    lda #$00                    ; 00/2000: A9 00
    beq L002007                 ; 00/2002: F0 03
    .byte $48,$49,$00           ; 00/2004
L002007:
    rts                         ; 00/2007: 60
