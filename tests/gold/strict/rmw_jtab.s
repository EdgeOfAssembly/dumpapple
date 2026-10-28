; dumpapple 0.10.0 listing of tests/progs/rmw_jtab.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o rmw_jtab.o rmw_jtab.s
;          ld65 -C rmw_jtab.cfg -o rmw_jtab.bin rmw_jtab.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)
; note: auto table $002005: 1 entry used by $002002 (stopped: target outside image)

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $E
.segment "SEG1"
.org $002000
entry_002000:
    ldx #$00                    ; 00/2000: A2 00
    jmp ($2005,x)               ; 00/2002: 7C 05 20
D002005:
; jump table (auto): 1 word entry, used by $002002, heuristic stopped: target outside image
    .word .loword(L002007)      ; 00/2005 -> $002007
L002007:
    lsr a:$200B                 ; 00/2007: 4E 0B 20
    nop                         ; 00/200A: EA
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $A2,$10,$60           ; 00/200B
