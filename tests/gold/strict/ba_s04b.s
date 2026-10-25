; dumpapple 0.9.0 listing of tests/progs/ba_s04b.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o ba_s04b.o ba_s04b.s
;          ld65 -C ba_s04b.cfg -o ba_s04b.bin ba_s04b.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $E
.segment "SEG1"
.org $002000
entry_002000:
    clc                         ; 00/2000: 18
    bcc L002006                 ; 00/2001: 90 03
L002003:
    lda #$01                    ; 00/2003: A9 01
    rts                         ; 00/2005: 60
L002006:
    lda #$03                    ; 00/2006: A9 03
    ldx #$20                    ; 00/2008: A2 20
    jsr $03F0                   ; 00/200A: 20 F0 03
    rts                         ; 00/200D: 60
