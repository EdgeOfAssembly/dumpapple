; dumpapple 0.10.0 listing of tests/progs/g1_sec.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g1_sec.o g1_sec.s
;          ld65 -C g1_sec.cfg -o g1_sec.bin g1_sec.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $34
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_00200E)     ; 00/2000: 20 0E 20 ; returns past 5 inline bytes (length-prefixed)
; length-prefixed inline string after call to $00200E (routine reads past its return address)
    .byte $03,$41,$42,$43,$20   ; 00/2003 ".ABC "
    asl a:$0020                 ; 00/2008: 0E 20 00
    lda #$01                    ; 00/200B: A9 01
    rts                         ; 00/200D: 60
sub_00200E:
    pla                         ; 00/200E: 68
    sta z:$F0                   ; 00/200F: 85 F0
    pla                         ; 00/2011: 68
    sta z:$F1                   ; 00/2012: 85 F1
    ldy #$01                    ; 00/2014: A0 01
    lda ($F0),y                 ; 00/2016: B1 F0
    sta z:$F2                   ; 00/2018: 85 F2
L00201A:
    cpy z:$F2                   ; 00/201A: C4 F2
    bcs L002024                 ; 00/201C: B0 06
    iny                         ; 00/201E: C8
    lda ($F0),y                 ; 00/201F: B1 F0
    jmp .loword(L00201A)        ; 00/2021: 4C 1A 20
L002024:
    iny                         ; 00/2024: C8
    tya                         ; 00/2025: 98
    sec                         ; 00/2026: 38
    adc z:$F0                   ; 00/2027: 65 F0
    sta z:$F0                   ; 00/2029: 85 F0
    lda z:$F1                   ; 00/202B: A5 F1
    adc #$00                    ; 00/202D: 69 00
    pha                         ; 00/202F: 48
    lda z:$F0                   ; 00/2030: A5 F0
    pha                         ; 00/2032: 48
    rts                         ; 00/2033: 60
