; dumpapple 0.10.0 listing of tests/progs/w02.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o w02.o w02.s
;          ld65 -C w02.cfg -o w02.bin w02.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $12
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    lda #$38                    ; 00/2000: A9 38
    sta a:$2005                 ; 00/2002: 8D 05 20
    clc                         ; 00/2005: 18 ; changed by a store before it runs: runs as sec (38) (self-modifying code)
    xce                         ; 00/2006: FB
    rep #$20                    ; 00/2007: C2 20
    lda #$60                    ; 00/2009: A9 60
    rts                         ; 00/200B: 60
    .byte $A9,$00,$8D,$00,$C0,$60 ; 00/200C
