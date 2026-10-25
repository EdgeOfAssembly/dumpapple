; dumpapple 0.9.0 listing of tests/progs/b2_mismatch.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o b2_mismatch.o b2_mismatch.s
;          ld65 -C b2_mismatch.cfg -o b2_mismatch.bin b2_mismatch.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $34
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002018)     ; 00/2000: 20 18 20
    pha                         ; 00/2003: 48
    eor z:$4C                   ; 00/2004: 45 4C
    jmp $004F                   ; 00/2006: 4C 4F 00
entry_002009:
    jsr .loword(sub_002018)     ; 00/2009: 20 18 20
; code flow reached here but decoding stopped: undefined 6502 opcode or truncated
    .byte "WORLD"               ; 00/200C
    .byte $00                   ; 00/2011
entry_002012:
    jsr .loword(sub_002018)     ; 00/2012: 20 18 20
    lda #$01                    ; 00/2015: A9 01
    rts                         ; 00/2017: 60
sub_002018:
    pla                         ; 00/2018: 68
    sta z:$F0                   ; 00/2019: 85 F0
    pla                         ; 00/201B: 68
    sta z:$F1                   ; 00/201C: 85 F1
    ldy #$00                    ; 00/201E: A0 00
L002020:
    inc z:$F0                   ; 00/2020: E6 F0
    bne L002026                 ; 00/2022: D0 02
    inc z:$F1                   ; 00/2024: E6 F1
L002026:
    lda ($F0),y                 ; 00/2026: B1 F0
    beq L00202D                 ; 00/2028: F0 03
    jmp .loword(L002020)        ; 00/202A: 4C 20 20
L00202D:
    lda z:$F1                   ; 00/202D: A5 F1
    pha                         ; 00/202F: 48
    lda z:$F0                   ; 00/2030: A5 F0
    pha                         ; 00/2032: 48
    rts                         ; 00/2033: 60
