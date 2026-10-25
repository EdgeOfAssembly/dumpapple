; dumpapple 0.9.0 listing of tests/progs/g2s_opc.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2s_opc.o g2s_opc.s
;          ld65 -C g2s_opc.cfg -o g2s_opc.bin g2s_opc.o
; note: inline-string helper $002040 called at $002003: COUT $FDED goes through CSW ($36/$37), which the image may change (store that may modify code (self-modifying code) at $2182); bytes after the call left undecoded

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $191
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002180)     ; 00/2000: 20 80 21
    jsr .loword(sub_002040)     ; 00/2003: 20 40 20 ; unknown: inline string after jsr $002040 not proven (COUT $FDED goes through CSW ($36/$37), which the image may change (store that may modify code (self-modifying code) at $2182))
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
    lda #$05                    ; 00/2180: A9 05
    sta a:$218C                 ; 00/2182: 8D 8C 21
    lda #$0D                    ; 00/2185: A9 0D
    sta a:$218F                 ; 00/2187: 8D 8F 21
    clc                         ; 00/218A: 18
    nop                         ; 00/218B: EA
    adc #$00                    ; 00/218C: 69 00 ; changed by a store before it runs: runs as ora (05 00) (self-modifying code)
    cmp #$00                    ; 00/218E: C9 00
    rts                         ; 00/2190: 60
