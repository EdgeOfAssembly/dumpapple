; dumpapple 0.9.0 listing of tests/progs/g1_wclc.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g1_wclc.o g1_wclc.s
;          ld65 -C g1_wclc.cfg -o g1_wclc.bin g1_wclc.o
; note: length-prefixed helper $00200D: a call site does not fit the length rule; inline length not applied

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $33
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_00200D)     ; 00/2000: 20 0D 20
; code flow reached here but decoding stopped: undefined 6502 opcode or truncated
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
L002019:
    cpy z:$F2                   ; 00/2019: C4 F2
    bcs L002023                 ; 00/201B: B0 06
    iny                         ; 00/201D: C8
    lda ($F0),y                 ; 00/201E: B1 F0
    jmp .loword(L002019)        ; 00/2020: 4C 19 20
L002023:
    iny                         ; 00/2023: C8
    clc                         ; 00/2024: 18
    tya                         ; 00/2025: 98
    adc z:$F0                   ; 00/2026: 65 F0
    sta z:$F0                   ; 00/2028: 85 F0
    lda z:$F1                   ; 00/202A: A5 F1
    adc #$00                    ; 00/202C: 69 00
    pha                         ; 00/202E: 48
    lda z:$F0                   ; 00/202F: A5 F0
    pha                         ; 00/2031: 48
    rts                         ; 00/2032: 60
