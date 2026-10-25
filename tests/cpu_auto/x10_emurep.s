; positive: emulation case. sec; xce enters emulation mode, where rep #$30 cannot widen m/x, so
; lda #$01 is 2 bytes and ldx #$02 follows. Read 16-bit, the lda would swallow the ldx opcode and
; land on $02 (cop) - the clean-run check must read it 8-bit. Valid 65816 code -> 65816.
.setcpu "65816"
.org $2000
        phk
        plb
        sec
        xce
        rep #$30
        lda #$01
        ldx #$02
        sta $10
        sep #$30
        rts
