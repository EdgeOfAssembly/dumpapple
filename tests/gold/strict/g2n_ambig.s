; dumpapple 0.10.0 listing of tests/progs/g2n_ambig.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2n_ambig.o g2n_ambig.s
;          ld65 -C g2n_ambig.cfg -o g2n_ambig.bin g2n_ambig.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)
; note: inline-string helper $002040 called at $002000: paths return to different places ($2009 and $2008); bytes after the call left undecoded

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $64
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002040)     ; 00/2000: 20 40 20 ; unknown: inline string after jsr $002040 not proven (paths return to different places ($2009 and $2008))
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
    beq L002055                 ; 00/204B: F0 08
    ldx a:$0300                 ; 00/204D: AE 00 03
    bmi L002055                 ; 00/2050: 30 03
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
