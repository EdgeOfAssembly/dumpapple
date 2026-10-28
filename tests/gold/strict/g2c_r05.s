; dumpapple 0.10.0 listing of tests/progs/g2c_r05.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2c_r05.o g2c_r05.s
;          ld65 -C g2c_r05.cfg -o g2c_r05.bin g2c_r05.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $322
.segment "SEG1"
.org $002000
entry_002000:
    ldx #$01                    ; 00/2000: A2 01 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
    ldy #$00                    ; 00/2002: A0 00 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $B9,$00,$21,$49,$80,$99,$00,$20 ; 00/2004
    .byte $C8,$D0,$F5,$EE       ; 00/200C hi-ascii "HPun"
    .byte $06,$20,$EE,$0B,$20,$CA,$F0,$03,$4C,$04,$20,$20,$00 ; 00/2010
    .byte "#HELLO WORLD"        ; 00/201D
    .byte $00,$60               ; 00/2029
    .res 469                    ; 00/202B
    .byte $C8,$60               ; 00/2200
    .res 254                    ; 00/2202
    .byte $68,$85,$F0,$68,$85,$F1,$A0,$00 ; 00/2300
    .byte $C8,$B1,$F0,$F0       ; 00/2308 hi-ascii "H1pp"
    .byte $06,$20,$ED,$FD,$4C,$08,$23,$98,$18,$65,$F0,$85,$F0,$A5,$F1,$69 ; 00/230C
    .byte $00,$48,$A5,$F0,$48,$60 ; 00/231C
