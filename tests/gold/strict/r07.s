; dumpapple 0.10.0 listing of tests/progs/r07.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o r07.o r07.s
;          ld65 -C r07.cfg -o r07.bin r07.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $13
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    clc                         ; 00/2000: 18
    xce                         ; 00/2001: FB
    sep #$20                    ; 00/2002: E2 20
    lda #$38                    ; 00/2004: A9 38
    sta a:$200B                 ; 00/2006: 8D 0B 20
    nop                         ; 00/2009: EA
    nop                         ; 00/200A: EA
    clc                         ; 00/200B: 18 ; changed by a store before it runs: runs as sec (38) (self-modifying code)
    xce                         ; 00/200C: FB
    rep #$20                    ; 00/200D: C2 20
    lda #$00                    ; 00/200F: A9 00
    .byte $00,$60               ; 00/2011: 00 60 brk $60
