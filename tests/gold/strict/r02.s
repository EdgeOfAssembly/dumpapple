; dumpapple 0.10.0 listing of tests/progs/r02.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o r02.o r02.s
;          ld65 -C r02.cfg -o r02.bin r02.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $18
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    clc                         ; 00/2000: 18 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
    xce                         ; 00/2001: FB ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
    rep #$30                    ; 00/2002: C2 30 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
; code flow reached here but decoding stopped: index width unknown (X flag conflict)
    .byte $A2,$00,$02,$9E,$00,$1F,$CA,$10,$FA,$E2,$20,$A9,$60,$60,$A9,$00 ; 00/2004
    .byte $8D,$00,$C0,$60       ; 00/2014
