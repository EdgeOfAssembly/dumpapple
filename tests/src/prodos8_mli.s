; ProDOS 8 MLI: JSR $BF00 is followed by a command byte and a parameter list pointer.
.setcpu "6502"
.org $2000
start:  jsr $BF00
        .byte $C8               ; OPEN
        .word parms
        bcs err
        lda #$00
err:    rts
parms:  .byte 3
        .word name
name:   .byte 4, "FILE"
