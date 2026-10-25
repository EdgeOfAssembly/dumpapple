; positive: clc;xce with the carry known clear at the entry, then [dp] and long ops
; ($x7 opcodes, which a 65C02 would read as rmb/smb) -> 65816.
.setcpu "65816"
.org $2000
        clc
        xce
        rep #$30
        .a16
        .i16
        lda [$10]
        sta [$14],y
        lda $E12000
        sta f:$E12002
        sep #$30
        .a8
        .i8
        sec
        xce
        rts
