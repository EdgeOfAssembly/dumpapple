; positive: entered in emulation mode (a raw binary), rep #$30 has no effect, clc; xce enters native
; at 8-bit, so lda #$01 is 2 bytes. The clean-run check starts with E unknown and must accept it. (sta $00: a 16-bit misread runs into its $00 as brk)
.setcpu "65816"
.org $2000
        phk
        plb
        rep #$30
        clc
        xce
        lda #$01
        sta $00
        sep #$30
        rts
