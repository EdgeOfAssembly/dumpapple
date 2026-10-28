; dumpapple 0.10.0 listing of tests/progs/rules_gsquit.bin
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o rules_gsquit.o rules_gsquit.s
;          ld65 -C rules_gsquit.cfg -o rules_gsquit.bin rules_gsquit.o

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $10
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    jsl f:$E100A8               ; 00/2000: 22 A8 00 E1 ; returns past 6 inline bytes; QUIT returns only on error (C=1)
; GS/OS inline call number + parameter block pointer after call to $E100A8
    .word $2029                 ; 00/2004 GS/OS call number
    .dword params_00200C        ; 00/2006 parameter block
    .byte $00,$00               ; 00/200A: 00 00 brk $00
params_00200C:
    .byte $01,$00,$00,$00       ; 00/200C
