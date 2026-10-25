; dumpapple 0.9.0 listing of tests/progs/g2s_nocout.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2s_nocout.o g2s_nocout.s
;          ld65 -C g2s_nocout.cfg -o g2s_nocout.bin g2s_nocout.o
; note: inline-string helper $002040 called at $002007: the helper's immediate operand at $00204D is modified by a store elsewhere (self-modifying code); bytes after the call left undecoded

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $5B
.segment "SEG1"
.org $002000
entry_002000:
    lda #$01                    ; 00/2000: A9 01
    ldy #$00                    ; 00/2002: A0 00
    sta a:$204D,y               ; 00/2004: 99 4D 20
    jsr .loword(sub_002040)     ; 00/2007: 20 40 20 ; unknown: inline string after jsr $002040 not proven (the helper's immediate operand at $00204D is modified by a store elsewhere (self-modifying code))
    .byte "HELLO"               ; 00/200A
    .byte $00,$60               ; 00/200F
    .res 47                     ; 00/2011
sub_002040:
    pla                         ; 00/2040: 68
    sta z:$F0                   ; 00/2041: 85 F0
    pla                         ; 00/2043: 68
    sta z:$F1                   ; 00/2044: 85 F1
L002046:
    inc z:$F0                   ; 00/2046: E6 F0
    bne L00204C                 ; 00/2048: D0 02
    inc z:$F1                   ; 00/204A: E6 F1
L00204C:
    ldy #$00                    ; 00/204C: A0 00
    lda ($F0),y                 ; 00/204E: B1 F0
    bne L002046                 ; 00/2050: D0 F4
    inc z:$F0                   ; 00/2052: E6 F0
    bne L002058                 ; 00/2054: D0 02
    inc z:$F1                   ; 00/2056: E6 F1
L002058:
    jmp ($00F0)                 ; 00/2058: 6C F0 00
