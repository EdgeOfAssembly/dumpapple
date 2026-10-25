; negative: $03 is a 1-byte NOP on a 65C02 but ora sr (2 bytes) on a 65816 -> slips onto $C2.
.setcpu "65C02"
.org $2000
        .byte $03
        ldx #$C2
        rts
