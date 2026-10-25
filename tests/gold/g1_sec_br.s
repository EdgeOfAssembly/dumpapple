; dumpapple 0.9.0 listing of tests/progs/g1_sec_br.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g1_sec_br.o g1_sec_br.s
;          ld65 -C g1_sec_br.cfg -o g1_sec_br.bin g1_sec_br.o
; note: length-prefixed helper $00200D: carry unknown at the return-address add; inline length not applied

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $37
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_00200D)     ; 00/2000: 20 0D 20 ; unknown: inline length after jsr $00200D depends on the carry
    .byte $03                   ; 00/2003
    .byte "ABC "                ; 00/2004
    .byte $0D,$20,$A9,$01,$60   ; 00/2008
sub_00200D:
    pla                         ; 00/200D: 68
    sta z:$F0                   ; 00/200E: 85 F0
    pla                         ; 00/2010: 68
    sta z:$F1                   ; 00/2011: 85 F1
    ldy #$01                    ; 00/2013: A0 01
    lda ($F0),y                 ; 00/2015: B1 F0
    sta z:$F2                   ; 00/2017: 85 F2
    lda z:$F2                   ; 00/2019: A5 F2
    beq L00202A                 ; 00/201B: F0 0D
L00201D:
    cpy z:$F2                   ; 00/201D: C4 F2
    bcs L002027                 ; 00/201F: B0 06
    iny                         ; 00/2021: C8
    lda ($F0),y                 ; 00/2022: B1 F0
    jmp .loword(L00201D)        ; 00/2024: 4C 1D 20
L002027:
    iny                         ; 00/2027: C8
    tya                         ; 00/2028: 98
    sec                         ; 00/2029: 38
L00202A:
    adc z:$F0                   ; 00/202A: 65 F0
    sta z:$F0                   ; 00/202C: 85 F0
    lda z:$F1                   ; 00/202E: A5 F1
    adc #$00                    ; 00/2030: 69 00
    pha                         ; 00/2032: 48
    lda z:$F0                   ; 00/2033: A5 F0
    pha                         ; 00/2035: 48
    rts                         ; 00/2036: 60
