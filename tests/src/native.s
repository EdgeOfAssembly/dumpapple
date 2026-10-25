; Native-mode program: XCE, REP/SEP in branches and at subroutine entry,
; JSL/RTL, JML, BRL, MVN/MVP, PEA/PER, PHP/PLP, conflicting join.
.setcpu "65816"
.org $2000
start:  clc
        xce                 ; native, m8 x8
        rep #$30
        .a16
        .i16
        lda #$1234
        ldx #$5678
        ldy #$0000
        jsr sub16           ; subroutine that sets its own widths
        sep #$20
        .a8
        lda #$12
        lda $00
        bne @eight
        rep #$20            ; REP inside a branch, re-joined after SEP: consistent
        .a16
        lda #$BEEF
        sep #$20
        .a8
@eight: lda #$34
        php
        rep #$30
        .a16
        .i16
        lda #$FFFF
        plp                 ; back to m8 x16
        .a8
        lda #$56
        jsl farsub
        pea $C0DE
        per data1
        mvn #$01,#$02
        mvp #$03,#$04
        brl later
        .byte $EA,$EA       ; never reached
later:  lda f:$E10000
        sta f:$012345,x
        lda [$10],y
        lda ($12,s),y
        lda $03,s
        jml far2
data1:  .word $1111, $2222
sub16:  rep #$30
        .a16
        .i16
        lda #$0001
        rts
        .a8
farsub: phb
        phk
        plb
        lda #$7F
        plb
        rtl
far2:   sep #$30            ; join into conflict below
        .a8
        .i8
        lda $20
        beq @w16
        bra @join
@w16:   rep #$20
        .a16
@join:  ; M is 8 on one path, 16 on the other: the next lda #imm is ambiguous
        .a16
        lda #$4321
        stp
