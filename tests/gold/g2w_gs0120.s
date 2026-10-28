; dumpapple 0.10.0 listing of tests/progs/g2w_gs0120.bin
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o g2w_gs0120.o g2w_gs0120.s
;          ld65 -C g2w_gs0120.cfg -o g2w_gs0120.bin g2w_gs0120.o
; note: inline-string helper $002040 called at $00200F: COUT $FDED goes through CSW ($36/$37), which the image may change (return to an address that is not a caller's frame (rts dispatch) at $2189); bytes after the call left undecoded

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $18A
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    clc                         ; 00/2000: 18
    xce                         ; 00/2001: FB
    rep #$30                    ; 00/2002: C2 30
    .a16
    .i16
    lda #$0000                  ; 00/2004: A9 00 00
    tcd                         ; 00/2007: 5B
    sep #$30                    ; 00/2008: E2 30
    .a8
    .i8
    sec                         ; 00/200A: 38
    xce                         ; 00/200B: FB
    jsr .loword(sub_002180)     ; 00/200C: 20 80 21
    jsr .loword(sub_002040)     ; 00/200F: 20 40 20 ; unknown: inline string after jsr $002040 not proven (COUT $FDED goes through CSW ($36/$37), which the image may change (return to an address that is not a caller's frame (rts dispatch) at $2189))
    .byte "HELLO"               ; 00/2012
    .byte $00,$60               ; 00/2017
    .res 39                     ; 00/2019
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
    lda #$BF                    ; 00/2182: A9 BF
    sta a:$0120                 ; 00/2184: 8D 20 01
    sec                         ; 00/2187: 38
    xce                         ; 00/2188: FB
    rts                         ; 00/2189: 60
