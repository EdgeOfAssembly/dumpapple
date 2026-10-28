; dumpapple 0.10.0 listing of tests/progs/rules_varhint.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o rules_varhint.o rules_varhint.s
;          ld65 -C rules_varhint.cfg -o rules_varhint.bin rules_varhint.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $7
.segment "SEG1"
.org $002000
entry_002000:
    jsr $B006                   ; 00/2000: 20 06 B0 ; returns past 3 inline bytes (zero-terminated)
; zero-terminated inline string after call to $00B006 (hint)
    .byte $4F,$4B,$00           ; 00/2003 "OK."
    rts                         ; 00/2006: 60
