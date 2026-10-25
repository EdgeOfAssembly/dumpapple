; dumpapple 0.9.0 listing of tests/progs/ba_f12.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o ba_f12.o ba_f12.s
;          ld65 -C ba_f12.cfg -o ba_f12.bin ba_f12.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $10
.segment "SEG1"
.org $002000
entry_002000:
    lda #$38                    ; 00/2000: A9 38
    sta a:$2006                 ; 00/2002: 8D 06 20
    clc                         ; 00/2005: 18
    nop                         ; 00/2006: EA ; changed by a store before it runs: runs as sec (38) (self-modifying code)
    bcc $00200F                 ; 00/2007: 90 06
    lda #$C1                    ; 00/2009: A9 C1
    jsr $FDED                   ; 00/200B: 20 ED FD
    rts                         ; 00/200E: 60
    .byte $60                   ; 00/200F
