; dumpapple 0.9.0 listing of tests/progs/noret_lc.bin
; cpu 65c02, platform prodos8
; rebuild: ca65 --cpu 65C02 -t none -o noret_lc.o noret_lc.s
;          ld65 -C noret_lc.cfg -o noret_lc.bin noret_lc.o
; note: call to ROM $FF69 at $002010 followed as an ordinary call: decoded code may switch the language card ($C080-$C08F) and map RAM over the ROM

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $1A
.segment "SEG1"
.org $002000
entry_002000:
    lda a:$C083                 ; 00/2000: AD 83 C0
    lda a:$0300                 ; 00/2003: AD 00 03
    beq L002010                 ; 00/2006: F0 08
    lda #$60                    ; 00/2008: A9 60
    sta a:$2013                 ; 00/200A: 8D 13 20
    jmp .loword(L002013)        ; 00/200D: 4C 13 20
L002010:
    jsr $FF69                   ; 00/2010: 20 69 FF
L002013:
    bbr5 $00,L002016            ; 00/2013: 5F 00 00 ; may also run as rts (60) (self-modifying code)
L002016:
    sta a:$C000                 ; 00/2016: 8D 00 C0
    rts                         ; 00/2019: 60
