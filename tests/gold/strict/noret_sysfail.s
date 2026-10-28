; dumpapple 0.10.0 listing of tests/progs/noret_sysfail.bin
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o noret_sysfail.o noret_sysfail.s
;          ld65 -C noret_sysfail.cfg -o noret_sysfail.bin noret_sysfail.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $B
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i16
    ldx #$1503                  ; 00/2000: A2 03 15
    jsl f:$E10000               ; 00/2003: 22 00 00 E1 ; does not return (_SysFailMgr)
    .byte $8D,$00,$C0,$60       ; 00/2007
