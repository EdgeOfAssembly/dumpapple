; dumpapple 0.10.0 listing of tests/progs/rules_imm.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o rules_imm_off.o rules_imm_off.s
;          ld65 -C rules_imm_off.cfg -o rules_imm_off.bin rules_imm_off.o

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
    .byte $00,$00,$00,$00,$00,$60,$A9,$01,$85,$00,$60,$00,$00,$00,$00,$00 ; 00/2012
    .byte $00,$00,$00,$00,$00,$00 ; 00/2022
    .byte "HELLO"               ; 00/2028
    .byte $00                   ; 00/202D
