; negative: bbr0 then immediates $C2/$E2/$22 that a slipped 65816 decode reads as rep/sep/jsl.
.setcpu "65C02"
.org $2000
        lda #0
        sta $12
        .byte $0F,$12,$00          ; bbr0 $12,+0
        ldx #$C2
        ldy #$E2
        lda #$22
        rts
