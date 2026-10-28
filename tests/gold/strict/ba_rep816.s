; dumpapple 0.10.0 listing of tests/progs/ba_rep816.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o ba_rep816.o ba_rep816.s
;          ld65 -C ba_rep816.cfg -o ba_rep816.bin ba_rep816.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $10
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    clc                         ; 00/2000: 18
    xce                         ; 00/2001: FB
    lda z:$F0                   ; 00/2002: A5 F0
    bne L002006                 ; 00/2004: D0 00
L002006:
    rep #$01                    ; 00/2006: C2 01
    bcc L00200D                 ; 00/2008: 90 03
    .byte $48,$49,$00           ; 00/200A
L00200D:
    sec                         ; 00/200D: 38
    xce                         ; 00/200E: FB
    rts                         ; 00/200F: 60
