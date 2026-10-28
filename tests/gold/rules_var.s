; dumpapple 0.10.0 listing of tests/progs/rules_var.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o rules_var.o rules_var.s
;          ld65 -C rules_var.cfg -o rules_var.bin rules_var.o
; assumes CSW hook preserves X/Y (an inline-string helper calls COUT $FDED; nothing in the image stores to CSW $36/$37)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $83
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002010)     ; 00/2000: 20 10 20 ; returns past 3 inline bytes (zero-terminated)
; zero-terminated inline string after call to $002010 (routine reads past its return address)
    .byte $48,$49,$00           ; 00/2003 "HI."
    jsr .loword(sub_002040)     ; 00/2006: 20 40 20 ; returns past 2 inline bytes (bit-7-set-terminated)
; bit-7-set-terminated inline string after call to $002040 (routine reads past its return address)
    .byte $48,$C9               ; 00/2009 "HI"
    jsr .loword(sub_002070)     ; 00/200B: 20 70 20
    rts                         ; 00/200E: 60
    .byte $00                   ; 00/200F
sub_002010:
    pla                         ; 00/2010: 68
    sta z:$F0                   ; 00/2011: 85 F0
    pla                         ; 00/2013: 68
    sta z:$F1                   ; 00/2014: 85 F1
    ldy #$00                    ; 00/2016: A0 00
L002018:
    inc z:$F0                   ; 00/2018: E6 F0
    bne L00201E                 ; 00/201A: D0 02
    inc z:$F1                   ; 00/201C: E6 F1
L00201E:
    lda ($F0),y                 ; 00/201E: B1 F0
    beq L002028                 ; 00/2020: F0 06
    jsr $FDED                   ; 00/2022: 20 ED FD
    jmp .loword(L002018)        ; 00/2025: 4C 18 20
L002028:
    lda z:$F1                   ; 00/2028: A5 F1
    pha                         ; 00/202A: 48
    lda z:$F0                   ; 00/202B: A5 F0
    pha                         ; 00/202D: 48
    rts                         ; 00/202E: 60
    .res 17                     ; 00/202F
sub_002040:
    pla                         ; 00/2040: 68
    sta z:$F2                   ; 00/2041: 85 F2
    pla                         ; 00/2043: 68
    sta z:$F3                   ; 00/2044: 85 F3
    ldy #$00                    ; 00/2046: A0 00
L002048:
    inc z:$F2                   ; 00/2048: E6 F2
    bne L00204E                 ; 00/204A: D0 02
    inc z:$F3                   ; 00/204C: E6 F3
L00204E:
    lda ($F2),y                 ; 00/204E: B1 F2
    bmi L002055                 ; 00/2050: 30 03
    jmp .loword(L002048)        ; 00/2052: 4C 48 20
L002055:
    lda z:$F3                   ; 00/2055: A5 F3
    pha                         ; 00/2057: 48
    lda z:$F2                   ; 00/2058: A5 F2
    pha                         ; 00/205A: 48
    rts                         ; 00/205B: 60
    .res 20                     ; 00/205C
sub_002070:
    pla                         ; 00/2070: 68
    sta z:$F4                   ; 00/2071: 85 F4
    pla                         ; 00/2073: 68
    sta z:$F5                   ; 00/2074: 85 F5
    ldy #$00                    ; 00/2076: A0 00
    lda ($F4),y                 ; 00/2078: B1 F4
    beq L00207C                 ; 00/207A: F0 00
L00207C:
    lda z:$F5                   ; 00/207C: A5 F5
    pha                         ; 00/207E: 48
    lda z:$F4                   ; 00/207F: A5 F4
    pha                         ; 00/2081: 48
    rts                         ; 00/2082: 60
