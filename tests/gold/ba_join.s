; dumpapple 0.10.0 listing of tests/progs/ba_join.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o ba_join.o ba_join.s
;          ld65 -C ba_join.cfg -o ba_join.bin ba_join.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $C
.segment "SEG1"
.org $002000
entry_002000:
    lda z:$F0                   ; 00/2000: A5 F0
    beq L002007                 ; 00/2002: F0 03
    clc                         ; 00/2004: 18
    bcc L002008                 ; 00/2005: 90 01
L002007:
    sec                         ; 00/2007: 38
L002008:
    bcs L00200B                 ; 00/2008: B0 01
    rts                         ; 00/200A: 60
L00200B:
    rts                         ; 00/200B: 60
