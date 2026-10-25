; dumpapple 0.9.0 listing of tests/progs/g2c_p06.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2c_p06.o g2c_p06.s
;          ld65 -C g2c_p06.cfg -o g2c_p06.bin g2c_p06.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $202
.segment "SEG1"
.org $002000
entry_002000:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $4C,$00,$21           ; 00/2000
    .res 61                     ; 00/2003
    .byte $68,$85,$F0,$68,$85,$F1,$A0,$00 ; 00/2040
    .byte $C8,$B1,$F0,$F0       ; 00/2048 hi-ascii "H1pp"
    .byte $06,$20,$ED,$FD,$4C,$48,$20,$98,$18,$65,$F0,$85,$F0,$A5,$F1,$69 ; 00/204C
    .byte $00,$48,$A5,$F0,$48,$60 ; 00/205C
    .res 158                    ; 00/2062
    .byte $A9,$36,$8D,$0B,$21,$A9,$00,$8D,$0F,$21,$A9,$00,$85,$F8,$A9,$04 ; 00/2100
    .byte $85,$F9,$A0,$00,$A9,$00,$91,$F8 ; 00/2110
    .byte " @ HELLO WORLD"      ; 00/2118
    .byte $00,$60               ; 00/2126
    .res 216                    ; 00/2128
    .byte $C8,$60               ; 00/2200
