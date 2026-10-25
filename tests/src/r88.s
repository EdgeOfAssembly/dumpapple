; regression (review ce21145a4): 8/8 native immediates
.setcpu "65816"
.org $2000
        clc
        xce
        sep #$30
        .a8
        .i8
        lda #$12
        ldx #$34
        rts
