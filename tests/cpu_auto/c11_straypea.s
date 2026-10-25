; negative: 65C02 program whose flow runs into a byte table; one $F4 (pea on a 65816) is not enough.
.setcpu "65C02"
.org $2000
        lda #1
        .byte $0C,$09,$07,$06,$0C,$F4,$01,$02,$60
