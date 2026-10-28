; dumpapple 0.10.0 listing of tests/progs/g2s_rngu.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2s_rngu.o g2s_rngu.s
;          ld65 -C g2s_rngu.cfg -o g2s_rngu.bin g2s_rngu.o
; assumes stores with unknown targets do not modify code
; note: inline-string helper $002040 called at $002003: COUT $FDED goes through CSW ($36/$37), which the image may change (store that may modify code (self-modifying code) at $2185); bytes after the call left undecoded
; note: unknown-target stores still count for return frames, CSW and inline helpers: COUT $FDED is not trusted (store that may modify code (self-modifying code) at $2185)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $18F
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002180)     ; 00/2000: 20 80 21
    jsr .loword(sub_002040)     ; 00/2003: 20 40 20 ; unknown: inline string after jsr $002040 not proven (COUT $FDED goes through CSW ($36/$37), which the image may change (store that may modify code (self-modifying code) at $2185))
    .byte "HELLO"               ; 00/2006
    .byte $00,$60               ; 00/200B
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
    ldy a:$0300                 ; 00/2180: AC 00 03
    lda #$05                    ; 00/2183: A9 05
    sta a:$218A,y               ; 00/2185: 99 8A 21 ; unknown-target store (assumed not to modify code)
    clc                         ; 00/2188: 18
    nop                         ; 00/2189: EA
    adc #$00                    ; 00/218A: 69 00
    cmp #$00                    ; 00/218C: C9 00
    rts                         ; 00/218E: 60
