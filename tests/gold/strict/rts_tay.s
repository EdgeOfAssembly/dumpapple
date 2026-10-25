; dumpapple 0.9.0 listing of tests/progs/rts_tay.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o rts_tay.o rts_tay.s
;          ld65 -C rts_tay.cfg -o rts_tay.bin rts_tay.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $1B
.segment "SEG1"
.org $002000
entry_002000:
    ldy #$02                    ; 00/2000: A0 02
    lda a:$2011,y               ; 00/2002: B9 11 20
    pha                         ; 00/2005: 48
    tay                         ; 00/2006: A8
    lda a:$2010,y               ; 00/2007: B9 10 20
    pha                         ; 00/200A: 48
    rts                         ; 00/200B: 60
    .byte $00,$00,$00,$00,$16,$20,$18,$20,$00,$00,$00,$60,$00,$EA,$60 ; 00/200C
