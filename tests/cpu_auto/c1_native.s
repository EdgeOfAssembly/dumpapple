; positive: GS-program shape: BRL over a debug name, then clc/xce.
.setcpu "65816"
.org $2000
        brl start
        .word $7771
        .byte 4,"main"
start:  clc
        xce
        rep #$30
        .a16
        .i16
        lda #$1234
        sec
        xce
        rts
