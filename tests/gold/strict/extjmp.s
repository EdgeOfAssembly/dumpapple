; dumpapple 0.9.0 listing of tests/progs/extjmp.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o extjmp.o extjmp.s
;          ld65 -C extjmp.cfg -o extjmp.bin extjmp.o
; note: suggested hint: inline $003000 z (4 call sites look like strings)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $2F
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002010)     ; 00/2000: 20 10 20
    jsr .loword(sub_002018)     ; 00/2003: 20 18 20
    jsr .loword(sub_002028)     ; 00/2006: 20 28 20
    jsr .loword(sub_002020)     ; 00/2009: 20 20 20
    jmp .loword(L002023)        ; 00/200C: 4C 23 20
    .byte $00                   ; 00/200F
sub_002010:
    jsr $3000                   ; 00/2010: 20 00 30 ; unknown: possible inline data after jsr $003000; see suggested hint
    .byte $41,$42,$00,$60,$00   ; 00/2013
sub_002018:
    jsr $3000                   ; 00/2018: 20 00 30 ; unknown: possible inline data after jsr $003000; see suggested hint
    .byte $43,$44,$00,$60,$00   ; 00/201B
sub_002020:
    jsr $3000                   ; 00/2020: 20 00 30 ; unknown: possible inline data after jsr $003000; see suggested hint
L002023:
    eor z:$46                   ; 00/2023: 45 46
    .byte $00,$60               ; 00/2025: 00 60 brk $60
    .byte $00                   ; 00/2027
sub_002028:
    jsr $3000                   ; 00/2028: 20 00 30 ; unknown: possible inline data after jsr $003000; see suggested hint
    .byte $47,$48,$00,$60       ; 00/202B
