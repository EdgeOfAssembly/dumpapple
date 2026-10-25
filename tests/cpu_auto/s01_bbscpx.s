; negative: bbs7 then cpx #$C2: the byte after the BBS ($E0) is a canonical bank to a
; 65816 long reading, but the 65C02 reading carries on validly, so the long op vouches nothing.
.setcpu "65C02"
.org $2000
        lda #$80
        sta $12
t:      .byte $FF,$12,$00          ; bbs7 $12,+0
        cpx #$C2
        bne t
        rts
