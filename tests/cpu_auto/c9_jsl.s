; positive: one jsl on flow, no xce (an emulation-mode 65816 program, e.g. calling the IIgs toolbox).
.setcpu "65816"
.org $2000
        lda #1
        jsl $E10000
        rts
