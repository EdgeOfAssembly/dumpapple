; negative: 65C02 code using $02/$42 two-byte NOPs on flow (COP/WDM on 65816).
.setcpu "65C02"
.org $2000
        stz $00
        .byte $02,$EA   ; 2-byte NOP on 65C02, COP on 65816
        .byte $42,$EA   ; 2-byte NOP on 65C02, WDM on 65816
        lda #1
        rts
