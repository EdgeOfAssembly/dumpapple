; positive: IIgs prologue phk; plb; rep #$30; lda #$0001 (16-bit immediate, zero high byte).
.setcpu "65816"
.org $2000
        phk
        plb
        rep #$30
        .a16
        .i16
        lda #$0001
        sta $10
        sep #$30
        .a8
        .i8
        rts
