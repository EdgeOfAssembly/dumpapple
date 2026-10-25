; dumpapple 0.9.0 listing of tests/progs/a2_mismatch.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o a2_mismatch.o a2_mismatch.s
;          ld65 -C a2_mismatch.cfg -o a2_mismatch.bin a2_mismatch.o
; note: overlapping entry point at $00201B (BIT-skip style; label emitted as an equate)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $21
.segment "SEG1"
.org $002000
entry_002000:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $20,$00,$FD           ; 00/2000
    .byte "HELLO"               ; 00/2003
    .byte $00                   ; 00/2008
entry_002009:
    jsr $FD00                   ; 00/2009: 20 00 FD
; code flow reached here but decoding stopped: undefined 6502 opcode or truncated
    .byte "WORLD"               ; 00/200C
    .byte $00                   ; 00/2011
entry_002012:
    jsr $FD00                   ; 00/2012: 20 00 FD
    eor ($47,x)                 ; 00/2015: 41 47
    eor ($49,x)                 ; 00/2017: 41 49
    lsr a:$2000                 ; 00/2019: 4E 00 20
    .byte $00,$FD               ; 00/201C: 00 FD brk $FD
    lda #$01                    ; 00/201E: A9 01
    rts                         ; 00/2020: 60

; labels that do not start a listing line
entry_00201B = $00201B
