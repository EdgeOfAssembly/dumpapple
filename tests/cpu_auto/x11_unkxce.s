; positive: xce with unknown carry leaves E unknown; rep #$30 then cannot make m/x known, and the
; 16-bit immediate lda #$0001 passes through the both-sizes split -> 65816.
.setcpu "65816"
.org $2000
        phk
        plb
        xce
        rep #$30
        .a16
        .i16
        lda #$0001
        sta $10
        sep #$30
        .a8
        .i8
        rts
