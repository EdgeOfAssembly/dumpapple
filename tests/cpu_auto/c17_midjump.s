; negative: a branch into the operand of sta $82 (a jump into data at a wrong origin, the cc65
; file shape): the 65816 reads brl there, the 65C02 decode has the sta and stops on $82.
.setcpu "65C02"
.org $2000
        ldx $300
        bne t+1
t:      sta $82
        stx $83
        lda #$A2
        rts
