; dumpapple 0.10.0 listing of tests/progs/g2a_c18.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2a_c18.o g2a_c18.s
;          ld65 -C g2a_c18.cfg -o g2a_c18.bin g2a_c18.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)
; note: inline-string helper $002040 called at $002000: return to $2008 does not land right after the last byte read ($2008); bytes after the call left undecoded

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $6C
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002040)     ; 00/2000: 20 40 20 ; unknown: inline string after jsr $002040 not proven (return to $2008 does not land right after the last byte read ($2008))
    .byte "HELLO"               ; 00/2003
    .byte $00,$60               ; 00/2008
    .res 54                     ; 00/200A
sub_002040:
    pla                         ; 00/2040: 68
    sta z:$F0                   ; 00/2041: 85 F0
    pla                         ; 00/2043: 68
    sta z:$F1                   ; 00/2044: 85 F1
    lda z:$F0                   ; 00/2046: A5 F0
    sta z:$F2                   ; 00/2048: 85 F2
    lda z:$F1                   ; 00/204A: A5 F1
    sta z:$F3                   ; 00/204C: 85 F3
    inc z:$F2                   ; 00/204E: E6 F2
    ldy #$00                    ; 00/2050: A0 00
L002052:
    iny                         ; 00/2052: C8
    lda ($F2),y                 ; 00/2053: B1 F2
    beq L00205D                 ; 00/2055: F0 06
    jsr $FDED                   ; 00/2057: 20 ED FD
    jmp .loword(L002052)        ; 00/205A: 4C 52 20
L00205D:
    tya                         ; 00/205D: 98
    clc                         ; 00/205E: 18
    adc z:$F0                   ; 00/205F: 65 F0
    sta z:$F0                   ; 00/2061: 85 F0
    lda z:$F1                   ; 00/2063: A5 F1
    adc #$00                    ; 00/2065: 69 00
    pha                         ; 00/2067: 48
    lda z:$F0                   ; 00/2068: A5 F0
    pha                         ; 00/206A: 48
    rts                         ; 00/206B: 60
