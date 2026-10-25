; negative: bbs7 then ora ($C2,x) ($01).
.setcpu "65C02"
.org $2000
        lda #$80
        sta $12
        .byte $FF,$12,$00          ; bbs7 $12,+0
        ora ($C2,x)
        rts
