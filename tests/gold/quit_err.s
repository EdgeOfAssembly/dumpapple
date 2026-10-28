; dumpapple 0.10.0 listing of tests/progs/quit_err.bin
; cpu 6502, platform prodos8
; rebuild: ca65 --cpu 6502 -t none -o quit_err.o quit_err.s
;          ld65 -C quit_err.cfg -o quit_err.bin quit_err.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $11
.segment "SEG1"
.org $002000
entry_002000:
    jsr $BF00                   ; 00/2000: 20 00 BF ; returns past 3 inline bytes; QUIT returns only on error (C=1)
; ProDOS 8 MLI command + parameter list pointer after call to $00BF00
    .byte $65                   ; 00/2003 MLI command
    .word $0300                 ; 00/2004 parameter list
    bcs L00200B                 ; 00/2006: B0 03
    .byte $8D,$00,$C0           ; 00/2008
L00200B:
    lda #$C1                    ; 00/200B: A9 C1
    jsr $FDED                   ; 00/200D: 20 ED FD
    rts                         ; 00/2010: 60
