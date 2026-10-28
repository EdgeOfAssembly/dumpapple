; dumpapple 0.10.0 listing of tests/progs/g2a_c40.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2a_c40.o g2a_c40.s
;          ld65 -C g2a_c40.cfg -o g2a_c40.bin g2a_c40.o
; note: inline-string helper $002040 called at $00200A: COUT $FDED goes through CSW ($36/$37), which the image may change (store that may reach CSW at $2004); bytes after the call left undecoded

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $202
.segment "SEG1"
.org $002000
entry_002000:
    ldx #$00                    ; 00/2000: A2 00
    lda #$00                    ; 00/2002: A9 00
    sta z:$36,x                 ; 00/2004: 95 36
    lda #$22                    ; 00/2006: A9 22
    sta z:$37,x                 ; 00/2008: 95 37
    jsr .loword(sub_002040)     ; 00/200A: 20 40 20 ; unknown: inline string after jsr $002040 not proven (COUT $FDED goes through CSW ($36/$37), which the image may change (store that may reach CSW at $2004))
    .byte "HELLO WORLD"         ; 00/200D
    .byte $00,$60               ; 00/2018
    .res 38                     ; 00/201A
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
    .res 414                    ; 00/2062
    .byte $C8,$60               ; 00/2200
