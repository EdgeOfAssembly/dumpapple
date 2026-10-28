; dumpapple 0.10.0 listing of tests/progs/ba_lda1bne.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o ba_lda1bne.o ba_lda1bne.s
;          ld65 -C ba_lda1bne.cfg -o ba_lda1bne.bin ba_lda1bne.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $8
.segment "SEG1"
.org $002000
entry_002000:
    lda #$01                    ; 00/2000: A9 01
    bne L002007                 ; 00/2002: D0 03
    .byte $48,$49,$00           ; 00/2004
L002007:
    rts                         ; 00/2007: 60
