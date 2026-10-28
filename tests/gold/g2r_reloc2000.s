; dumpapple 0.10.0 listing of tests/progs/g2r_reloc.bin
; cpu 6502, platform prodos8
; rebuild: ca65 --cpu 6502 -t none -o g2r_reloc2000.o g2r_reloc2000.s
;          ld65 -C g2r_reloc2000.cfg -o g2r_reloc2000.bin g2r_reloc2000.o
; note: relocation loop at $2012 copies 2 page(s) from $2000 to $1000 and continues in the copy; the code is meant to run at $1000 (try --org 1000)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $A2
.segment "SEG1"
.org $002000
entry_002000:
    lda #$00                    ; 00/2000: A9 00
    sta z:$00                   ; 00/2002: 85 00
    sta z:$02                   ; 00/2004: 85 02
    lda #$20                    ; 00/2006: A9 20
    sta z:$01                   ; 00/2008: 85 01
    lda #$10                    ; 00/200A: A9 10
    sta z:$03                   ; 00/200C: 85 03
    ldx #$02                    ; 00/200E: A2 02
    ldy #$00                    ; 00/2010: A0 00
L002012:
    lda ($00),y                 ; 00/2012: B1 00
    sta ($02),y                 ; 00/2014: 91 02
    iny                         ; 00/2016: C8
    bne L002012                 ; 00/2017: D0 F9
    inc z:$01                   ; 00/2019: E6 01
    inc z:$03                   ; 00/201B: E6 03
    dex                         ; 00/201D: CA
    bne L002012                 ; 00/201E: D0 F2
    jmp $1023                   ; 00/2020: 4C 23 10
    .byte $20,$80,$10           ; 00/2023
    .byte "HELLO"               ; 00/2026
    .byte $00,$20,$80,$10,$41,$42,$00,$60 ; 00/202B
    .res 77                     ; 00/2033
    .byte $68,$85,$F0,$68,$85,$F1,$A0,$00 ; 00/2080
    .byte $C8,$B1,$F0,$F0       ; 00/2088 hi-ascii "H1pp"
    .byte $06,$20,$ED,$FD,$4C,$88,$10,$98,$18,$65,$F0,$85,$F0,$A5,$F1,$69 ; 00/208C
    .byte $00,$48,$A5,$F0,$48,$60 ; 00/209C
