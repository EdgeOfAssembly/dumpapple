; dumpapple 0.9.0 listing of tests/progs/r04.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o r04.o r04.s
;          ld65 -C r04.cfg -o r04.bin r04.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $9
.segment "SEG1"
.org $002000
entry_002000:
    lda #$C1                    ; 00/2000: A9 C1
    sta a:$2007                 ; 00/2002: 8D 07 20
    sta a:$C000                 ; 00/2005: 8D 00 C0 ; changed by a store before it runs: runs as sta (8D 00 C1) (self-modifying code)
    rts                         ; 00/2008: 60
