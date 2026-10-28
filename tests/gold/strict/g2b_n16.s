; dumpapple 0.10.0 listing of tests/progs/g2b_n16.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2b_n16.o g2b_n16.s
;          ld65 -C g2b_n16.cfg -o g2b_n16.bin g2b_n16.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)
; note: inline-string helper $002040 called at $002100: return to $2110 does not land right after the last byte read ($210E); bytes after the call left undecoded

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $202
.segment "SEG1"
.org $002000
entry_002000:
    jmp .loword(L002100)        ; 00/2000: 4C 00 21
    .res 61                     ; 00/2003
sub_002040:
    pla                         ; 00/2040: 68
    sta z:$F0                   ; 00/2041: 85 F0
    pla                         ; 00/2043: 68
    sta z:$F1                   ; 00/2044: 85 F1
    lda z:$F0                   ; 00/2046: A5 F0
    sta z:$F2                   ; 00/2048: 85 F2
    lda z:$F1                   ; 00/204A: A5 F1
    sta z:$F3                   ; 00/204C: 85 F3
    ldy #$00                    ; 00/204E: A0 00
L002050:
    iny                         ; 00/2050: C8
    lda ($F2),y                 ; 00/2051: B1 F2
    beq L00205B                 ; 00/2053: F0 06
    jsr $FDED                   ; 00/2055: 20 ED FD
    jmp .loword(L002050)        ; 00/2058: 4C 50 20
L00205B:
    iny                         ; 00/205B: C8
    tya                         ; 00/205C: 98
    clc                         ; 00/205D: 18
    adc z:$F0                   ; 00/205E: 65 F0
    sta z:$F0                   ; 00/2060: 85 F0
    lda z:$F1                   ; 00/2062: A5 F1
    adc #$00                    ; 00/2064: 69 00
    pha                         ; 00/2066: 48
    lda z:$F0                   ; 00/2067: A5 F0
    pha                         ; 00/2069: 48
    rts                         ; 00/206A: 60
    .res 149                    ; 00/206B
L002100:
    jsr .loword(sub_002040)     ; 00/2100: 20 40 20 ; unknown: inline string after jsr $002040 not proven (return to $2110 does not land right after the last byte read ($210E))
    .byte "HELLO WORLD"         ; 00/2103
    .byte $00,$60               ; 00/210E
    .res 240                    ; 00/2110
    .byte $C8,$60               ; 00/2200
