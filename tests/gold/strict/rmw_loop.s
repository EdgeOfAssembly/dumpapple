; dumpapple 0.9.0 listing of tests/progs/rmw_loop.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o rmw_loop.o rmw_loop.s
;          ld65 -C rmw_loop.cfg -o rmw_loop.bin rmw_loop.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $C
.segment "SEG1"
.org $002000
entry_002000:
    ldx #$03                    ; 00/2000: A2 03
L002002:
    lsr a:$2009                 ; 00/2002: 4E 09 20
    dex                         ; 00/2005: CA
    bne L002002                 ; 00/2006: D0 FA
    nop                         ; 00/2008: EA
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $A2,$10,$60           ; 00/2009
