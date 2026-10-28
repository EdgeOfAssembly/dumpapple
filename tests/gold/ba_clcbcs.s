; dumpapple 0.10.0 listing of tests/progs/ba_clcbcs.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o ba_clcbcs.o ba_clcbcs.s
;          ld65 -C ba_clcbcs.cfg -o ba_clcbcs.bin ba_clcbcs.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $6
.segment "SEG1"
.org $002000
entry_002000:
    clc                         ; 00/2000: 18
    bcs $002005                 ; 00/2001: B0 02
    nop                         ; 00/2003: EA
    rts                         ; 00/2004: 60
    .byte $02                   ; 00/2005
