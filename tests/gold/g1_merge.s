; dumpapple 0.10.0 listing of tests/progs/g1_merge.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g1_merge.o g1_merge.s
;          ld65 -C g1_merge.cfg -o g1_merge.bin g1_merge.o
; note: length-prefixed helper $00200E: carry unknown at the return-address add; inline length not applied

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $36
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
    clc                         ; 00/201A: 18
    bcc L002028                 ; 00/201B: 90 0B
    .byte $C4,$F2,$B0,$06,$C8,$B1,$F0,$4C,$1D,$20,$C8 ; 00/201D
L002028:
    tya                         ; 00/2028: 98
    adc z:$F0                   ; 00/2029: 65 F0
    sta z:$F0                   ; 00/202B: 85 F0
    lda z:$F1                   ; 00/202D: A5 F1
    adc #$00                    ; 00/202F: 69 00
    pha                         ; 00/2031: 48
    lda z:$F0                   ; 00/2032: A5 F0
    pha                         ; 00/2034: 48
    rts                         ; 00/2035: 60
