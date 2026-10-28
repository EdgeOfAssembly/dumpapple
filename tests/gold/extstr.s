; dumpapple 0.10.0 listing of tests/progs/extstr.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o extstr.o extstr.s
;          ld65 -C extstr.cfg -o extstr.bin extstr.o
; note: suggested hint: inline $003000 z (3 call sites look like strings)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $27
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002010)     ; 00/2000: 20 10 20
    jsr .loword(sub_002018)     ; 00/2003: 20 18 20
    jsr .loword(sub_002020)     ; 00/2006: 20 20 20
    rts                         ; 00/2009: 60
    .byte $00,$00,$00,$00,$00,$00 ; 00/200A
sub_002010:
    jsr $3000                   ; 00/2010: 20 00 30 ; unknown: possible inline data after jsr $003000; see suggested hint
    .byte $41,$42,$00,$60,$00   ; 00/2013
sub_002018:
    jsr $3000                   ; 00/2018: 20 00 30 ; unknown: possible inline data after jsr $003000; see suggested hint
    .byte $43,$44,$00,$60,$00   ; 00/201B
sub_002020:
    jsr $3000                   ; 00/2020: 20 00 30 ; unknown: possible inline data after jsr $003000; see suggested hint
    .byte $45,$46,$00,$60       ; 00/2023
