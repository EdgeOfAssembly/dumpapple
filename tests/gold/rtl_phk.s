; dumpapple 0.10.0 listing of tests/progs/rtl_phk.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o rtl_phk.o rtl_phk.s
;          ld65 -C rtl_phk.cfg -o rtl_phk.bin rtl_phk.o
; note: auto table $002010: 1 entry used by $00200B (stopped: index guard)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $21
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    ldx #$00                    ; 00/2000: A2 00
    phk                         ; 00/2002: 4B
    lda a:$2011,x               ; 00/2003: BD 11 20
    pha                         ; 00/2006: 48
    lda a:$2010,x               ; 00/2007: BD 10 20
    pha                         ; 00/200A: 48
    rtl                         ; 00/200B: 6B ; rtl dispatch through table $002010
    .byte $00,$00,$00,$00       ; 00/200C
D002010:
; jump table (auto): 1 rts (addr-1) entry, used by $00200B, heuristic stopped: index guard
    .word .loword(L002020-1)    ; 00/2010 -> $002020
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 00/2012
L002020:
    rtl                         ; 00/2020: 6B
