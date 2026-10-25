; negative: bbs7 then sbc ($E2,x) ($E1): valid 65C02, a 65816 slip reads sep.
.setcpu "65C02"
.org $2000
        lda #$80
        sta $12
        .byte $FF,$12,$00          ; bbs7 $12,+0
        sbc ($E2,x)
        rts
