; dumpapple 0.9.0 listing of tests/progs/g1_clc.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g1_clc.o g1_clc.s
;          ld65 -C g1_clc.cfg -o g1_clc.bin g1_clc.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $37
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002011)     ; 00/2000: 20 11 20 ; returns past 4 inline bytes (length-prefixed)
; length-prefixed inline string after call to $002011 (routine reads past its return address)
    .byte $03,$41,$42,$43       ; 00/2003 ".ABC"
    jsr .loword(sub_002011)     ; 00/2007: 20 11 20 ; returns past 4 inline bytes (length-prefixed)
; length-prefixed inline string after call to $002011 (routine reads past its return address)
    .byte $03,$44,$45,$46       ; 00/200A ".DEF"
    lda #$01                    ; 00/200E: A9 01
    rts                         ; 00/2010: 60
sub_002011:
    pla                         ; 00/2011: 68
    sta z:$F0                   ; 00/2012: 85 F0
    pla                         ; 00/2014: 68
    sta z:$F1                   ; 00/2015: 85 F1
    ldy #$01                    ; 00/2017: A0 01
    lda ($F0),y                 ; 00/2019: B1 F0
    sta z:$F2                   ; 00/201B: 85 F2
L00201D:
    cpy z:$F2                   ; 00/201D: C4 F2
    bcs L002027                 ; 00/201F: B0 06
    iny                         ; 00/2021: C8
    lda ($F0),y                 ; 00/2022: B1 F0
    jmp .loword(L00201D)        ; 00/2024: 4C 1D 20
L002027:
    iny                         ; 00/2027: C8
    clc                         ; 00/2028: 18
    tya                         ; 00/2029: 98
    adc z:$F0                   ; 00/202A: 65 F0
    sta z:$F0                   ; 00/202C: 85 F0
    lda z:$F1                   ; 00/202E: A5 F1
    adc #$00                    ; 00/2030: 69 00
    pha                         ; 00/2032: 48
    lda z:$F0                   ; 00/2033: A5 F0
    pha                         ; 00/2035: 48
    rts                         ; 00/2036: 60
