; dumpapple 0.10.0 listing of tests/progs/rtl_long.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o rtl_long.o rtl_long.s
;          ld65 -C rtl_long.cfg -o rtl_long.bin rtl_long.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)
; note: auto table $002010: 2 entries used by $00200E (stopped: target outside image)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $26
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    ldx z:$80                   ; 00/2000: A6 80
    lda a:$2012,x               ; 00/2002: BD 12 20
    pha                         ; 00/2005: 48
    lda a:$2011,x               ; 00/2006: BD 11 20
    pha                         ; 00/2009: 48
    lda a:$2010,x               ; 00/200A: BD 10 20
    pha                         ; 00/200D: 48
    rtl                         ; 00/200E: 6B ; rtl dispatch through table $002010
    .byte $00                   ; 00/200F
D002010:
; jump table (auto): 2 rtl long (addr-1) entries, used by $00200E, heuristic stopped: target outside image
    .faraddr L002020-1          ; 00/2010 -> $002020
    .faraddr L002024-1          ; 00/2013 -> $002024
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 00/2016
L002020:
    rtl                         ; 00/2020: 6B
    .byte $00,$00,$00           ; 00/2021
L002024:
    nop                         ; 00/2024: EA
    rtl                         ; 00/2025: 6B
