; positive: three 65816-only stack/register ops (phb, xba, plb) on flow, no mode switch.
.setcpu "65816"
.org $2000
        phb
        lda #1
        xba
        plb
        rts
