; negative: 65C02 program; a message after the code contains $C2/$E2 (REP/SEP) bytes off the flow.
.setcpu "65C02"
.org $2000
        ldx #0
loop:   lda msg,x
        beq done
        jsr $FDED
        inx
        bne loop
done:   rts
msg:    .byte $C2,$30,$E2,$20,$82,$C1,0
