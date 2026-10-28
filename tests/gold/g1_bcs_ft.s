; dumpapple 0.10.0 listing of tests/progs/g1_bcs_ft.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g1_bcs_ft.o g1_bcs_ft.s
;          ld65 -C g1_bcs_ft.cfg -o g1_bcs_ft.bin g1_bcs_ft.o
; note: length-prefixed helper $00200E: carry unknown at the return-address add; inline length not applied

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $33
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
    bcs L00202D                 ; 00/201C: B0 0F
    iny                         ; 00/201E: C8
    tya                         ; 00/201F: 98
    adc z:$F0                   ; 00/2020: 65 F0
    sta z:$F0                   ; 00/2022: 85 F0
    lda z:$F1                   ; 00/2024: A5 F1
    adc #$00                    ; 00/2026: 69 00
    pha                         ; 00/2028: 48
    lda z:$F0                   ; 00/2029: A5 F0
    pha                         ; 00/202B: 48
    rts                         ; 00/202C: 60
L00202D:
    iny                         ; 00/202D: C8
    lda ($F0),y                 ; 00/202E: B1 F0
    jmp .loword(L00201A)        ; 00/2030: 4C 1A 20
