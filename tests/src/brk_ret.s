; BRK with a `returns` hint continues after the signature byte
.p816
.org $2000
start:  brk $01
        lda #$01
        rts
