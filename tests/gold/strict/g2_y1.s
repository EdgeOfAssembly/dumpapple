; dumpapple 0.10.0 listing of tests/progs/g2_y1.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2_y1.o g2_y1.s
;          ld65 -C g2_y1.cfg -o g2_y1.bin g2_y1.o
; assumes CSW hook preserves X/Y (an inline-string helper calls COUT $FDED; nothing in the image stores to CSW $36/$37)
; assumes decimal mode clear at entry (an inline-string helper adds/subtracts; no cld/sed on the way to its call)
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $61
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002040)     ; 00/2000: 20 40 20 ; returns past 6 inline bytes (zero-terminated)
; zero-terminated inline string after call to $002040 (routine reads past its return address)
    .byte $48,$45,$4C,$4C,$4F,$00 ; 00/2003 "HELLO."
    jsr .loword(sub_002040)     ; 00/2009: 20 40 20 ; returns past 1 inline byte (zero-terminated)
; zero-terminated inline string after call to $002040 (routine reads past its return address)
    .byte $00                   ; 00/200C "."
    rts                         ; 00/200D: 60
    .res 50                     ; 00/200E
sub_002040:
    pla                         ; 00/2040: 68
    sta z:$F0                   ; 00/2041: 85 F0
    pla                         ; 00/2043: 68
    sta z:$F1                   ; 00/2044: 85 F1
    ldy #$01                    ; 00/2046: A0 01
L002048:
    lda ($F0),y                 ; 00/2048: B1 F0
    beq L002052                 ; 00/204A: F0 06
    jsr $FDED                   ; 00/204C: 20 ED FD
    iny                         ; 00/204F: C8
    bne L002048                 ; 00/2050: D0 F6
L002052:
    tya                         ; 00/2052: 98
    clc                         ; 00/2053: 18
    adc z:$F0                   ; 00/2054: 65 F0
    sta z:$F0                   ; 00/2056: 85 F0
    lda z:$F1                   ; 00/2058: A5 F1
    adc #$00                    ; 00/205A: 69 00
    pha                         ; 00/205C: 48
    lda z:$F0                   ; 00/205D: A5 F0
    pha                         ; 00/205F: 48
    rts                         ; 00/2060: 60
