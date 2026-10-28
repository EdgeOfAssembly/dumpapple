; dumpapple 0.10.0 listing of tests/progs/rmw_twocall.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o rmw_twocall.o rmw_twocall.s
;          ld65 -C rmw_twocall.cfg -o rmw_twocall.bin rmw_twocall.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $E
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002007)     ; 00/2000: 20 07 20
    jsr .loword(sub_002007)     ; 00/2003: 20 07 20
    rts                         ; 00/2006: 60
sub_002007:
    lsr a:$200B                 ; 00/2007: 4E 0B 20
    nop                         ; 00/200A: EA
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $A2,$10,$60           ; 00/200B
