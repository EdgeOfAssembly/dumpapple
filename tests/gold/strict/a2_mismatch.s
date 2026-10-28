; dumpapple 0.10.0 listing of tests/progs/a2_mismatch.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o a2_mismatch.o a2_mismatch.s
;          ld65 -C a2_mismatch.cfg -o a2_mismatch.bin a2_mismatch.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)
; note: dropped overlapping instruction at $002019 (overlaps --entry $00201B)
; note: dropped overlapping instruction at $00201C

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $21
.segment "SEG1"
.org $002000
entry_002000:
    jsr $FD00                   ; 00/2000: 20 00 FD
    pha                         ; 00/2003: 48
    eor z:$4C                   ; 00/2004: 45 4C
    jmp $004F                   ; 00/2006: 4C 4F 00
entry_002009:
    jsr $FD00                   ; 00/2009: 20 00 FD
; code flow reached here but decoding stopped: undefined 6502 opcode or truncated
    .byte "WORLD"               ; 00/200C
    .byte $00                   ; 00/2011
entry_002012:
    jsr $FD00                   ; 00/2012: 20 00 FD
    eor ($47,x)                 ; 00/2015: 41 47
    eor ($49,x)                 ; 00/2017: 41 49
    .byte $4E,$00               ; 00/2019
entry_00201B:
    jsr $FD00                   ; 00/201B: 20 00 FD
    lda #$01                    ; 00/201E: A9 01
    rts                         ; 00/2020: 60
