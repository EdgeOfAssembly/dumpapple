; dumpapple 0.10.0 listing of tests/progs/g2_incptr.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2_incptr.o g2_incptr.s
;          ld65 -C g2_incptr.cfg -o g2_incptr.bin g2_incptr.o
; assumes CSW hook preserves X/Y (an inline-string helper calls COUT $FDED; nothing in the image stores to CSW $36/$37)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $5E
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002040)     ; 00/2000: 20 40 20 ; returns past 4 inline bytes (zero-terminated)
; zero-terminated inline string after call to $002040 (routine reads past its return address)
    .byte $48,$49,$8D,$00       ; 00/2003 "HI.."
    jsr .loword(sub_002040)     ; 00/2007: 20 40 20 ; returns past 1 inline byte (zero-terminated)
; zero-terminated inline string after call to $002040 (routine reads past its return address)
    .byte $00                   ; 00/200A "."
    rts                         ; 00/200B: 60
    .res 52                     ; 00/200C
sub_002040:
    pla                         ; 00/2040: 68
    sta z:$F0                   ; 00/2041: 85 F0
    pla                         ; 00/2043: 68
    sta z:$F1                   ; 00/2044: 85 F1
    bne L00204B                 ; 00/2046: D0 03
L002048:
    jsr $FDED                   ; 00/2048: 20 ED FD
L00204B:
    inc z:$F0                   ; 00/204B: E6 F0
    bne L002051                 ; 00/204D: D0 02
    inc z:$F1                   ; 00/204F: E6 F1
L002051:
    ldy #$00                    ; 00/2051: A0 00
    lda ($F0),y                 ; 00/2053: B1 F0
    bne L002048                 ; 00/2055: D0 F1
    lda z:$F1                   ; 00/2057: A5 F1
    pha                         ; 00/2059: 48
    lda z:$F0                   ; 00/205A: A5 F0
    pha                         ; 00/205C: 48
    rts                         ; 00/205D: 60
