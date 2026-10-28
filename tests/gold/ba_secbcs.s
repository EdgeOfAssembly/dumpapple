; dumpapple 0.10.0 listing of tests/progs/ba_secbcs.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o ba_secbcs.o ba_secbcs.s
;          ld65 -C ba_secbcs.cfg -o ba_secbcs.bin ba_secbcs.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $7
.segment "SEG1"
.org $002000
entry_002000:
    sec                         ; 00/2000: 38
    bcs L002006                 ; 00/2001: B0 03
    .byte $48,$49,$00           ; 00/2003
L002006:
    rts                         ; 00/2006: 60
