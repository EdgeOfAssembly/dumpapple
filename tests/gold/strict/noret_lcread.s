; dumpapple 0.9.0 listing of tests/progs/noret_lcread.bin
; cpu 6502, platform prodos8
; rebuild: ca65 --cpu 6502 -t none -o noret_lcread.o noret_lcread.s
;          ld65 -C noret_lcread.cfg -o noret_lcread.bin noret_lcread.o
; note: call to ROM $FF69 at $002003 followed as an ordinary call: decoded code may switch the language card ($C080-$C08F) and map RAM over the ROM

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $A
.segment "SEG1"
.org $002000
entry_002000:
    lda a:$C081                 ; 00/2000: AD 81 C0
    jsr $FF69                   ; 00/2003: 20 69 FF
    sta a:$C000                 ; 00/2006: 8D 00 C0
    rts                         ; 00/2009: 60
