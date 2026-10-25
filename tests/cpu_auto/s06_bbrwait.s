; negative: realistic wait loop: w: bbr7 $C0,w; cpx #$E2.
.setcpu "65C02"
.org $2000
w:      .byte $7F,$C0,$FD          ; bbr7 $C0,w
        cpx #$E2
        beq w
        rts
