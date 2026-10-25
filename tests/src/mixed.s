; Mixed widths m8x16 and m16x8, PLP/PHP pairs, mode switches back to emulation
.setcpu "65816"
.org $8000
start:  clc
        xce
        sep #$20
        rep #$10
        .a8
        .i16
        lda #$01
        ldx #$1234
        cpx #$2000
        bcc @skip
        rep #$20
        sep #$10
        .a16
        .i8
        lda #$1234
        ldx #$12
        sep #$20
        rep #$10
        .a8
        .i16
@skip:  ldy #$ABCD
        cpy #$0001
        sec
        xce                 ; back to emulation: m8 x8
        .a8
        .i8
        lda #$FF
        ldx #$EE
        cmp #$10
        bit #$01
        and #$0F
        eor #$F0
        adc #$01
        sbc #$02
        ora #$03
        cpx #$04
        cpy #$05
        rti
