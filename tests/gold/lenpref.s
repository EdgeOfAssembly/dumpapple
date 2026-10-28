; dumpapple 0.10.0 listing of tests/progs/lenpref.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o lenpref.o lenpref.s
;          ld65 -C lenpref.cfg -o lenpref.bin lenpref.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $33
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_00200D)     ; 00/2000: 20 0D 20 ; returns past 4 inline bytes (length-prefixed)
; length-prefixed inline string after call to $00200D (routine reads past its return address)
    .byte $03,$41,$42,$43       ; 00/2003 ".ABC"
    jsr .loword(sub_00200D)     ; 00/2007: 20 0D 20 ; returns past 2 inline bytes (length-prefixed)
; length-prefixed inline string after call to $00200D (routine reads past its return address)
    .byte $01,$44               ; 00/200A ".D"
    rts                         ; 00/200C: 60
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
    tya                         ; 00/2024: 98
    clc                         ; 00/2025: 18
    adc z:$F0                   ; 00/2026: 65 F0
    sta z:$F0                   ; 00/2028: 85 F0
    lda z:$F1                   ; 00/202A: A5 F1
    adc #$00                    ; 00/202C: 69 00
    pha                         ; 00/202E: 48
    lda z:$F0                   ; 00/202F: A5 F0
    pha                         ; 00/2031: 48
    rts                         ; 00/2032: 60
