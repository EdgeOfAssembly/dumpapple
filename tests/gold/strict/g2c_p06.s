; dumpapple 0.10.0 listing of tests/progs/g2c_p06.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2c_p06.o g2c_p06.s
;          ld65 -C g2c_p06.cfg -o g2c_p06.bin g2c_p06.o
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
    lda #$36                    ; 00/2100: A9 36 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
    sta a:$210B                 ; 00/2102: 8D 0B 21 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $A9,$00,$8D,$0F,$21,$A9,$00,$85,$F8,$A9,$04,$85,$F9,$A0,$00,$A9 ; 00/2105
    .byte $00,$91,$F8           ; 00/2115
    .byte " @ HELLO WORLD"      ; 00/2118
    .byte $00,$60               ; 00/2126
    .res 216                    ; 00/2128
    .byte $C8,$60               ; 00/2200
