; dumpapple 0.10.0 listing of tests/progs/u01.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o u01.o u01.s
;          ld65 -C u01.cfg -o u01.bin u01.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $187
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002180)     ; 00/2000: 20 80 21 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte " @ HELLO"            ; 00/2003
    .byte $00,$60               ; 00/200B
    .res 51                     ; 00/200D
    .byte $68,$85,$F0,$68,$85,$F1,$A0,$00 ; 00/2040
    .byte $C8,$B1,$F0,$F0       ; 00/2048 hi-ascii "H1pp"
    .byte $06,$20,$ED,$FD,$4C,$48,$20,$98,$18,$65,$F0,$85,$F0,$A5,$F1,$69 ; 00/204C
    .byte $00,$48,$A5,$F0,$48,$60 ; 00/205C
    .res 286                    ; 00/2062
sub_002180:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $A0,$00,$A9,$00,$91,$F8,$60 ; 00/2180
