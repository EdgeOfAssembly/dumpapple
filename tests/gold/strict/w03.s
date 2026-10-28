; dumpapple 0.10.0 listing of tests/progs/w03.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o w03.o w03.s
;          ld65 -C w03.cfg -o w03.bin w03.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $15
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    ldy a:$0300                 ; 00/2000: AC 00 03
    lda #$00                    ; 00/2003: A9 00
    sta a:$200B,y               ; 00/2005: 99 0B 20
    clc                         ; 00/2008: 18
    xce                         ; 00/2009: FB
    rep #$20                    ; 00/200A: C2 20
; code flow reached here but decoding stopped: accumulator width unknown (M flag conflict)
    .byte $A9,$60,$60,$A9,$00,$8D,$00,$C0,$60 ; 00/200C
