; negative: 65816-looking bytes reachable only through an unresolved jmp (pointer unknown).
.setcpu "65C02"
.org $2000
        lda $300
        beq out
        jmp ($0300)
out:    rts
        .byte $18,$FB,$C2,$30,$22,$00,$10,$00,$82,$00,$00
