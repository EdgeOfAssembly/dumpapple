; dumpapple 0.9.0 listing of tests/progs/g2n_ind.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2n_ind.o g2n_ind.s
;          ld65 -C g2n_ind.cfg -o g2n_ind.bin g2n_ind.o
; note: inline-string helper $002040 called at $002000: unresolved indirect jump; bytes after the call left undecoded

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $53
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002040)     ; 00/2000: 20 40 20 ; unknown: inline string after jsr $002040 not proven (unresolved indirect jump)
    .byte "HELLO"               ; 00/2003
    .byte $00,$60               ; 00/2008
    .res 54                     ; 00/200A
sub_002040:
    pla                         ; 00/2040: 68
    sta z:$F0                   ; 00/2041: 85 F0
    pla                         ; 00/2043: 68
    sta z:$F1                   ; 00/2044: 85 F1
    ldy #$00                    ; 00/2046: A0 00
L002048:
    iny                         ; 00/2048: C8
    lda ($F0),y                 ; 00/2049: B1 F0
    beq L002050                 ; 00/204B: F0 03
    jmp .loword(L002048)        ; 00/204D: 4C 48 20
L002050:
    jmp ($0300)                 ; 00/2050: 6C 00 03
