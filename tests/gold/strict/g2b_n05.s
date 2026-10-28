; dumpapple 0.10.0 listing of tests/progs/g2b_n05.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2b_n05.o g2b_n05.s
;          ld65 -C g2b_n05.cfg -o g2b_n05.bin g2b_n05.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)
; note: inline-string helper $002040 called at $00210F: COUT $FDED goes through CSW ($36/$37), which the image may change (unresolved indirect jump at $2120); bytes after the call left undecoded

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
    lda a:$21F0                 ; 00/2100: AD F0 21
    sta a:$0300                 ; 00/2103: 8D 00 03
    lda a:$21F1                 ; 00/2106: AD F1 21
    sta a:$0301                 ; 00/2109: 8D 01 03
    jsr .loword(sub_002120)     ; 00/210C: 20 20 21
    jsr .loword(sub_002040)     ; 00/210F: 20 40 20 ; unknown: inline string after jsr $002040 not proven (COUT $FDED goes through CSW ($36/$37), which the image may change (unresolved indirect jump at $2120))
    .byte "HELLO WORLD"         ; 00/2112
    .byte $00,$60,$00           ; 00/211D
sub_002120:
    jmp ($0300)                 ; 00/2120: 6C 00 03
    .res 93                     ; 00/2123
    .byte $A9,$00,$85,$36,$A9,$22,$85,$37,$60 ; 00/2180
    .res 103                    ; 00/2189
    .byte $80,$21,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 00/21F0
    .byte $C8,$60               ; 00/2200
