; dumpapple 0.9.0 listing of tests/progs/g2b_n26.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2b_n26.o g2b_n26.s
;          ld65 -C g2b_n26.cfg -o g2b_n26.bin g2b_n26.o
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
    ldx #$00                    ; 00/2046: A2 00
L002048:
    inc z:$F0                   ; 00/2048: E6 F0
    bne L00204E                 ; 00/204A: D0 02
    inc z:$F1                   ; 00/204C: E6 F1
L00204E:
    lda ($F0,x)                 ; 00/204E: A1 F0
    beq L002058                 ; 00/2050: F0 06
    jsr $FDED                   ; 00/2052: 20 ED FD
    jmp .loword(L002048)        ; 00/2055: 4C 48 20
L002058:
    lda z:$F1                   ; 00/2058: A5 F1
    pha                         ; 00/205A: 48
    lda z:$F0                   ; 00/205B: A5 F0
    pha                         ; 00/205D: 48
    rts                         ; 00/205E: 60
    .res 161                    ; 00/205F
L002100:
    jsr .loword(sub_002040)     ; 00/2100: 20 40 20 ; returns past 12 inline bytes (zero-terminated)
; zero-terminated inline string after call to $002040 (routine reads past its return address)
    .byte $48,$45,$4C,$4C,$4F,$20,$57,$4F,$52,$4C,$44,$00 ; 00/2103 "HELLO WORLD."
    rts                         ; 00/210F: 60
    .res 240                    ; 00/2110
    .byte $C8,$60               ; 00/2200
