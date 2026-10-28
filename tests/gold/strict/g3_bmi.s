; dumpapple 0.10.0 listing of tests/progs/g3_bmi.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g3_bmi.o g3_bmi.s
;          ld65 -C g3_bmi.cfg -o g3_bmi.bin g3_bmi.o
; assumes CSW hook preserves X/Y (an inline-string helper calls COUT $FDED; nothing in the image stores to CSW $36/$37)
; assumes decimal mode clear at entry (an inline-string helper adds/subtracts; no cld/sed on the way to its call)
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $65
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002040)     ; 00/2000: 20 40 20 ; returns past 5 inline bytes (bit-7-set-terminated)
; bit-7-set-terminated inline string after call to $002040 (routine reads past its return address)
    .byte $48,$45,$4C,$4C,$CF   ; 00/2003 "HELLO"
    jsr .loword(sub_002040)     ; 00/2008: 20 40 20 ; returns past 2 inline bytes (bit-7-set-terminated)
; bit-7-set-terminated inline string after call to $002040 (routine reads past its return address)
    .byte $4F,$CB               ; 00/200B "OK"
    rts                         ; 00/200D: 60
    .res 50                     ; 00/200E
sub_002040:
    pla                         ; 00/2040: 68
    sta z:$F0                   ; 00/2041: 85 F0
    pla                         ; 00/2043: 68
    sta z:$F1                   ; 00/2044: 85 F1
    ldy #$00                    ; 00/2046: A0 00
L002048:
    iny                         ; 00/2048: C8
    lda ($F0),y                 ; 00/2049: B1 F0
    bmi L002053                 ; 00/204B: 30 06
    jsr $FDED                   ; 00/204D: 20 ED FD
    jmp .loword(L002048)        ; 00/2050: 4C 48 20
L002053:
    jsr $FDED                   ; 00/2053: 20 ED FD
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
