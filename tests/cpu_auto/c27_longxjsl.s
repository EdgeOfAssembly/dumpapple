; positive: sta $E10000,x then jsl: the 65C02 reading runs into a brk.
.setcpu "65816"
.org $2000
        ldx #0
        sta $E10000,x
        jsl $E100A8
        rts
