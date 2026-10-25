; Emulation-mode program (6502-style), org $2000
.setcpu "65816"
.org $2000
start:  sei
        cld
        ldx #$FF
        txs
        lda #$00
        sta $10
loop:   ldy #$00
@l2:    lda msg,y
        beq done
        jsr putc
        iny
        bne @l2
done:   lda #<hitext
        sta $06
        lda #>hitext
        sta $07
        jmp (vec)
putc:   ora #$80
        sta $C000,x
        bit $C010
        bvc :+
        dex
:       rts
vec:    .word start
msg:    .byte "HELLO, WORLD", 0
hitext: .byte $C8,$C9,$A0,$D4,$C8,$C5,$D2,$45   ; "HI THERE" last byte clear
table:  .byte 1,2,3,4,5,$22,$5C,0,0,0
        .res 20
        .byte $FF
