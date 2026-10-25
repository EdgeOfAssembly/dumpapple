; dumpapple 0.9.0 listing of tests/progs/g2r_reloc.bin
; cpu 6502, platform prodos8
; rebuild: ca65 --cpu 6502 -t none -o g2r_reloc.o g2r_reloc.s
;          ld65 -C g2r_reloc.cfg -o g2r_reloc.bin g2r_reloc.o
; assumes CSW hook preserves X/Y (an inline-string helper calls COUT $FDED; nothing in the image stores to CSW $36/$37)
; assumes decimal mode clear at entry (an inline-string helper adds/subtracts; no cld/sed on the way to its call)

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
    sta ($02),y                 ; 00/1014: 91 02
    iny                         ; 00/1016: C8
    bne L001012                 ; 00/1017: D0 F9
    inc z:$01                   ; 00/1019: E6 01
    inc z:$03                   ; 00/101B: E6 03
    dex                         ; 00/101D: CA
    bne L001012                 ; 00/101E: D0 F2
    jmp .loword(L001023)        ; 00/1020: 4C 23 10
L001023:
    jsr .loword(sub_001080)     ; 00/1023: 20 80 10 ; returns past 6 inline bytes (zero-terminated)
; zero-terminated inline string after call to $001080 (routine reads past its return address)
    .byte $48,$45,$4C,$4C,$4F,$00 ; 00/1026 "HELLO."
    jsr .loword(sub_001080)     ; 00/102C: 20 80 10 ; returns past 3 inline bytes (zero-terminated)
; zero-terminated inline string after call to $001080 (routine reads past its return address)
    .byte $41,$42,$00           ; 00/102F "AB."
    rts                         ; 00/1032: 60
    .res 77                     ; 00/1033
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
