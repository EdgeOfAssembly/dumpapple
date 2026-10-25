; negative: 65C02 Rockwell bit ops ($x7/$xF) look like 65816 long addressing; not evidence.
.setcpu "65C02"
.org $2000
        rmb0 $10
        smb7 $11
        bbr1 $10,skip
        lda $1234
skip:   bbs2 $11,done
        nop
done:   rts
