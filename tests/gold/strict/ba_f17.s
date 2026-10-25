; dumpapple 0.9.0 listing of tests/progs/ba_f17.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o ba_f17.o ba_f17.s
;          ld65 -C ba_f17.cfg -o ba_f17.bin ba_f17.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $11
.segment "SEG1"
.org $002000
entry_002000:
    lda #$69                    ; 00/2000: A9 69
    sta a:$2006                 ; 00/2002: 8D 06 20
    sec                         ; 00/2005: 38
    lda #$00                    ; 00/2006: A9 00 ; changed by a store before it runs: runs as adc (69 00) (self-modifying code)
    bcs L002010                 ; 00/2008: B0 06
    lda #$C1                    ; 00/200A: A9 C1
    jsr $FDED                   ; 00/200C: 20 ED FD
    rts                         ; 00/200F: 60
L002010:
    rts                         ; 00/2010: 60
