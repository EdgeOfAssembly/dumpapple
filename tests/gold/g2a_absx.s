; dumpapple 0.9.0 listing of tests/progs/g2a_absx.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2a_absx.o g2a_absx.s
;          ld65 -C g2a_absx.cfg -o g2a_absx.bin g2a_absx.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $6A
.segment "SEG1"
.org $002000
entry_002000:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte " @ HELLO"            ; 00/2000
    .byte $00,$60               ; 00/2008
    .res 54                     ; 00/200A
    .byte $68,$85,$F0,$68,$85,$F1,$AE,$00,$03,$A9,$00,$9D,$00,$20,$A0,$00 ; 00/2040
    .byte $C8,$B1,$F0,$F0       ; 00/2050 hi-ascii "H1pp"
    .byte $06,$20,$ED,$FD,$4C,$50,$20,$98,$18,$65,$F0,$85,$F0,$A5,$F1,$69 ; 00/2054
    .byte $00,$48,$A5,$F0,$48,$60 ; 00/2064
