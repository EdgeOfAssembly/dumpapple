; dumpapple 0.9.0 listing of tests/progs/bitskip.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o bitskip.o bitskip.s
;          ld65 -C bitskip.cfg -o bitskip.bin bitskip.o
; note: overlapping entry point at $002009 (BIT-skip style; label emitted as an equate)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $B
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    jsr .loword(sub_002007)     ; 00/2000: 20 07 20
    jsr .loword(sub_002009)     ; 00/2003: 20 09 20
    rts                         ; 00/2006: 60
sub_002007:
    sec                         ; 00/2007: 38
    bit z:$18                   ; 00/2008: 24 18
    rts                         ; 00/200A: 60

; labels that do not start a listing line
sub_002009 = $002009
