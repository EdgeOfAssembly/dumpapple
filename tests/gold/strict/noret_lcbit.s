; dumpapple 0.10.0 listing of tests/progs/noret_lcbit.bin
; cpu 6502, platform prodos8
; rebuild: ca65 --cpu 6502 -t none -o noret_lcbit.o noret_lcbit.s
;          ld65 -C noret_lcbit.cfg -o noret_lcbit.bin noret_lcbit.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)
; note: call to ROM $FF69 at $002006 followed as an ordinary call: decoded code may switch the language card ($C080-$C08F) and map RAM over the ROM

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $D
.segment "SEG1"
.org $002000
entry_002000:
    bit a:$C08B                 ; 00/2000: 2C 8B C0
    bit a:$C08B                 ; 00/2003: 2C 8B C0
    jsr $FF69                   ; 00/2006: 20 69 FF
    sta a:$C000                 ; 00/2009: 8D 00 C0
    rts                         ; 00/200C: 60
