; dumpapple 0.9.0 listing of tests/progs/rts_tail.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o rts_tail.o rts_tail.s
;          ld65 -C rts_tail.cfg -o rts_tail.bin rts_tail.o
; note: auto table $002010: 2 entries used by $00200E (stopped: index guard)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $1B
.segment "SEG1"
.org $002000
entry_002000:
    ldy #$02                    ; 00/2000: A0 02
    lda a:$2011,y               ; 00/2002: B9 11 20
    pha                         ; 00/2005: 48
    lda a:$2010,y               ; 00/2006: B9 10 20
    pha                         ; 00/2009: 48
    lda z:$A5                   ; 00/200A: A5 A5
    ldy z:$A4                   ; 00/200C: A4 A4
    rts                         ; 00/200E: 60 ; rts dispatch through table $002010
    .byte $00                   ; 00/200F
D002010:
; jump table (auto): 2 rts (addr-1) entries, used by $00200E, heuristic stopped: index guard
    .word .loword(L002017-1)    ; 00/2010 -> $002017
    .word .loword(L002019-1)    ; 00/2012 -> $002019
    .byte $00,$00,$00           ; 00/2014
L002017:
    rts                         ; 00/2017: 60
    .byte $00                   ; 00/2018
L002019:
    nop                         ; 00/2019: EA
    rts                         ; 00/201A: 60
