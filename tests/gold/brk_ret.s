; dumpapple 0.9.0 listing of tests/progs/brk_ret.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o brk_ret.o brk_ret.s
;          ld65 -C brk_ret.cfg -o brk_ret.bin brk_ret.o

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $5
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    .byte $00,$01               ; 00/2000: 00 01 brk $01
    lda #$01                    ; 00/2002: A9 01
    rts                         ; 00/2004: 60
