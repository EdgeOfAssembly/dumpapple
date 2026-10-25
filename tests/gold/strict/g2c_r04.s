; dumpapple 0.9.0 listing of tests/progs/g2c_r04.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2c_r04.o g2c_r04.s
;          ld65 -C g2c_r04.cfg -o g2c_r04.bin g2c_r04.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $322
.segment "SEG1"
.org $002000
entry_002000:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $A2,$01,$A0,$00,$B9,$00,$21,$99,$00,$20 ; 00/2000
    .byte $C8,$D0,$F7,$EE       ; 00/200A hi-ascii "HPwn"
    .byte $06,$20,$EE,$09,$20,$CA,$F0,$03,$4C,$04,$20,$20,$00 ; 00/200E
    .byte "#HELLO WORLD"        ; 00/201B
    .byte $00,$4C,$04,$20       ; 00/2027
    .res 469                    ; 00/202B
    .byte $C8,$60               ; 00/2200
    .res 254                    ; 00/2202
    .byte $68,$85,$F0,$68,$85,$F1,$A0,$00 ; 00/2300
    .byte $C8,$B1,$F0,$F0       ; 00/2308 hi-ascii "H1pp"
    .byte $06,$20,$ED,$FD,$4C,$08,$23,$98,$18,$65,$F0,$85,$F0,$A5,$F1,$69 ; 00/230C
    .byte $00,$48,$A5,$F0,$48,$60 ; 00/231C
