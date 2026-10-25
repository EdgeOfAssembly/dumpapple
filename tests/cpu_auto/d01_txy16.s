; positive: txy; rep #$20; lda #$0001; sep #$20 (m tracked, x stays 8-bit).
.setcpu "65816"
.org $2000
        txy
        rep #$20
        .a16
        lda #$0001
        ldx #$00
        sep #$20
        .a8
        rts
