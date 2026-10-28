; dumpapple 0.10.0 listing of tests/progs/t01.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o t01.o t01.s
;          ld65 -C t01.cfg -o t01.bin t01.o
; assumes CSW hook preserves X/Y (an inline-string helper calls COUT $FDED; nothing in the image stores to CSW $36/$37)
; assumes decimal mode clear at entry (an inline-string helper adds/subtracts; no cld/sed on the way to its call)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $1A4
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
    tya                         ; 00/2053: 98
    clc                         ; 00/2054: 18
    adc z:$F0                   ; 00/2055: 65 F0
    sta z:$F0                   ; 00/2057: 85 F0
    lda z:$F1                   ; 00/2059: A5 F1
    adc #$00                    ; 00/205B: 69 00
    pha                         ; 00/205D: 48
    lda z:$F0                   ; 00/205E: A5 F0
    pha                         ; 00/2060: 48
    rts                         ; 00/2061: 60
    .res 158                    ; 00/2062
L002100:
    jsr .loword(sub_002180)     ; 00/2100: 20 80 21
    jsr .loword(sub_002040)     ; 00/2103: 20 40 20 ; returns past 12 inline bytes (zero-terminated)
; zero-terminated inline string after call to $002040 (routine reads past its return address)
    .byte $48,$45,$4C,$4C,$4F,$20,$57,$4F,$52,$4C,$44,$00 ; 00/2106 "HELLO WORLD."
    rts                         ; 00/2112: 60
    .res 109                    ; 00/2113
sub_002180:
    ldy #$03                    ; 00/2180: A0 03
L002182:
    ldx a:$21A0,y               ; 00/2182: BE A0 21
    lda #$BF                    ; 00/2185: A9 BF
    sta z:$30,x                 ; 00/2187: 95 30
    dey                         ; 00/2189: 88
    bpl L002182                 ; 00/218A: 10 F6
    rts                         ; 00/218C: 60
    .res 20                     ; 00/218D
    .byte $01,$02,$03           ; 00/21A1
