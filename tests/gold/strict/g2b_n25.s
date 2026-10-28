; dumpapple 0.10.0 listing of tests/progs/g2b_n25.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2b_n25.o g2b_n25.s
;          ld65 -C g2b_n25.cfg -o g2b_n25.bin g2b_n25.o
; assumes CSW hook preserves X/Y (an inline-string helper calls COUT $FDED; nothing in the image stores to CSW $36/$37)
; assumes decimal mode clear at entry (an inline-string helper adds/subtracts; no cld/sed on the way to its call)
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

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
    tya                         ; 00/205B: 98
    clc                         ; 00/205C: 18
    adc z:$F0                   ; 00/205D: 65 F0
    sta z:$F0                   ; 00/205F: 85 F0
    lda z:$F1                   ; 00/2061: A5 F1
    adc #$00                    ; 00/2063: 69 00
    pha                         ; 00/2065: 48
    lda z:$F0                   ; 00/2066: A5 F0
    pha                         ; 00/2068: 48
    rts                         ; 00/2069: 60
    .res 150                    ; 00/206A
L002100:
    jsr .loword(sub_002040)     ; 00/2100: 20 40 20 ; returns past 12 inline bytes (zero-terminated)
; zero-terminated inline string after call to $002040 (routine reads past its return address)
    .byte $48,$45,$4C,$4C,$4F,$20,$57,$4F,$52,$4C,$44,$00 ; 00/2103 "HELLO WORLD."
    rts                         ; 00/210F: 60
    .res 240                    ; 00/2110
    .byte $C8,$60               ; 00/2200
