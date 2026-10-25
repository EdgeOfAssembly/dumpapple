; dumpapple 0.9.0 listing of tests/progs/g2c_s03.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o g2c_s03.o g2c_s03.s
;          ld65 -C g2c_s03.cfg -o g2c_s03.bin g2c_s03.o
; note: inline-string helper $002040 called at $00210E: helper code at $2048 may be changed by the store at $2107 (self-modifying code); bytes after the call left undecoded

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $202
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    jmp .loword(L002100)        ; 00/2000: 4C 00 21
    .res 61                     ; 00/2003
sub_002040:
    pla                         ; 00/2040: 68
    sta z:$F0                   ; 00/2041: 85 F0
    pla                         ; 00/2043: 68
    sta z:$F1                   ; 00/2044: 85 F1
    ldy #$00                    ; 00/2046: A0 00 ; changed by a store before it runs: runs as ldy (A0 A0) (self-modifying code)
    iny                         ; 00/2048: C8 ; changed by a store before it runs: runs as ldy (A0 B1) (self-modifying code)
    .byte $B1                   ; 00/2049
    beq $00203C                 ; 00/204A: F0 F0
    asl z:$20                   ; 00/204C: 06 20
    sbc a:$4CFD                 ; 00/204E: ED FD 4C
    pha                         ; 00/2051: 48
    jsr $1898                   ; 00/2052: 20 98 18
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
    clc                         ; 00/2100: 18
    xce                         ; 00/2101: FB
    rep #$20                    ; 00/2102: C2 20
    .a16
    lda #$A0A0                  ; 00/2104: A9 A0 A0
    sta a:$2047                 ; 00/2107: 8D 47 20
    sep #$20                    ; 00/210A: E2 20
    .a8
    sec                         ; 00/210C: 38
    xce                         ; 00/210D: FB
    jsr .loword(sub_002040)     ; 00/210E: 20 40 20 ; unknown: inline string after jsr $002040 not proven (helper code at $2048 may be changed by the store at $2107 (self-modifying code))
    .byte "HELLO WORLD"         ; 00/2111
    .byte $00,$60               ; 00/211C
    .res 226                    ; 00/211E
    .byte $C8,$60               ; 00/2200
