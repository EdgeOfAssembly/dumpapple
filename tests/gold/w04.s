; dumpapple 0.10.0 listing of tests/progs/w04.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o w04.o w04.s
;          ld65 -C w04.cfg -o w04.bin w04.o

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $12
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    lda #$00                    ; 00/2000: A9 00
    sta a:$2008                 ; 00/2002: 8D 08 20
    clc                         ; 00/2005: 18
    xce                         ; 00/2006: FB
    rep #$20                    ; 00/2007: C2 20 ; changed by a store before it runs: runs as rep (C2 00) (self-modifying code)
    lda #$60                    ; 00/2009: A9 60
    rts                         ; 00/200B: 60
    .byte $A9,$00,$8D,$00,$C0,$60 ; 00/200C
