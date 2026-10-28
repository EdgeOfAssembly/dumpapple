; dumpapple 0.10.0 listing of tests/progs/a1_inline_code.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o a1_inline_code.o a1_inline_code.s
;          ld65 -C a1_inline_code.cfg -o a1_inline_code.bin a1_inline_code.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $18
.segment "SEG1"
.org $002000
entry_002000:
    jsr $FDED                   ; 00/2000: 20 ED FD
    lda #$C1                    ; 00/2003: A9 C1
    bne L002007                 ; 00/2005: D0 00
L002007:
    jsr $FDED                   ; 00/2007: 20 ED FD
L00200A:
    lda #$C1                    ; 00/200A: A9 C1
    bne L00200E                 ; 00/200C: D0 00
L00200E:
    jsr $FDED                   ; 00/200E: 20 ED FD
    lda #$C1                    ; 00/2011: A9 C1
    bne L002015                 ; 00/2013: D0 00
L002015:
    jmp .loword(L00200A)        ; 00/2015: 4C 0A 20
