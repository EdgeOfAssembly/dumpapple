; dumpapple 0.10.0 listing of tests/progs/g2b_n24.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2b_n24.o g2b_n24.s
;          ld65 -C g2b_n24.cfg -o g2b_n24.bin g2b_n24.o
; assumes stores with unknown targets do not modify code
; note: inline-string helper $002040 called at $002100: helper code at $2040 may be changed by the store at $2050 (self-modifying code); bytes after the call left undecoded
; note: unknown-target stores still count for return frames, CSW and inline helpers: COUT $FDED is not trusted (store that may modify code (self-modifying code) at $2050)

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
    ldx a:$0300                 ; 00/2046: AE 00 03
    ldy #$00                    ; 00/2049: A0 00
L00204B:
    iny                         ; 00/204B: C8
    lda ($F0),y                 ; 00/204C: B1 F0
    beq L002059                 ; 00/204E: F0 09
    sta a:$2000,x               ; 00/2050: 9D 00 20 ; unknown-target store (assumed not to modify code)
    jsr $FDED                   ; 00/2053: 20 ED FD
    jmp .loword(L00204B)        ; 00/2056: 4C 4B 20
L002059:
    tya                         ; 00/2059: 98
    clc                         ; 00/205A: 18
    adc z:$F0                   ; 00/205B: 65 F0
    sta z:$F0                   ; 00/205D: 85 F0
    lda z:$F1                   ; 00/205F: A5 F1
    adc #$00                    ; 00/2061: 69 00
    pha                         ; 00/2063: 48
    lda z:$F0                   ; 00/2064: A5 F0
    pha                         ; 00/2066: 48
    rts                         ; 00/2067: 60
    .res 152                    ; 00/2068
L002100:
    jsr .loword(sub_002040)     ; 00/2100: 20 40 20 ; unknown: inline string after jsr $002040 not proven (helper code at $2040 may be changed by the store at $2050 (self-modifying code))
    .byte "HELLO WORLD"         ; 00/2103
    .byte $00,$60               ; 00/210E
    .res 240                    ; 00/2110
    .byte $C8,$60               ; 00/2200
