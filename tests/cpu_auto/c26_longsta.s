; positive: lda $E10000; sta $0300; rep: the 65C02 reading of the long op runs into a brk.
.setcpu "65816"
.org $2000
        lda $E10000
        sta $0300
        rep #$30
        sep #$30
        rts
