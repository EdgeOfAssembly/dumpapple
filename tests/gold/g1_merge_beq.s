; dumpapple 0.9.0 listing of tests/progs/g1_merge_beq.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g1_merge_beq.o g1_merge_beq.s
;          ld65 -C g1_merge_beq.cfg -o g1_merge_beq.bin g1_merge_beq.o
; note: length-prefixed helper $00200E: carry unknown at the return-address add; inline length not applied

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $35
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
    beq L002027                 ; 00/201A: F0 0B
L00201C:
    cpy z:$F2                   ; 00/201C: C4 F2
    bcs L002026                 ; 00/201E: B0 06
    iny                         ; 00/2020: C8
    lda ($F0),y                 ; 00/2021: B1 F0
    jmp .loword(L00201C)        ; 00/2023: 4C 1C 20
L002026:
    iny                         ; 00/2026: C8
L002027:
    tya                         ; 00/2027: 98
    adc z:$F0                   ; 00/2028: 65 F0
    sta z:$F0                   ; 00/202A: 85 F0
    lda z:$F1                   ; 00/202C: A5 F1
    adc #$00                    ; 00/202E: 69 00
    pha                         ; 00/2030: 48
    lda z:$F0                   ; 00/2031: A5 F0
    pha                         ; 00/2033: 48
    rts                         ; 00/2034: 60
