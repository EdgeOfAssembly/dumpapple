; Code in bank $02 with 24-bit labels, JSR/JMP within bank, JML/JSL across,
; indirect jumps and a jump table described by a hints file.
.setcpu "65816"
.org $021000
start:  rep #$30
        .a16
        .i16
        jsr .loword(init)
        lda #$0002
        asl a
        tax
        jmp (.loword(jtab),x)
init:   stz $00
        stz a:$1234
        lda ($10)
        lda [$10]
        lda ($10,x)
        lda ($10),y
        lda a:$1234,y
        lda f:$123456
        lda f:$123456,x
        jsl $E10000
        jml [$00F0]
        jmp ($1000)
        cop $05
        brk $00
        wdm $42
        rts
jtab:   .word .loword(h0), .loword(h1), .loword(h2)
h0:     inc a
        rts
h1:     dec a
        rts
h2:     xba
        tcd
        tdc
        txy
        tyx
        rts
