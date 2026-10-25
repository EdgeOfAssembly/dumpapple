; negative: 65C02 code: bbs7 then an unconditional transfer (bra t) ends the 65C02 reading as
; valid; the $C2 and $00 table bytes after it are no breakdown, so no vouch for a 65816 slip.
.setcpu "65C02"
.org $2000
        .byte $FF,$10,$00       ; bbs7 $10,+0
t:      lda #$01
        .byte $80,$18              ; bra +$18 (a 65816 slip reads clc there)
        .byte $FB,$C2,$30,$00,$00,$00
        .res 18,0
        rts                        ; bra target
