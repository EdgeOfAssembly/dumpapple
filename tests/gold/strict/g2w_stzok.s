; dumpapple 0.10.0 listing of tests/progs/g2w_stzok.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o g2w_stzok.o g2w_stzok.s
;          ld65 -C g2w_stzok.cfg -o g2w_stzok.bin g2w_stzok.o
; assumes CSW hook preserves X/Y (an inline-string helper calls COUT $FDED; nothing in the image stores to CSW $36/$37)
; assumes decimal mode clear at entry (an inline-string helper adds/subtracts; no cld/sed on the way to its call)
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $184
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002180)     ; 00/2000: 20 80 21
    jsr .loword(sub_002040)     ; 00/2003: 20 40 20 ; returns past 6 inline bytes (zero-terminated)
; zero-terminated inline string after call to $002040 (routine reads past its return address)
    .byte $48,$45,$4C,$4C,$4F,$00 ; 00/2006 "HELLO."
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
    .res 286                    ; 00/2062
sub_002180:
    stz a:$0120                 ; 00/2180: 9C 20 01
    rts                         ; 00/2183: 60
