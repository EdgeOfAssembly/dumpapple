; dumpapple 0.9.0 listing of tests/progs/r88.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o r88.o r88.s
;          ld65 -C r88.cfg -o r88.bin r88.o

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $9
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    clc                         ; 00/2000: 18
    xce                         ; 00/2001: FB
    sep #$30                    ; 00/2002: E2 30
    lda #$12                    ; 00/2004: A9 12
    ldx #$34                    ; 00/2006: A2 34
    rts                         ; 00/2008: 60
