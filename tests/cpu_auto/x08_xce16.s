; positive: rep #$30; clc; xce; lda #$0001 after a phk; plb prologue: xce leaves m/x unknown to the
; clean-run reading (here still 16-bit, the code already ran native), so a 16-bit immediate is fine.
.setcpu "65816"
.org $2000
        phk
        plb
        rep #$30
        clc
        xce
        .a16
        .i16
        lda #$0001
        sta $10
        sep #$30
        .a8
        .i8
        rts
