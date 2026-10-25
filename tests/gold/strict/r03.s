; dumpapple 0.9.0 listing of tests/progs/r03.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o r03.o r03.s
;          ld65 -C r03.cfg -o r03.bin r03.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $E
.segment "SEG1"
.org $002000
entry_002000:
    lda #$05                    ; 00/2000: A9 05
    sta a:$2007                 ; 00/2002: 8D 07 20
    clc                         ; 00/2005: 18
    bcc $00200A                 ; 00/2006: 90 02 ; changed by a store before it runs: runs as bcc (90 05) (self-modifying code)
    .byte $A9,$01,$8D,$00,$C0   ; 00/2008
L00200D:
    rts                         ; 00/200D: 60
