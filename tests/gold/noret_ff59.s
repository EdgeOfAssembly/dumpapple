; dumpapple 0.10.0 listing of tests/progs/noret_ff59.bin
; cpu 65c02, platform prodos8
; rebuild: ca65 --cpu 65C02 -t none -o noret_ff59.o noret_ff59.s
;          ld65 -C noret_ff59.cfg -o noret_ff59.bin noret_ff59.o

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $17
.segment "SEG1"
.org $002000
entry_002000:
    lda a:$0300                 ; 00/2000: AD 00 03
    beq L00200D                 ; 00/2003: F0 08
    lda #$60                    ; 00/2005: A9 60
    sta a:$2010                 ; 00/2007: 8D 10 20
    jmp .loword(L002010)        ; 00/200A: 4C 10 20
L00200D:
    jsr $FF59                   ; 00/200D: 20 59 FF ; does not return (Apple II ROM $FF59)
L002010:
    bbr5 $00,$002013            ; 00/2010: 5F 00 00 ; changed by a store before it runs: runs as rts (60) (self-modifying code)
    .byte $8D,$00,$C0,$60       ; 00/2013
