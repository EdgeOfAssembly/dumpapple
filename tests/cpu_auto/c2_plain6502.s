; negative: plain 6502 ProDOS 8 SYS file.
.setcpu "6502"
.org $2000
        ldx #0
loop:   lda msg,x
        beq done
        jsr $FDED
        inx
        bne loop
done:   jsr $BF00
        .byte $65
        .word parms
        rts
parms:  .byte 4,0,0,0,0,0,0
msg:    .byte "HELLO",0
