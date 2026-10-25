; positive: 65816 code reached only through jmp (tab,x) with X known; the 65C02 decode uses the
; same table but refuses the entry (rep there), so the edge agrees.
.setcpu "65816"
.org $2000
        ldx #2
        jmp (tab,x)
tab:    .word r1, r2
r1:     rts
r2:     rep #$30
        sep #$30
        rts
