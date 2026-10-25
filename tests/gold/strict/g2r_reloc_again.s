; dumpapple 0.9.0 listing of tests/progs/g2r_reloc_again.bin
; cpu 6502, platform prodos8
; rebuild: ca65 --cpu 6502 -t none -o g2r_reloc_again.o g2r_reloc_again.s
;          ld65 -C g2r_reloc_again.cfg -o g2r_reloc_again.bin g2r_reloc_again.o

.setcpu "6502"

; ------------------------------------------------------------
; base $001000 length $A2
.segment "SEG1"
.org $001000
entry_001000:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $A9,$00,$85,$00,$85,$02,$A9,$20,$85,$01,$A9,$10,$85,$03,$A2,$02 ; 00/1000
    .byte $A0,$00,$B1,$00,$91,$02 ; 00/1010
    .byte $C8,$D0,$F9,$E6       ; 00/1016 hi-ascii "HPyf"
    .byte $01,$E6,$03,$CA,$D0,$F2,$4C,$23,$10,$20,$80,$10 ; 00/101A
    .byte "HELLO"               ; 00/1026
    .byte $00,$4C,$00,$10       ; 00/102B
    .res 81                     ; 00/102F
    .byte $68,$85,$F0,$68,$85,$F1,$A0,$00 ; 00/1080
    .byte $C8,$B1,$F0,$F0       ; 00/1088 hi-ascii "H1pp"
    .byte $06,$20,$ED,$FD,$4C,$88,$10,$98,$18,$65,$F0,$85,$F0,$A5,$F1,$69 ; 00/108C
    .byte $00,$48,$A5,$F0,$48,$60 ; 00/109C
