; dumpapple 0.10.0 listing of tests/progs/rmw_once.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o rmw_once.o rmw_once.s
;          ld65 -C rmw_once.cfg -o rmw_once.bin rmw_once.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $7
.segment "SEG1"
.org $002000
entry_002000:
    lsr a:$2004                 ; 00/2000: 4E 04 20
    nop                         ; 00/2003: EA
    ldx #$10                    ; 00/2004: A2 10 ; changed by a store before it runs: runs as eor (51 10) (self-modifying code)
    rts                         ; 00/2006: 60
