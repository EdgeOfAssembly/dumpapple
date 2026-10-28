; dumpapple 0.10.0 listing of tests/progs/g2c_v01.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2c_v01.o g2c_v01.s
;          ld65 -C g2c_v01.cfg -o g2c_v01.bin g2c_v01.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $202
.segment "SEG1"
.org $002000
entry_002000:
    jmp .loword(L002100)        ; 00/2000: 4C 00 21 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
    .res 61                     ; 00/2003
    .byte $68,$85,$F0,$68,$85,$F1,$A0,$00 ; 00/2040
    .byte $C8,$B1,$F0,$F0       ; 00/2048 hi-ascii "H1pp"
    .byte $06,$20,$ED,$FD,$4C,$48,$20,$98,$18,$65,$F0,$85,$F0,$A5,$F1,$69 ; 00/204C
    .byte $00,$48,$A5,$F0,$48,$60 ; 00/205C
    .res 158                    ; 00/2062
L002100:
    lda #$0F                    ; 00/2100: A9 0F ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
    sta z:$F8                   ; 00/2102: 85 F8 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $A9,$21,$85,$F9,$A0,$00,$A9,$EA,$91,$F8,$A9,$1D,$85,$F8,$A9,$21 ; 00/2104
    .byte $85,$F9,$A0,$00,$A9,$EA,$91,$F8,$A9,$2B,$85,$F8,$A9,$21,$85,$F9 ; 00/2114
    .byte $A0,$00,$A9,$EA,$91,$F8,$A9,$39,$85,$F8,$A9,$21,$85,$F9,$A0,$00 ; 00/2124
    .byte $A9,$EA,$91,$F8,$A9,$47,$85,$F8,$A9,$21,$85,$F9,$A0,$00,$A9,$EA ; 00/2134
    .byte $91,$F8,$A9,$55,$85,$F8,$A9,$21,$85,$F9,$A0,$00,$A9,$EA,$91,$F8 ; 00/2144
    .byte $A9,$63,$85,$F8,$A9,$21,$85,$F9,$A0,$00,$A9,$EA,$91,$F8,$A9,$71 ; 00/2154
    .byte $85,$F8,$A9,$21,$85,$F9,$A0,$00,$A9,$EA,$91,$F8,$A9,$7F,$85,$F8 ; 00/2164
    .byte $A9,$21,$85,$F9,$A0,$00,$A9,$EA,$91,$F8,$A9,$8D,$85,$F8,$A9,$21 ; 00/2174
    .byte $85,$F9,$A0,$00,$A9,$EA,$91,$F8,$A9,$00 ; 00/2184
    .byte " @ HELLO WORLD"      ; 00/218E
    .byte $00,$60               ; 00/219C
    .res 98                     ; 00/219E
    .byte $C8,$60               ; 00/2200
