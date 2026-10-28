; dumpapple 0.10.0 listing of tests/progs/g2n_off.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2n_off.o g2n_off.s
;          ld65 -C g2n_off.cfg -o g2n_off.bin g2n_off.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)
; note: inline-string helper $002003 called at $002040: string runs past the end of the image (read at $2045); bytes after the call left undecoded

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $45
.segment "SEG1"
.org $002000
entry_002000:
    jmp .loword(L002040)        ; 00/2000: 4C 40 20
sub_002003:
    pla                         ; 00/2003: 68
    sta z:$F0                   ; 00/2004: 85 F0
    pla                         ; 00/2006: 68
    sta z:$F1                   ; 00/2007: 85 F1
    ldy #$00                    ; 00/2009: A0 00
L00200B:
    iny                         ; 00/200B: C8
    lda ($F0),y                 ; 00/200C: B1 F0
    beq L002016                 ; 00/200E: F0 06
    jsr $FDED                   ; 00/2010: 20 ED FD
    jmp .loword(L00200B)        ; 00/2013: 4C 0B 20
L002016:
    tya                         ; 00/2016: 98
    clc                         ; 00/2017: 18
    adc z:$F0                   ; 00/2018: 65 F0
    sta z:$F0                   ; 00/201A: 85 F0
    lda z:$F1                   ; 00/201C: A5 F1
    adc #$00                    ; 00/201E: 69 00
    pha                         ; 00/2020: 48
    lda z:$F0                   ; 00/2021: A5 F0
    pha                         ; 00/2023: 48
    rts                         ; 00/2024: 60
    .res 27                     ; 00/2025
L002040:
    jsr .loword(sub_002003)     ; 00/2040: 20 03 20 ; unknown: inline string after jsr $002003 not proven (string runs past the end of the image (read at $2045))
    .byte $41,$42               ; 00/2043
