; dumpapple 0.10.0 listing of tests/progs/rts_16.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o rts_16.o rts_16.s
;          ld65 -C rts_16.cfg -o rts_16.bin rts_16.o
; note: auto table $002010: 1 entry used by $002006 (stopped: index guard)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $21
.segment "SEG1"
.org $002000
entry_002000:
    .a16
    .i8
    ldx #$00                    ; 00/2000: A2 00
    lda a:$2010,x               ; 00/2002: BD 10 20
    pha                         ; 00/2005: 48
    rts                         ; 00/2006: 60 ; rts dispatch through table $002010
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00 ; 00/2007
D002010:
; jump table (auto): 1 rts (addr-1) entry, used by $002006, heuristic stopped: index guard
    .word .loword(L002020-1)    ; 00/2010 -> $002020
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 00/2012
L002020:
    rts                         ; 00/2020: 60
