; dumpapple 0.10.0 listing of tests/progs/rules_p8quit.bin
; cpu 6502, platform prodos8
; rebuild: ca65 --cpu 6502 -t none -o rules_p8quit.o rules_p8quit.s
;          ld65 -C rules_p8quit.cfg -o rules_p8quit.bin rules_p8quit.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $D
.segment "SEG1"
.org $002000
entry_002000:
    jsr $BF00                   ; 00/2000: 20 00 BF ; returns past 3 inline bytes; QUIT returns only on error (C=1)
; ProDOS 8 MLI command + parameter list pointer after call to $00BF00
    .byte $65                   ; 00/2003 MLI command
    .word $0300                 ; 00/2004 parameter list
    rol a:$5953                 ; 00/2006: 2E 53 59
; code flow reached here but decoding stopped: undefined 6502 opcode or truncated
    .byte "STEM"                ; 00/2009
