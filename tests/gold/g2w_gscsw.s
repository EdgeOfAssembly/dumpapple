; dumpapple 0.9.0 listing of tests/progs/g2w_gscsw.bin
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o g2w_gscsw.o g2w_gscsw.s
;          ld65 -C g2w_gscsw.cfg -o g2w_gscsw.bin g2w_gscsw.o
; assumes stores with unknown targets do not modify code
; note: inline-string helper $002040 called at $00200F: helper code at $2040 may be changed by the store at $2182 (self-modifying code); bytes after the call left undecoded
; note: unknown-target stores still count for return frames, CSW and inline helpers: COUT $FDED is not trusted (store that may reach CSW at $2182; store that may modify code (self-modifying code) at $2182; return to an address that is not a caller's frame (rts dispatch) at $2184)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $185
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    jsr .loword(sub_002180)     ; 00/2000: 20 80 21
    clc                         ; 00/2003: 18
    xce                         ; 00/2004: FB
    rep #$30                    ; 00/2005: C2 30
    .a16
    .i16
    lda #$0000                  ; 00/2007: A9 00 00
    tcd                         ; 00/200A: 5B
    sep #$30                    ; 00/200B: E2 30
    .a8
    .i8
    sec                         ; 00/200D: 38
    xce                         ; 00/200E: FB
    jsr .loword(sub_002040)     ; 00/200F: 20 40 20 ; unknown: inline string after jsr $002040 not proven (helper code at $2040 may be changed by the store at $2182 (self-modifying code))
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
    lda #$00                    ; 00/2180: A9 00
    sta z:$36                   ; 00/2182: 85 36 ; unknown-target store (assumed not to modify code)
    rts                         ; 00/2184: 60
