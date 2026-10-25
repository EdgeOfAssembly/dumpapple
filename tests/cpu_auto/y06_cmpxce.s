; positive: cmp overwrites carry. sec; xce; clc; cmp #$00 leaves C=1, so the second xce stays in
; emulation and rep #$30 does nothing: lda #$01 / ldx #$02 are 2 bytes. A checker that kept C=0
; from the clc would go native, widen at the rep and reject the file.
.setcpu "65816"
.org $2000
        phk
        plb
        sec
        xce
        clc
        cmp #$00
        xce
        rep #$30
        lda #$01
        ldx #$02
        sta $10
        sep #$30
        rts
