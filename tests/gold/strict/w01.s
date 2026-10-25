; dumpapple 0.9.0 listing of tests/progs/w01.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o w01.o w01.s
;          ld65 -C w01.cfg -o w01.bin w01.o

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $15
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    ldy a:$0300                 ; 00/2000: AC 00 03
    lda #$38                    ; 00/2003: A9 38
    sta a:$2008,y               ; 00/2005: 99 08 20
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $18,$FB,$C2,$20,$A9,$60,$60,$A9,$00,$8D,$00,$C0,$60 ; 00/2008
