; dumpapple 0.9.0 listing of tests/progs/prodos8_mli.bin
; cpu 6502, platform prodos8
; rebuild: ca65 --cpu 6502 -t none -o prodos8_mli.o prodos8_mli.s
;          ld65 -C prodos8_mli.cfg -o prodos8_mli.bin prodos8_mli.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $13
.segment "SEG1"
.org $002000
entry_002000:
    jsr $BF00                   ; 00/2000: 20 00 BF ; returns past 3 inline bytes
; ProDOS 8 MLI command + parameter list pointer after call to $00BF00
    .byte $C8                   ; 00/2003 MLI command
    .word .loword(params_00200B) ; 00/2004 parameter list
    bcs L00200A                 ; 00/2006: B0 02
    lda #$00                    ; 00/2008: A9 00
L00200A:
    rts                         ; 00/200A: 60
params_00200B:
    .byte $03,$0E,$20,$04       ; 00/200B
    .byte "FILE"                ; 00/200F
