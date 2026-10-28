; dumpapple 0.10.0 listing of tests/progs/g2a_c42.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2a_c42.o g2a_c42.s
;          ld65 -C g2a_c42.cfg -o g2a_c42.bin g2a_c42.o
; note: inline-string helper $002040 called at $002000: the helper sets CSW ($36/$37) before calling COUT $FDED; bytes after the call left undecoded

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $202
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002040)     ; 00/2000: 20 40 20 ; unknown: inline string after jsr $002040 not proven (the helper sets CSW ($36/$37) before calling COUT $FDED)
    .byte "HELLO WORLD"         ; 00/2003
    .byte $00,$60               ; 00/200E
    .res 48                     ; 00/2010
sub_002040:
    pla                         ; 00/2040: 68
    sta z:$F0                   ; 00/2041: 85 F0
    pla                         ; 00/2043: 68
    sta z:$F1                   ; 00/2044: 85 F1
    lda #$00                    ; 00/2046: A9 00
    sta z:$36                   ; 00/2048: 85 36
    lda #$22                    ; 00/204A: A9 22
    sta z:$37                   ; 00/204C: 85 37
    ldy #$00                    ; 00/204E: A0 00
L002050:
    iny                         ; 00/2050: C8
    lda ($F0),y                 ; 00/2051: B1 F0
    beq L00205B                 ; 00/2053: F0 06
    jsr $FDED                   ; 00/2055: 20 ED FD
    jmp .loword(L002050)        ; 00/2058: 4C 50 20
L00205B:
    tya                         ; 00/205B: 98
    clc                         ; 00/205C: 18
    adc z:$F0                   ; 00/205D: 65 F0
    sta z:$F0                   ; 00/205F: 85 F0
    lda z:$F1                   ; 00/2061: A5 F1
    adc #$00                    ; 00/2063: 69 00
    pha                         ; 00/2065: 48
    lda z:$F0                   ; 00/2066: A5 F0
    pha                         ; 00/2068: 48
    rts                         ; 00/2069: 60
    .res 406                    ; 00/206A
    .byte $C8,$60               ; 00/2200
