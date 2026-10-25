; positive: lda $E1C029,x ($BF, BBS3 on a 65C02) then jsl to the toolbox dispatcher.
.setcpu "65816"
.org $2000
        ldx #0
        lda $E1C029,x
        jsl $E10000
        rts
