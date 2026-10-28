; dumpapple 0.10.0 listing of tests/progs/g2n_join.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2n_join.o g2n_join.s
;          ld65 -C g2n_join.cfg -o g2n_join.bin g2n_join.o
; note: inline-string helper $002040 called at $002000: paths return to different places ($2009 and $2006); bytes after the call left undecoded

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $66
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002040)     ; 00/2000: 20 40 20 ; unknown: inline string after jsr $002040 not proven (paths return to different places ($2009 and $2006))
    .byte $41,$42,$00,$60       ; 00/2003
    .res 57                     ; 00/2007
sub_002040:
    pla                         ; 00/2040: 68
    sta z:$F0                   ; 00/2041: 85 F0
    pla                         ; 00/2043: 68
    sta z:$F1                   ; 00/2044: 85 F1
    ldy #$00                    ; 00/2046: A0 00
    lda a:$0300                 ; 00/2048: AD 00 03
    beq L00204F                 ; 00/204B: F0 02
    ldy #$05                    ; 00/204D: A0 05
L00204F:
    iny                         ; 00/204F: C8
    lda ($F0),y                 ; 00/2050: B1 F0
    beq L002057                 ; 00/2052: F0 03
    jmp .loword(L00204F)        ; 00/2054: 4C 4F 20
L002057:
    tya                         ; 00/2057: 98
    clc                         ; 00/2058: 18
    adc z:$F0                   ; 00/2059: 65 F0
    sta z:$F0                   ; 00/205B: 85 F0
    lda z:$F1                   ; 00/205D: A5 F1
    adc #$00                    ; 00/205F: 69 00
    pha                         ; 00/2061: 48
    lda z:$F0                   ; 00/2062: A5 F0
    pha                         ; 00/2064: 48
    rts                         ; 00/2065: 60
