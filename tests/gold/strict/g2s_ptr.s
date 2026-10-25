; dumpapple 0.9.0 listing of tests/progs/g2s_ptr.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2s_ptr.o g2s_ptr.s
;          ld65 -C g2s_ptr.cfg -o g2s_ptr.bin g2s_ptr.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $194
.segment "SEG1"
.org $002000
entry_002000:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $20,$80               ; 00/2000
    .byte "! @ HELLO"           ; 00/2002
    .byte $00,$60               ; 00/200B
    .res 51                     ; 00/200D
    .byte $68,$85,$F0,$68,$85,$F1,$A0,$00 ; 00/2040
    .byte $C8,$B1,$F0,$F0       ; 00/2048 hi-ascii "H1pp"
    .byte $06,$20,$ED,$FD,$4C,$48,$20,$98,$18,$65,$F0,$85,$F0,$A5,$F1,$69 ; 00/204C
    .byte $00,$48,$A5,$F0,$48,$60 ; 00/205C
    .res 286                    ; 00/2062
    .byte $A9,$00,$85,$F8,$A9,$04,$85,$F9,$A0,$00,$A9,$00,$91,$F8,$A9,$00 ; 00/2180
    .byte $8D,$85,$21,$60       ; 00/2190
