; dumpapple 0.10.0 listing of tests/progs/g2c_s04.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o g2c_s04.o g2c_s04.s
;          ld65 -C g2c_s04.cfg -o g2c_s04.bin g2c_s04.o
; note: inline-string helper $002040 called at $00210C: helper code at $2048 may be changed by the store at $2107 (self-modifying code); bytes after the call left undecoded

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
    ldy #$00                    ; 00/2046: A0 00
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $C8,$B1,$F0,$F0       ; 00/2048 hi-ascii "H1pp"
    .byte $06,$20,$ED,$FD,$4C,$48,$20,$98,$18,$65,$F0,$85,$F0,$A5,$F1,$69 ; 00/204C
    .byte $00,$48,$A5,$F0,$48,$60 ; 00/205C
    .res 158                    ; 00/2062
L002100:
    clc                         ; 00/2100: 18
    xce                         ; 00/2101: FB
    lda a:$0300                 ; 00/2102: AD 00 03
    pha                         ; 00/2105: 48
    plp                         ; 00/2106: 28
    sta a:$2047                 ; 00/2107: 8D 47 20
    sec                         ; 00/210A: 38
    xce                         ; 00/210B: FB
    jsr .loword(sub_002040)     ; 00/210C: 20 40 20 ; unknown: inline string after jsr $002040 not proven (helper code at $2048 may be changed by the store at $2107 (self-modifying code))
    .byte "HELLO WORLD"         ; 00/210F
    .byte $00,$60               ; 00/211A
    .res 228                    ; 00/211C
    .byte $C8,$60               ; 00/2200
