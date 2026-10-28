; dumpapple 0.10.0 listing of tests/progs/r02.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o r02.o r02.s
;          ld65 -C r02.cfg -o r02.bin r02.o

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $18
.segment "SEG1"
.org $002000
entry_002000:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $18,$FB,$C2,$30,$A2,$00,$02,$9E,$00,$1F,$CA,$10,$FA,$E2,$20,$A9 ; 00/2000
    .byte $60,$60,$A9,$00,$8D,$00,$C0,$60 ; 00/2010
