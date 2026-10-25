; dumpapple 0.9.0 listing of tests/progs/g3_bpl.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g3_bpl.o g3_bpl.s
;          ld65 -C g3_bpl.cfg -o g3_bpl.bin g3_bpl.o
; assumes CSW hook preserves X/Y (an inline-string helper calls COUT $FDED; nothing in the image stores to CSW $36/$37)
; assumes decimal mode clear at entry (an inline-string helper adds/subtracts; no cld/sed on the way to its call)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $65
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002040)     ; 00/2000: 20 40 20 ; returns past 4 inline bytes (bit-7-clear-terminated)
; bit-7-clear-terminated inline string after call to $002040 (routine reads past its return address)
    .byte $C8,$C5,$CC,$4C       ; 00/2003 "HELL"
    jsr .loword(sub_002040)     ; 00/2007: 20 40 20 ; returns past 2 inline bytes (bit-7-clear-terminated)
; bit-7-clear-terminated inline string after call to $002040 (routine reads past its return address)
    .byte $CF,$4B               ; 00/200A "OK"
    rts                         ; 00/200C: 60
    .res 51                     ; 00/200D
sub_002040:
    pla                         ; 00/2040: 68
    sta z:$F0                   ; 00/2041: 85 F0
    pla                         ; 00/2043: 68
    sta z:$F1                   ; 00/2044: 85 F1
    ldy #$00                    ; 00/2046: A0 00
L002048:
    iny                         ; 00/2048: C8
    lda ($F0),y                 ; 00/2049: B1 F0
    pha                         ; 00/204B: 48
    ora #$80                    ; 00/204C: 09 80
    jsr $FDED                   ; 00/204E: 20 ED FD
    pla                         ; 00/2051: 68
    bpl L002056                 ; 00/2052: 10 02
    bmi L002048                 ; 00/2054: 30 F2
L002056:
    tya                         ; 00/2056: 98
    clc                         ; 00/2057: 18
    adc z:$F0                   ; 00/2058: 65 F0
    sta z:$F0                   ; 00/205A: 85 F0
    lda z:$F1                   ; 00/205C: A5 F1
    adc #$00                    ; 00/205E: 69 00
    pha                         ; 00/2060: 48
    lda z:$F0                   ; 00/2061: A5 F0
    pha                         ; 00/2063: 48
    rts                         ; 00/2064: 60
