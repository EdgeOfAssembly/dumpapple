; dumpapple 0.9.0 listing of tests/progs/t03.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o t03.o t03.s
;          ld65 -C t03.cfg -o t03.bin t03.o
; note: inline-string helper $002040 called at $002103: COUT $FDED goes through CSW ($36/$37), which the image may change (store that may reach CSW at $218C); bytes after the call left undecoded

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
    jsr .loword(sub_002040)     ; 00/2103: 20 40 20 ; unknown: inline string after jsr $002040 not proven (COUT $FDED goes through CSW ($36/$37), which the image may change (store that may reach CSW at $218C))
    .byte "HELLO WORLD"         ; 00/2106
    .byte $00,$60               ; 00/2111
    .res 109                    ; 00/2113
sub_002180:
    lda #$36                    ; 00/2180: A9 36
    sta a:$21A1                 ; 00/2182: 8D A1 21
    ldy #$03                    ; 00/2185: A0 03
L002187:
    ldx a:$21A0,y               ; 00/2187: BE A0 21
    lda #$BF                    ; 00/218A: A9 BF
    sta z:$30,x                 ; 00/218C: 95 30
    dey                         ; 00/218E: 88
    bpl L002187                 ; 00/218F: 10 F6
    rts                         ; 00/2191: 60
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01 ; 00/2192
    .byte $02,$03               ; 00/21A2
