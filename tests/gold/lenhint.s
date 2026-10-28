; dumpapple 0.10.0 listing of tests/progs/lenhint.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o lenhint.o lenhint.s
;          ld65 -C lenhint.cfg -o lenhint.bin lenhint.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $C
.segment "SEG1"
.org $002000
entry_002000:
    jsr $3000                   ; 00/2000: 20 00 30 ; returns past 3 inline bytes (length-prefixed)
; length-prefixed inline string after call to $003000 (hint)
    .byte $02,$41,$42           ; 00/2003 ".AB"
    jsr $3000                   ; 00/2006: 20 00 30 ; returns past 2 inline bytes (length-prefixed)
; length-prefixed inline string after call to $003000 (hint)
    .byte $01,$43               ; 00/2009 ".C"
    rts                         ; 00/200B: 60
