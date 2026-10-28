; dumpapple 0.10.0 listing of tests/progs/extstr2.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o extstr2.o extstr2.s
;          ld65 -C extstr2.cfg -o extstr2.bin extstr2.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $1F
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002010)     ; 00/2000: 20 10 20
    jsr .loword(sub_002018)     ; 00/2003: 20 18 20
    rts                         ; 00/2006: 60
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00 ; 00/2007
sub_002010:
    jsr $3000                   ; 00/2010: 20 00 30
    eor ($42,x)                 ; 00/2013: 41 42
    .byte $00,$60               ; 00/2015: 00 60 brk $60
    .byte $00                   ; 00/2017
sub_002018:
    jsr $3000                   ; 00/2018: 20 00 30
; code flow reached here but decoding stopped: undefined 6502 opcode or truncated
    .byte $43,$44,$00,$60       ; 00/201B
