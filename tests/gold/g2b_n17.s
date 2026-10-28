; dumpapple 0.10.0 listing of tests/progs/g2b_n17.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2b_n17.o g2b_n17.s
;          ld65 -C g2b_n17.cfg -o g2b_n17.bin g2b_n17.o
; note: inline-string helper $002040 called at $002100: return to $2110 does not land right after the last byte read ($210E); bytes after the call left undecoded

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
    ldx #$00                    ; 00/2046: A2 00
L002048:
    inc z:$F0                   ; 00/2048: E6 F0
    bne L00204E                 ; 00/204A: D0 02
    inc z:$F1                   ; 00/204C: E6 F1
L00204E:
    lda ($F0,x)                 ; 00/204E: A1 F0
    beq L002058                 ; 00/2050: F0 06
    jsr $FDED                   ; 00/2052: 20 ED FD
    jmp .loword(L002048)        ; 00/2055: 4C 48 20
L002058:
    inc z:$F0                   ; 00/2058: E6 F0
    bne L00205E                 ; 00/205A: D0 02
    inc z:$F1                   ; 00/205C: E6 F1
L00205E:
    lda z:$F1                   ; 00/205E: A5 F1
    pha                         ; 00/2060: 48
    lda z:$F0                   ; 00/2061: A5 F0
    pha                         ; 00/2063: 48
    rts                         ; 00/2064: 60
    .res 155                    ; 00/2065
L002100:
    jsr .loword(sub_002040)     ; 00/2100: 20 40 20 ; unknown: inline string after jsr $002040 not proven (return to $2110 does not land right after the last byte read ($210E))
    .byte "HELLO WORLD"         ; 00/2103
    .byte $00,$60               ; 00/210E
    .res 240                    ; 00/2110
    .byte $C8,$60               ; 00/2200
