; dumpapple 0.10.0 listing of tests/progs/ba_settgt.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o ba_settgt.o ba_settgt.s
;          ld65 -C ba_settgt.cfg -o ba_settgt.bin ba_settgt.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $C
.segment "SEG1"
.org $002000
entry_002000:
    lda z:$F0                   ; 00/2000: A5 F0
    bne L002005                 ; 00/2002: D0 01
    nop                         ; 00/2004: EA
L002005:
    sec                         ; 00/2005: 38
    bcs L00200B                 ; 00/2006: B0 03
    .byte $48,$49,$00           ; 00/2008
L00200B:
    rts                         ; 00/200B: 60
