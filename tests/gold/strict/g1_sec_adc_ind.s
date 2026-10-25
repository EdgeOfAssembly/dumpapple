; dumpapple 0.9.0 listing of tests/progs/g1_sec_adc_ind.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g1_sec_adc_ind.o g1_sec_adc_ind.s
;          ld65 -C g1_sec_adc_ind.cfg -o g1_sec_adc_ind.bin g1_sec_adc_ind.o
; note: length-prefixed helper $002010: carry unknown at the return-address add; inline length not applied

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $39
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002010)     ; 00/2000: 20 10 20 ; unknown: inline length after jsr $002010 depends on the carry
    .byte $03                   ; 00/2003
    .byte "ABC "                ; 00/2004
    .byte $10                   ; 00/2008
    .byte "  6 "                ; 00/2009
    .byte $A9,$01,$60           ; 00/200D
sub_002010:
    pla                         ; 00/2010: 68
    sta z:$F0                   ; 00/2011: 85 F0
    pla                         ; 00/2013: 68
    sta z:$F1                   ; 00/2014: 85 F1
    ldy #$01                    ; 00/2016: A0 01
    lda ($F0),y                 ; 00/2018: B1 F0
    sta z:$F2                   ; 00/201A: 85 F2
L00201C:
    cpy z:$F2                   ; 00/201C: C4 F2
    bcs L002026                 ; 00/201E: B0 06
    iny                         ; 00/2020: C8
    lda ($F0),y                 ; 00/2021: B1 F0
    jmp .loword(L00201C)        ; 00/2023: 4C 1C 20
L002026:
    iny                         ; 00/2026: C8
    tya                         ; 00/2027: 98
    sec                         ; 00/2028: 38
    adc z:$F0                   ; 00/2029: 65 F0
    sta z:$F0                   ; 00/202B: 85 F0
    lda z:$F1                   ; 00/202D: A5 F1
    adc #$00                    ; 00/202F: 69 00
    pha                         ; 00/2031: 48
    lda z:$F0                   ; 00/2032: A5 F0
    pha                         ; 00/2034: 48
    rts                         ; 00/2035: 60
    .byte $6C,$34,$12           ; 00/2036
