; dumpapple 0.10.0 listing of tests/progs/r05.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o r05.o r05.s
;          ld65 -C r05.cfg -o r05.bin r05.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $1C
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    clc                         ; 00/2000: 18
    xce                         ; 00/2001: FB
    rep #$30                    ; 00/2002: C2 30
    .a16
    .i16
    lda #$1F00                  ; 00/2004: A9 00 1F
    tcd                         ; 00/2007: 5B
    ldx #$00FE                  ; 00/2008: A2 FE 00
L00200B:
    stz z:$00,x                 ; 00/200B: 74 00
    dex                         ; 00/200D: CA
    dex                         ; 00/200E: CA
    bpl L00200B                 ; 00/200F: 10 FA
    sep #$20                    ; 00/2011: E2 20
    .a8
    lda #$60                    ; 00/2013: A9 60
    rts                         ; 00/2015: 60
    .byte $A9,$00,$8D,$00,$C0,$60 ; 00/2016
