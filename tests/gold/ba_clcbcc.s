; dumpapple 0.9.0 listing of tests/progs/ba_clcbcc.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o ba_clcbcc.o ba_clcbcc.s
;          ld65 -C ba_clcbcc.cfg -o ba_clcbcc.bin ba_clcbcc.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $7
.segment "SEG1"
.org $002000
entry_002000:
    clc                         ; 00/2000: 18
    bcc L002006                 ; 00/2001: 90 03
    .byte $48,$49,$00           ; 00/2003
L002006:
    rts                         ; 00/2006: 60
