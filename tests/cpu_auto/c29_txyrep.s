; positive: txy; ...; rep prologue.
.setcpu "65816"
.org $2000
        txy
        lda #1
        sta $10
        rep #$20
        .a16
        lda $10
        sep #$20
        .a8
        rts
