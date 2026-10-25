; positive: lda [$10],y ($B7, 2 bytes on both CPUs: SMB3 on a 65C02) before the first key
; instruction; the decodes stay in step and the rep agrees.
.setcpu "65816"
.org $2000
        lda [$10],y
        rep #$30
        .a16
        .i16
        sta $1000
        sep #$30
        .a8
        .i8
        rts
