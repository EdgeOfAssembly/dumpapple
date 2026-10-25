; positive: phk; plb; rep prologue (weak hits away from text, then an agreed-path key).
.setcpu "65816"
.org $2000
        phk
        plb
        rep #$30
        .a16
        .i16
        lda #$1234
        sep #$30
        .a8
        .i8
        rts
