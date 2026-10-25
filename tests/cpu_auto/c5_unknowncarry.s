; negative: xce with unknown carry is not evidence of native mode.
.setcpu "65C02"
.org $2000
        lda $00
        ror a
        .byte $FB       ; xce, carry unknown
        rts
