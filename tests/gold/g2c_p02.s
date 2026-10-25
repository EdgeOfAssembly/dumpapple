; dumpapple 0.9.0 listing of tests/progs/g2c_p02.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2c_p02.o g2c_p02.s
;          ld65 -C g2c_p02.cfg -o g2c_p02.bin g2c_p02.o
; note: inline-string helper $002040 called at $002107: helper code at $2046 may be changed by the store at $2104 (self-modifying code); bytes after the call left undecoded

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $202
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
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $A0,$00               ; 00/2046
    .byte $C8,$B1,$F0,$F0       ; 00/2048 hi-ascii "H1pp"
    .byte $06,$20,$ED,$FD,$4C,$48,$20,$98,$18,$65,$F0,$85,$F0,$A5,$F1,$69 ; 00/204C
    .byte $00,$48,$A5,$F0,$48,$60 ; 00/205C
    .res 158                    ; 00/2062
L002100:
    ldx #$00                    ; 00/2100: A2 00
    lda #$EA                    ; 00/2102: A9 EA
    sta a:$2046,x               ; 00/2104: 9D 46 20
    jsr .loword(sub_002040)     ; 00/2107: 20 40 20 ; unknown: inline string after jsr $002040 not proven (helper code at $2046 may be changed by the store at $2104 (self-modifying code))
    .byte "HELLO WORLD"         ; 00/210A
    .byte $00,$60               ; 00/2115
    .res 233                    ; 00/2117
    .byte $C8,$60               ; 00/2200
