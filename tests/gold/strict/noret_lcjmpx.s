; dumpapple 0.9.0 listing of tests/progs/noret_lcjmpx.bin
; cpu 65c02, platform prodos8
; rebuild: ca65 --cpu 65C02 -t none -o noret_lcjmpx.o noret_lcjmpx.s
;          ld65 -C noret_lcjmpx.cfg -o noret_lcjmpx.bin noret_lcjmpx.o
; note: call to ROM $FF69 at $002008 followed as an ordinary call: decoded code may switch the language card ($C080-$C08F) and map RAM over the ROM

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $F
.segment "SEG1"
.org $002000
entry_002000:
    lda a:$0300                 ; 00/2000: AD 00 03
    beq L002008                 ; 00/2003: F0 03
    jmp ($C000,x)               ; 00/2005: 7C 00 C0
L002008:
    jsr $FF69                   ; 00/2008: 20 69 FF
    sta a:$C000                 ; 00/200B: 8D 00 C0
    rts                         ; 00/200E: 60
