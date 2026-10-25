; dumpapple 0.9.0 listing of tests/progs/g2c_v01.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2c_v01.o g2c_v01.s
;          ld65 -C g2c_v01.cfg -o g2c_v01.bin g2c_v01.o
; assumes stores with unknown targets do not modify code
; note: inline-string helper $002040 called at $00218E: helper code at $2040 may be changed by the store at $211A (self-modifying code); bytes after the call left undecoded
; note: unknown-target stores still count for return frames, CSW and inline helpers: COUT $FDED is not trusted (store through an unresolved pointer (F8) at $211A; store through an unresolved pointer (F8) at $2128; store through an unresolved pointer (F8) at $2136; store through an unresolved pointer (F8) at $2144; store through an unresolved pointer (F8) at $2152; store through an unresolved pointer (F8) at $2160; store through an unresolved pointer (F8) at $216E; store through an unresolved pointer (F8) at $217C; store through an unresolved pointer (F8) at $218A)

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
    .res 158                    ; 00/2062
L002100:
    lda #$0F                    ; 00/2100: A9 0F
    sta z:$F8                   ; 00/2102: 85 F8
    lda #$21                    ; 00/2104: A9 21
    sta z:$F9                   ; 00/2106: 85 F9
    ldy #$00                    ; 00/2108: A0 00
    lda #$EA                    ; 00/210A: A9 EA
    sta ($F8),y                 ; 00/210C: 91 F8
    lda #$1D                    ; 00/210E: A9 1D
    sta z:$F8                   ; 00/2110: 85 F8
    lda #$21                    ; 00/2112: A9 21
    sta z:$F9                   ; 00/2114: 85 F9
    ldy #$00                    ; 00/2116: A0 00
    lda #$EA                    ; 00/2118: A9 EA
    sta ($F8),y                 ; 00/211A: 91 F8 ; unknown-target store (assumed not to modify code)
    lda #$2B                    ; 00/211C: A9 2B
    sta z:$F8                   ; 00/211E: 85 F8
    lda #$21                    ; 00/2120: A9 21
    sta z:$F9                   ; 00/2122: 85 F9
    ldy #$00                    ; 00/2124: A0 00
    lda #$EA                    ; 00/2126: A9 EA
    sta ($F8),y                 ; 00/2128: 91 F8 ; unknown-target store (assumed not to modify code)
    lda #$39                    ; 00/212A: A9 39
    sta z:$F8                   ; 00/212C: 85 F8
    lda #$21                    ; 00/212E: A9 21
    sta z:$F9                   ; 00/2130: 85 F9
    ldy #$00                    ; 00/2132: A0 00
    lda #$EA                    ; 00/2134: A9 EA
    sta ($F8),y                 ; 00/2136: 91 F8 ; unknown-target store (assumed not to modify code)
    lda #$47                    ; 00/2138: A9 47
    sta z:$F8                   ; 00/213A: 85 F8
    lda #$21                    ; 00/213C: A9 21
    sta z:$F9                   ; 00/213E: 85 F9
    ldy #$00                    ; 00/2140: A0 00
    lda #$EA                    ; 00/2142: A9 EA
    sta ($F8),y                 ; 00/2144: 91 F8 ; unknown-target store (assumed not to modify code)
    lda #$55                    ; 00/2146: A9 55
    sta z:$F8                   ; 00/2148: 85 F8
    lda #$21                    ; 00/214A: A9 21
    sta z:$F9                   ; 00/214C: 85 F9
    ldy #$00                    ; 00/214E: A0 00
    lda #$EA                    ; 00/2150: A9 EA
    sta ($F8),y                 ; 00/2152: 91 F8 ; unknown-target store (assumed not to modify code)
    lda #$63                    ; 00/2154: A9 63
    sta z:$F8                   ; 00/2156: 85 F8
    lda #$21                    ; 00/2158: A9 21
    sta z:$F9                   ; 00/215A: 85 F9
    ldy #$00                    ; 00/215C: A0 00
    lda #$EA                    ; 00/215E: A9 EA
    sta ($F8),y                 ; 00/2160: 91 F8 ; unknown-target store (assumed not to modify code)
    lda #$71                    ; 00/2162: A9 71
    sta z:$F8                   ; 00/2164: 85 F8
    lda #$21                    ; 00/2166: A9 21
    sta z:$F9                   ; 00/2168: 85 F9
    ldy #$00                    ; 00/216A: A0 00
    lda #$EA                    ; 00/216C: A9 EA
    sta ($F8),y                 ; 00/216E: 91 F8 ; unknown-target store (assumed not to modify code)
    lda #$7F                    ; 00/2170: A9 7F
    sta z:$F8                   ; 00/2172: 85 F8
    lda #$21                    ; 00/2174: A9 21
    sta z:$F9                   ; 00/2176: 85 F9
    ldy #$00                    ; 00/2178: A0 00
    lda #$EA                    ; 00/217A: A9 EA
    sta ($F8),y                 ; 00/217C: 91 F8 ; unknown-target store (assumed not to modify code)
    lda #$8D                    ; 00/217E: A9 8D
    sta z:$F8                   ; 00/2180: 85 F8
    lda #$21                    ; 00/2182: A9 21
    sta z:$F9                   ; 00/2184: 85 F9
    ldy #$00                    ; 00/2186: A0 00
    lda #$EA                    ; 00/2188: A9 EA
    sta ($F8),y                 ; 00/218A: 91 F8 ; unknown-target store (assumed not to modify code)
    lda #$00                    ; 00/218C: A9 00
    jsr .loword(sub_002040)     ; 00/218E: 20 40 20 ; unknown: inline string after jsr $002040 not proven (helper code at $2040 may be changed by the store at $211A (self-modifying code))
    .byte "HELLO WORLD"         ; 00/2191
    .byte $00,$60               ; 00/219C
    .res 98                     ; 00/219E
    .byte $C8,$60               ; 00/2200
