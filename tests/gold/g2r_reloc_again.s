; dumpapple 0.9.0 listing of tests/progs/g2r_reloc_again.bin
; cpu 6502, platform prodos8
; rebuild: ca65 --cpu 6502 -t none -o g2r_reloc_again.o g2r_reloc_again.s
;          ld65 -C g2r_reloc_again.cfg -o g2r_reloc_again.bin g2r_reloc_again.o
; assumes stores with unknown targets do not modify code
; note: inline-string helper $001080 called at $001023: helper code at $1080 may be changed by the store at $1014 (self-modifying code); bytes after the call left undecoded
; note: unknown-target stores still count for return frames, CSW and inline helpers: COUT $FDED is not trusted (store through an unresolved pointer (02) at $1014)

.setcpu "6502"

; ------------------------------------------------------------
; base $001000 length $A2
.segment "SEG1"
.org $001000
entry_001000:
    lda #$00                    ; 00/1000: A9 00
    sta z:$00                   ; 00/1002: 85 00
    sta z:$02                   ; 00/1004: 85 02
    lda #$20                    ; 00/1006: A9 20
    sta z:$01                   ; 00/1008: 85 01
    lda #$10                    ; 00/100A: A9 10
    sta z:$03                   ; 00/100C: 85 03
    ldx #$02                    ; 00/100E: A2 02
    ldy #$00                    ; 00/1010: A0 00
L001012:
    lda ($00),y                 ; 00/1012: B1 00
    sta ($02),y                 ; 00/1014: 91 02 ; unknown-target store (assumed not to modify code)
    iny                         ; 00/1016: C8
    bne L001012                 ; 00/1017: D0 F9
    inc z:$01                   ; 00/1019: E6 01
    inc z:$03                   ; 00/101B: E6 03
    dex                         ; 00/101D: CA
    bne L001012                 ; 00/101E: D0 F2
    jmp .loword(L001023)        ; 00/1020: 4C 23 10
L001023:
    jsr .loword(sub_001080)     ; 00/1023: 20 80 10 ; unknown: inline string after jsr $001080 not proven (helper code at $1080 may be changed by the store at $1014 (self-modifying code))
    .byte "HELLO"               ; 00/1026
    .byte $00,$4C,$00,$10       ; 00/102B
    .res 81                     ; 00/102F
sub_001080:
    pla                         ; 00/1080: 68
    sta z:$F0                   ; 00/1081: 85 F0
    pla                         ; 00/1083: 68
    sta z:$F1                   ; 00/1084: 85 F1
    ldy #$00                    ; 00/1086: A0 00
L001088:
    iny                         ; 00/1088: C8
    lda ($F0),y                 ; 00/1089: B1 F0
    beq L001093                 ; 00/108B: F0 06
    jsr $FDED                   ; 00/108D: 20 ED FD
    jmp .loword(L001088)        ; 00/1090: 4C 88 10
L001093:
    tya                         ; 00/1093: 98
    clc                         ; 00/1094: 18
    adc z:$F0                   ; 00/1095: 65 F0
    sta z:$F0                   ; 00/1097: 85 F0
    lda z:$F1                   ; 00/1099: A5 F1
    adc #$00                    ; 00/109B: 69 00
    pha                         ; 00/109D: 48
    lda z:$F0                   ; 00/109E: A5 F0
    pha                         ; 00/10A0: 48
    rts                         ; 00/10A1: 60
