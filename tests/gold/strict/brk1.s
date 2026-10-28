; dumpapple 0.10.0 listing of tests/progs/brk1.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o brk1.o brk1.s
;          ld65 -C brk1.cfg -o brk1.bin brk1.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)
; note: single-byte BRK at $002002: flow continues at $002003

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $5
.segment "SEG1"
.org $002000
entry_002000:
    bcc L002003                 ; 00/2000: 90 01
    .byte $00                   ; 00/2002
L002003:
    nop                         ; 00/2003: EA
    rts                         ; 00/2004: 60
