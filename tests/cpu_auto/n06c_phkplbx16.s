; positive: phk; plb; rep #$30; ldx #$0010 (16-bit index immediate).
.setcpu "65816"
.org $2000
        phk
        plb
        rep #$30
        .a16
        .i16
        ldx #$0010
        ldy #$0000
        sep #$30
        .a8
        .i8
        rts
