; dumpapple 0.9.0 listing of tests/progs/rules_imm.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o rules_imm.o rules_imm.s
;          ld65 -C rules_imm.cfg -o rules_imm.bin rules_imm.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $2E
.segment "SEG1"
.org $002000
entry_002000:
    lda #$18                    ; 00/2000: A9 18
    ldx #$20                    ; 00/2002: A2 20
    sta a:$03F2                 ; 00/2004: 8D F2 03
    stx a:$03F3                 ; 00/2007: 8E F3 03
    lda #$28                    ; 00/200A: A9 28
    ldy #$20                    ; 00/200C: A0 20
    jsr $FDED                   ; 00/200E: 20 ED FD
    rts                         ; 00/2011: 60
    .byte $00,$00,$00,$00,$00,$60 ; 00/2012
L002018:
    lda #$01                    ; 00/2018: A9 01
    sta z:$00                   ; 00/201A: 85 00
    rts                         ; 00/201C: 60
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 00/201D
    .byte "HELLO"               ; 00/2028
    .byte $00                   ; 00/202D
