; negative: 65C02 code: bbs7 then an unconditional transfer (rts) ends the 65C02 reading as
; valid; the $C2 and $00 table bytes after it are no breakdown, so no vouch for a 65816 slip.
.setcpu "65C02"
.org $2000
        .byte $FF,$10,$00       ; bbs7 $10,+0
t:      lda #$01
        rts
        .byte $C2,$30,$00,$00,$00,$00
