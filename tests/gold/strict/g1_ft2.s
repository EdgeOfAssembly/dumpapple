; dumpapple 0.10.0 listing of tests/progs/g1_ft2.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g1_ft2.o g1_ft2.s
;          ld65 -C g1_ft2.cfg -o g1_ft2.bin g1_ft2.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)
; note: length-prefixed helper $00200E: carry unknown at the return-address add; inline length not applied

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $32
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_00200E)     ; 00/2000: 20 0E 20 ; unknown: inline length after jsr $00200E depends on the carry
    .byte $03                   ; 00/2003
    .byte "ABC "                ; 00/2004
    .byte $0E,$20,$00,$A9,$01,$60 ; 00/2008
sub_00200E:
    pla                         ; 00/200E: 68
    sta z:$F0                   ; 00/200F: 85 F0
    pla                         ; 00/2011: 68
    sta z:$F1                   ; 00/2012: 85 F1
    ldy #$01                    ; 00/2014: A0 01
    lda ($F0),y                 ; 00/2016: B1 F0
    sta z:$F2                   ; 00/2018: 85 F2
L00201A:
    cpy z:$F2                   ; 00/201A: C4 F2
    bcs L002023                 ; 00/201C: B0 05
    iny                         ; 00/201E: C8
    lda ($F0),y                 ; 00/201F: B1 F0
    bpl L00201A                 ; 00/2021: 10 F7
L002023:
    iny                         ; 00/2023: C8
    tya                         ; 00/2024: 98
    adc z:$F0                   ; 00/2025: 65 F0
    sta z:$F0                   ; 00/2027: 85 F0
    lda z:$F1                   ; 00/2029: A5 F1
    adc #$00                    ; 00/202B: 69 00
    pha                         ; 00/202D: 48
    lda z:$F0                   ; 00/202E: A5 F0
    pha                         ; 00/2030: 48
    rts                         ; 00/2031: 60
