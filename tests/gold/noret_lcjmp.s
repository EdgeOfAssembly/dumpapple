; dumpapple 0.10.0 listing of tests/progs/noret_lcjmp.bin
; cpu 6502, platform prodos8
; rebuild: ca65 --cpu 6502 -t none -o noret_lcjmp.o noret_lcjmp.s
;          ld65 -C noret_lcjmp.cfg -o noret_lcjmp.bin noret_lcjmp.o
; note: call to ROM $FF69 at $002008 followed as an ordinary call: decoded code may switch the language card ($C080-$C08F) and map RAM over the ROM

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $F
.segment "SEG1"
.org $002000
entry_002000:
    lda a:$0300                 ; 00/2000: AD 00 03
    beq L002008                 ; 00/2003: F0 03
    jmp ($C080)                 ; 00/2005: 6C 80 C0
L002008:
    jsr $FF69                   ; 00/2008: 20 69 FF
    sta a:$C000                 ; 00/200B: 8D 00 C0
    rts                         ; 00/200E: 60
