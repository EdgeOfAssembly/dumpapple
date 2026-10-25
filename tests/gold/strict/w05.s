; dumpapple 0.9.0 listing of tests/progs/w05.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o w05.o w05.s
;          ld65 -C w05.cfg -o w05.bin w05.o

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $13
.segment "SEG1"
.org $002000
entry_002000:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $68,$5B,$A9,$38,$85,$10,$18,$FB,$C2,$20,$A9,$60,$60,$A9,$00,$8D ; 00/2000
    .byte $00,$C0,$60           ; 00/2010
