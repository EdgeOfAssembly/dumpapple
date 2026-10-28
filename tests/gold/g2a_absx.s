; dumpapple 0.10.0 listing of tests/progs/g2a_absx.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2a_absx.o g2a_absx.s
;          ld65 -C g2a_absx.cfg -o g2a_absx.bin g2a_absx.o
; assumes stores with unknown targets do not modify code
; note: inline-string helper $002040 called at $002000: helper code at $2040 may be changed by the store at $204B (self-modifying code); bytes after the call left undecoded
; note: unknown-target stores still count for return frames, CSW and inline helpers: COUT $FDED is not trusted (store that may modify code (self-modifying code) at $204B)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $6A
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002040)     ; 00/2000: 20 40 20 ; unknown: inline string after jsr $002040 not proven (helper code at $2040 may be changed by the store at $204B (self-modifying code))
    .byte "HELLO"               ; 00/2003
    .byte $00,$60               ; 00/2008
    .res 54                     ; 00/200A
sub_002040:
    pla                         ; 00/2040: 68
    sta z:$F0                   ; 00/2041: 85 F0
    pla                         ; 00/2043: 68
    sta z:$F1                   ; 00/2044: 85 F1
    ldx a:$0300                 ; 00/2046: AE 00 03
    lda #$00                    ; 00/2049: A9 00
    sta a:$2000,x               ; 00/204B: 9D 00 20 ; unknown-target store (assumed not to modify code)
    ldy #$00                    ; 00/204E: A0 00
L002050:
    iny                         ; 00/2050: C8
    lda ($F0),y                 ; 00/2051: B1 F0
    beq L00205B                 ; 00/2053: F0 06
    jsr $FDED                   ; 00/2055: 20 ED FD
    jmp .loword(L002050)        ; 00/2058: 4C 50 20
L00205B:
    tya                         ; 00/205B: 98
    clc                         ; 00/205C: 18
    adc z:$F0                   ; 00/205D: 65 F0
    sta z:$F0                   ; 00/205F: 85 F0
    lda z:$F1                   ; 00/2061: A5 F1
    adc #$00                    ; 00/2063: 69 00
    pha                         ; 00/2065: 48
    lda z:$F0                   ; 00/2066: A5 F0
    pha                         ; 00/2068: 48
    rts                         ; 00/2069: 60
