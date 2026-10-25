; positive: phb; phk; plb; rep #$10; ldx #$0000; lda #$00 (x 16-bit, m 8-bit).
.setcpu "65816"
.org $2000
        phb
        phk
        plb
        rep #$10
        .i16
        ldx #$0000
        lda #$00
        sep #$10
        .i8
        plb
        rts
