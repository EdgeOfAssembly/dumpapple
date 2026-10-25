; negative: 65C02 code; data after RTS starts with $82 (BRL) and $18 $FB.
.setcpu "65C02"
.org $2000
        stz $00
        lda #1
        rts
        .byte $82,$07,$00,$18,$FB,$C2,$30
