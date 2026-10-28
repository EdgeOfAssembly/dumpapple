; dumpapple 0.10.0 listing of tests/progs/ba_f16.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o ba_f16.o ba_f16.s
;          ld65 -C ba_f16.cfg -o ba_f16.bin ba_f16.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $11
.segment "SEG1"
.org $002000
entry_002000:
    lda #$C9                    ; 00/2000: A9 C9
    sta a:$2006                 ; 00/2002: 8D 06 20
    clc                         ; 00/2005: 18
    sta z:$10                   ; 00/2006: 85 10 ; changed by a store before it runs: runs as cmp (C9 10) (self-modifying code)
    bcc L002010                 ; 00/2008: 90 06
    lda #$C1                    ; 00/200A: A9 C1
    jsr $FDED                   ; 00/200C: 20 ED FD
    rts                         ; 00/200F: 60
L002010:
    rts                         ; 00/2010: 60
