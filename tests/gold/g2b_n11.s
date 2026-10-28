; dumpapple 0.10.0 listing of tests/progs/g2b_n11.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2b_n11.o g2b_n11.s
;          ld65 -C g2b_n11.cfg -o g2b_n11.bin g2b_n11.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $202
.segment "SEG1"
.org $002000
entry_002000:
    jmp .loword(L002100)        ; 00/2000: 4C 00 21
    .res 61                     ; 00/2003
    .byte $68,$85,$F0,$68,$85,$F1,$A0,$00 ; 00/2040
    .byte $C8,$B1,$F0,$F0       ; 00/2048 hi-ascii "H1pp"
    .byte $06,$20,$ED,$FD,$4C,$48,$20,$98,$18,$65,$F0,$85,$F0,$A5,$F1,$69 ; 00/204C
    .byte $00,$48,$A5,$F0,$48,$60 ; 00/205C
    .res 158                    ; 00/2062
L002100:
    lda #$21                    ; 00/2100: A9 21
    pha                         ; 00/2102: 48
    lda #$0A                    ; 00/2103: A9 0A
    pha                         ; 00/2105: 48
    lda #$38                    ; 00/2106: A9 38
    pha                         ; 00/2108: 48
    rti                         ; 00/2109: 40
    .byte " @ HELLO WORLD"      ; 00/210A
    .byte $00,$60               ; 00/2118
    .res 230                    ; 00/211A
    .byte $C8,$60               ; 00/2200
