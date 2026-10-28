; dumpapple 0.10.0 listing of tests/progs/g2s_816.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o g2s_816.o g2s_816.s
;          ld65 -C g2s_816.cfg -o g2s_816.bin g2s_816.o
; note: inline-string helper $002040 called at $002003: COUT $FDED goes through CSW ($36/$37), which the image may change (decoding stopped at $2188 (accumulator width unknown (M flag conflict)), code there not checked); bytes after the call left undecoded

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $18D
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    jsr .loword(sub_002180)     ; 00/2000: 20 80 21
    jsr .loword(sub_002040)     ; 00/2003: 20 40 20 ; unknown: inline string after jsr $002040 not proven (COUT $FDED goes through CSW ($36/$37), which the image may change (decoding stopped at $2188 (accumulator width unknown (M flag conflict)), code there not checked))
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
    clc                         ; 00/2180: 18
    xce                         ; 00/2181: FB
    lda #$05                    ; 00/2182: A9 05
    sta a:$218A                 ; 00/2184: 8D 8A 21
    plp                         ; 00/2187: 28
; code flow reached here but decoding stopped: accumulator width unknown (M flag conflict)
    .byte $69,$00,$38,$FB,$60   ; 00/2188
