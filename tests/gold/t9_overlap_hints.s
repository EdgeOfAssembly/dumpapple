; dumpapple 0.10.0 listing of tests/progs/t9_overrun.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o t9_overlap_hints.o t9_overlap_hints.s
;          ld65 -C t9_overlap_hints.cfg -o t9_overlap_hints.bin t9_overlap_hints.o
; note: warning: table hint at $002006 overlaps another table; ignored
; note: hinted table $002005: 1 entry used by $002002

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $21
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    ldx #$00                    ; 00/2000: A2 00
    jmp ($2005,x)               ; 00/2002: 7C 05 20
D002005:
; jump table (hint): 1 word entry, used by $002002
    .word .loword(L00200D)      ; 00/2005 -> $00200D
    .byte $20,$20               ; 00/2007
sub_002009:
    jsr .loword(sub_002020)     ; 00/2009: 20 20 20
    rts                         ; 00/200C: 60
L00200D:
    jsr .loword(sub_002009)     ; 00/200D: 20 09 20
    rts                         ; 00/2010: 60
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/2011 hi-ascii "jjjjjjjjjjjjjjj"
sub_002020:
    rts                         ; 00/2020: 60
