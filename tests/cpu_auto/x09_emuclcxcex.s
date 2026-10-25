; positive: as x07 with an index immediate too: entered in emulation, rep #$30 is a no-op,
; clc; xce goes native at 8-bit, so lda #$01 and ldx #$02 are 2 bytes each.
.setcpu "65816"
.org $2000
        phk
        plb
        rep #$30
        clc
        xce
        lda #$01
        ldx #$02
        stx $11
        sta $10
        sep #$30
        rts
