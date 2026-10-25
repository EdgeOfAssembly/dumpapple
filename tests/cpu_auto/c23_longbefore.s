; positive: lda $E10000 ($AF, 4 bytes on a 65816, BBS2 3 bytes on a 65C02) before rep: the
; 65C02 decode slips at the $AF, so the rep is accepted through the long instruction itself.
.setcpu "65816"
.org $2000
        lda $E10000
        rep #$30
        .a16
        .i16
        sta $1000
        sep #$30
        .a8
        .i8
        rts
