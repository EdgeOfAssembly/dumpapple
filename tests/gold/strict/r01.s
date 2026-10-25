; dumpapple 0.9.0 listing of tests/progs/r01.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o r01.o r01.s
;          ld65 -C r01.cfg -o r01.bin r01.o

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $16
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    clc                         ; 00/2000: 18
    xce                         ; 00/2001: FB
    rep #$30                    ; 00/2002: C2 30
    .a16
    .i16
    sep #$10                    ; 00/2004: E2 10
    .i8
    ldx z:$10                   ; 00/2006: A6 10
    sta a:$1D00,x               ; 00/2008: 9D 00 1D
    rep #$20                    ; 00/200B: C2 20
    lda #$6060                  ; 00/200D: A9 60 60
    lda #$8D00                  ; 00/2010: A9 00 8D
    .byte $00,$C0               ; 00/2013: 00 C0 brk $C0
    .byte $60                   ; 00/2015
