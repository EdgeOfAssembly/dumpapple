; dumpapple 0.9.0 listing of tests/progs/g2b_n24.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2b_n24.o g2b_n24.s
;          ld65 -C g2b_n24.cfg -o g2b_n24.bin g2b_n24.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $202
.segment "SEG1"
.org $002000
entry_002000:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $4C,$00,$21           ; 00/2000
    .res 61                     ; 00/2003
    .byte $68,$85,$F0,$68,$85,$F1,$AE,$00,$03,$A0,$00 ; 00/2040
    .byte $C8,$B1,$F0,$F0       ; 00/204B hi-ascii "H1pp"
    .byte $09,$9D,$00,$20,$20,$ED,$FD,$4C,$4B,$20,$98,$18,$65,$F0,$85,$F0 ; 00/204F
    .byte $A5,$F1,$69,$00,$48,$A5,$F0,$48,$60 ; 00/205F
    .res 152                    ; 00/2068
    .byte " @ HELLO WORLD"      ; 00/2100
    .byte $00,$60               ; 00/210E
    .res 240                    ; 00/2110
    .byte $C8,$60               ; 00/2200
