; dumpapple 0.9.0 listing of tests/progs/g2b_n08.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2b_n08.o g2b_n08.s
;          ld65 -C g2b_n08.cfg -o g2b_n08.bin g2b_n08.o
; assumes CSW hook preserves X/Y (an inline-string helper calls COUT $FDED; nothing in the image stores to CSW $36/$37)

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
    ldy #$00                    ; 00/2046: A0 00
L002048:
    iny                         ; 00/2048: C8
    lda ($F0),y                 ; 00/2049: B1 F0
    beq L002053                 ; 00/204B: F0 06
    jsr $FDED                   ; 00/204D: 20 ED FD
    jmp .loword(L002048)        ; 00/2050: 4C 48 20
L002053:
    sed                         ; 00/2053: F8
    cld                         ; 00/2054: D8
    tya                         ; 00/2055: 98
    clc                         ; 00/2056: 18
    adc z:$F0                   ; 00/2057: 65 F0
    sta z:$F0                   ; 00/2059: 85 F0
    lda z:$F1                   ; 00/205B: A5 F1
    adc #$00                    ; 00/205D: 69 00
    pha                         ; 00/205F: 48
    lda z:$F0                   ; 00/2060: A5 F0
    pha                         ; 00/2062: 48
    rts                         ; 00/2063: 60
    .res 156                    ; 00/2064
L002100:
    jsr .loword(sub_002040)     ; 00/2100: 20 40 20 ; returns past 12 inline bytes (zero-terminated)
; zero-terminated inline string after call to $002040 (routine reads past its return address)
    .byte $48,$45,$4C,$4C,$4F,$20,$57,$4F,$52,$4C,$44,$00 ; 00/2103 "HELLO WORLD."
    rts                         ; 00/210F: 60
    .res 240                    ; 00/2110
    .byte $C8,$60               ; 00/2200
