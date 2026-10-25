; positive: plp in emulation mode does not change E: m/x stay 8-bit, so after rep #$30 the
; lda #$01 is still 2 bytes (16-bit would land on $02, cop) -> 65816.
.setcpu "65816"
.org $2000
        phk
        plb
        sec
        xce
        php
        plp
        rep #$30
        lda #$01
        ldx #$02
        sta $10
        sep #$30
        rts
