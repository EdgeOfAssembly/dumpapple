; dumpapple 0.9.0 listing of tests/progs/ba_s04.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o ba_s04.o ba_s04.s
;          ld65 -C ba_s04.cfg -o ba_s04.bin ba_s04.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $11
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
    sta a:$03F0                 ; 00/2008: 8D F0 03
    lda #$20                    ; 00/200B: A9 20
    sta a:$03F1                 ; 00/200D: 8D F1 03
; code flow reached here but decoding stopped: undefined 6502 opcode or truncated
    .byte $00                   ; 00/2010
