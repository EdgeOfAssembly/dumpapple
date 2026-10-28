; dumpapple 0.10.0 listing of tests/progs/g2c_p03.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2c_p03.o g2c_p03.s
;          ld65 -C g2c_p03.cfg -o g2c_p03.bin g2c_p03.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)
; note: inline-string helper $002040 called at $002105: the helper's immediate operand at $00204C is modified by a store elsewhere (self-modifying code); bytes after the call left undecoded

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
    ldy #$00                    ; 00/2046: A0 00
L002048:
    iny                         ; 00/2048: C8
    lda ($F0),y                 ; 00/2049: B1 F0
    cmp #$00                    ; 00/204B: C9 00
    beq L002055                 ; 00/204D: F0 06
    jsr $FDED                   ; 00/204F: 20 ED FD
    jmp .loword(L002048)        ; 00/2052: 4C 48 20
L002055:
    tya                         ; 00/2055: 98
    clc                         ; 00/2056: 18
    adc z:$F0                   ; 00/2057: 65 F0
    sta z:$F0                   ; 00/2059: 85 F0
    lda z:$F1                   ; 00/205B: A5 F1
    adc #$00                    ; 00/205D: 69 00
    pha                         ; 00/205F: 48
    lda z:$F0                   ; 00/2060: A5 F0
    pha                         ; 00/2062: 48
    rts                         ; 00/2063: 60
    .res 156                    ; 00/2064
L002100:
    lda #$21                    ; 00/2100: A9 21
    sta a:$204C                 ; 00/2102: 8D 4C 20
    jsr .loword(sub_002040)     ; 00/2105: 20 40 20 ; unknown: inline string after jsr $002040 not proven (the helper's immediate operand at $00204C is modified by a store elsewhere (self-modifying code))
    .byte "HI!THERE"            ; 00/2108
    .byte $00,$60               ; 00/2110
    .res 238                    ; 00/2112
    .byte $C8,$60               ; 00/2200
