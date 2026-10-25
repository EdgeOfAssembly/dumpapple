; BIT-skip idiom: two real entry points overlap (sec / bit $18 hides a clc)
.p816
.org $2000
start:  jsr set
        jsr clr
        rts
set:    sec
        .byte $24               ; bit zp: skips the next byte
clr:    clc
        rts
