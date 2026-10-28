; dumpapple 0.10.0 listing of tests/progs/rules_davex.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o rules_twohints.o rules_twohints.s
;          ld65 -C rules_twohints.cfg -o rules_twohints.bin rules_twohints.o

.setcpu "6502"

; ------------------------------------------------------------
; base $009000 length $D
.segment "SEG1"
.org $009000
entry_009000:
    jsr $B006                   ; 00/9000: 20 06 B0 ; returns past 3 inline bytes (zero-terminated)
; zero-terminated inline string after call to $00B006 (hint)
    .byte $4F,$4B,$00           ; 00/9003 "OK."
    jsr .loword(sub_009009)     ; 00/9006: 20 09 90 ; does not return (assumed by noreturn hint)
sub_009009:
    jmp $B048                   ; 00/9009: 4C 48 B0
    .byte $60                   ; 00/900C
