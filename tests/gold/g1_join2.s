; dumpapple 0.10.0 listing of tests/progs/g1_join2.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g1_join2.o g1_join2.s
;          ld65 -C g1_join2.cfg -o g1_join2.bin g1_join2.o
; note: length-prefixed helper $002012: carry unknown at the return-address add; inline length not applied

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $37
.segment "SEG1"
.org $002000
entry_002000:
    lda z:$F3                   ; 00/2000: A5 F3
    bne L002028                 ; 00/2002: D0 24
    jsr .loword(sub_002012)     ; 00/2004: 20 12 20 ; unknown: inline length after jsr $002012 depends on the carry
    .byte $03                   ; 00/2007
    .byte "ABC "                ; 00/2008
    .byte $12,$20,$00,$A9,$01,$60 ; 00/200C
sub_002012:
    pla                         ; 00/2012: 68
    sta z:$F0                   ; 00/2013: 85 F0
    pla                         ; 00/2015: 68
    sta z:$F1                   ; 00/2016: 85 F1
    ldy #$01                    ; 00/2018: A0 01
    lda ($F0),y                 ; 00/201A: B1 F0
    sta z:$F2                   ; 00/201C: 85 F2
L00201E:
    cpy z:$F2                   ; 00/201E: C4 F2
    bcs L002028                 ; 00/2020: B0 06
    iny                         ; 00/2022: C8
    lda ($F0),y                 ; 00/2023: B1 F0
    jmp .loword(L00201E)        ; 00/2025: 4C 1E 20
L002028:
    iny                         ; 00/2028: C8
    tya                         ; 00/2029: 98
    adc z:$F0                   ; 00/202A: 65 F0
    sta z:$F0                   ; 00/202C: 85 F0
    lda z:$F1                   ; 00/202E: A5 F1
    adc #$00                    ; 00/2030: 69 00
    pha                         ; 00/2032: 48
    lda z:$F0                   ; 00/2033: A5 F0
    pha                         ; 00/2035: 48
    rts                         ; 00/2036: 60
