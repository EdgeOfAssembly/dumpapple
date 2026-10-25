; negative: bbs0 is 3 bytes on a 65C02 but the 65816 reads $0F as a 4-byte ora long, so its
; decode slips onto the lda operand $E2 (sep). The 65C02 decode has no instruction there.
.setcpu "65C02"
.org $2000
        lda #1
        sta $10
        .byte $9F,$10,$00          ; bbs1 $10,+0
        lda #$E2
        sta $400
        rts
