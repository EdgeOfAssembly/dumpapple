; dumpapple 0.10.0 listing of tests/progs/g2b_n27.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2b_n27.o g2b_n27.s
;          ld65 -C g2b_n27.cfg -o g2b_n27.bin g2b_n27.o
; assumes CSW hook preserves X/Y (an inline-string helper calls COUT $FDED; nothing in the image stores to CSW $36/$37)
; assumes decimal mode clear at entry (an inline-string helper adds/subtracts; no cld/sed on the way to its call)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $202
.segment "SEG1"
.org $002000
entry_002000:
    jmp .loword(L002100)        ; 00/2000: 4C 00 21
    .res 61                     ; 00/2003
sub_002040:
    tsx                         ; 00/2040: BA
    lda a:$0101,x               ; 00/2041: BD 01 01
    sta z:$F0                   ; 00/2044: 85 F0
    lda a:$0102,x               ; 00/2046: BD 02 01
    sta z:$F1                   ; 00/2049: 85 F1
    ldy #$00                    ; 00/204B: A0 00
L00204D:
    iny                         ; 00/204D: C8
    lda ($F0),y                 ; 00/204E: B1 F0
    beq L002058                 ; 00/2050: F0 06
    jsr $FDED                   ; 00/2052: 20 ED FD
    jmp .loword(L00204D)        ; 00/2055: 4C 4D 20
L002058:
    tya                         ; 00/2058: 98
    clc                         ; 00/2059: 18
    adc z:$F0                   ; 00/205A: 65 F0
    tsx                         ; 00/205C: BA
    sta a:$0101,x               ; 00/205D: 9D 01 01
    lda z:$F1                   ; 00/2060: A5 F1
    adc #$00                    ; 00/2062: 69 00
    sta a:$0102,x               ; 00/2064: 9D 02 01
    rts                         ; 00/2067: 60
    .res 152                    ; 00/2068
L002100:
    jsr .loword(sub_002040)     ; 00/2100: 20 40 20 ; returns past 12 inline bytes (zero-terminated)
; zero-terminated inline string after call to $002040 (routine reads past its return address)
    .byte $48,$45,$4C,$4C,$4F,$20,$57,$4F,$52,$4C,$44,$00 ; 00/2103 "HELLO WORLD."
    rts                         ; 00/210F: 60
    .res 240                    ; 00/2110
    .byte $C8,$60               ; 00/2200
