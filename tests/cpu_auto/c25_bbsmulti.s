; negative: two bbs7 slips onto immediates $C2/$22 (rep/jsl to a slipped 65816 decode).
.setcpu "65C02"
.org $2000
 lda #$FF
 sta $12
 .byte $FF,$12,$00
 ldx #$C2
 .byte $FF,$12,$00
 ldy #$22
 rts
