; dumpapple 0.9.0 listing of tests/progs/rules_noret.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o rules_noret.o rules_noret.s
;          ld65 -C rules_noret.cfg -o rules_noret.bin rules_noret.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $9
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002008)     ; 00/2000: 20 08 20 ; does not return (assumed by noreturn hint)
    .byte $41,$42,$43,$00,$00   ; 00/2003
sub_002008:
    rts                         ; 00/2008: 60
