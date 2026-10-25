; negative: sec; xce (stays in emulation mode) and a 65C02 program; no native-mode evidence.
.setcpu "65C02"
.org $2000
        sec
        .byte $FB
        stz $00
        rts
