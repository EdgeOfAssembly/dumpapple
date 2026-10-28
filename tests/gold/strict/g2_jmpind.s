; dumpapple 0.10.0 listing of tests/progs/g2_jmpind.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2_jmpind.o g2_jmpind.s
;          ld65 -C g2_jmpind.cfg -o g2_jmpind.bin g2_jmpind.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $5B
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002040)     ; 00/2000: 20 40 20 ; returns past 6 inline bytes (zero-terminated)
; zero-terminated inline string after call to $002040 (routine reads past its return address)
    .byte $48,$45,$4C,$4C,$4F,$00 ; 00/2003 "HELLO."
    rts                         ; 00/2009: 60
    .res 54                     ; 00/200A
sub_002040:
    pla                         ; 00/2040: 68
    sta z:$F0                   ; 00/2041: 85 F0
    pla                         ; 00/2043: 68
    sta z:$F1                   ; 00/2044: 85 F1
L002046:
    inc z:$F0                   ; 00/2046: E6 F0
    bne L00204C                 ; 00/2048: D0 02
    inc z:$F1                   ; 00/204A: E6 F1
L00204C:
    ldy #$00                    ; 00/204C: A0 00
    lda ($F0),y                 ; 00/204E: B1 F0
    bne L002046                 ; 00/2050: D0 F4
    inc z:$F0                   ; 00/2052: E6 F0
    bne L002058                 ; 00/2054: D0 02
    inc z:$F1                   ; 00/2056: E6 F1
L002058:
    jmp ($00F0)                 ; 00/2058: 6C F0 00
