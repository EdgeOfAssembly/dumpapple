; dumpapple 0.10.0 listing of tests/progs/g2w_sry.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o g2w_sry.o g2w_sry.s
;          ld65 -C g2w_sry.cfg -o g2w_sry.bin g2w_sry.o
; assumes stores with unknown targets do not modify code
; note: inline-string helper $002040 called at $002003: helper code at $2040 may be changed by the store at $2186 (self-modifying code); bytes after the call left undecoded
; note: unknown-target stores still count for return frames, CSW and inline helpers: COUT $FDED is not trusted (store through an unknown address at $2186; return to an address that is not a caller's frame (rts dispatch) at $218A)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $18B
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    jsr .loword(sub_002180)     ; 00/2000: 20 80 21
    jsr .loword(sub_002040)     ; 00/2003: 20 40 20 ; unknown: inline string after jsr $002040 not proven (helper code at $2040 may be changed by the store at $2186 (self-modifying code))
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
    ldy #$00                    ; 00/2182: A0 00
    lda #$BF                    ; 00/2184: A9 BF
    sta ($01,s),y               ; 00/2186: 93 01 ; unknown-target store (assumed not to modify code)
    sec                         ; 00/2188: 38
    xce                         ; 00/2189: FB
    rts                         ; 00/218A: 60
