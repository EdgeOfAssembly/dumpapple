; dumpapple 0.9.0 listing of tests/src/hint_h05_hint_in_callee.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o hint_h05_hint_in_callee.o hint_h05_hint_in_callee.s
;          ld65 -C hint_h05_hint_in_callee.cfg -o hint_h05_hint_in_callee.bin hint_h05_hint_in_callee.o

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $18
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002008)     ; 00/2000: 20 08 20
    nop                         ; 00/2003: EA ; changed by a store before it runs: runs as rts (60) (per noreturn hint) (self-modifying code)
    .byte $8D,$00,$C0,$60       ; 00/2004
sub_002008:
    lda a:$0300                 ; 00/2008: AD 00 03
    bne L002013                 ; 00/200B: D0 06
    lda #$60                    ; 00/200D: A9 60
    sta a:$2003                 ; 00/200F: 8D 03 20
    rts                         ; 00/2012: 60
L002013:
    jsr .loword(sub_002017)     ; 00/2013: 20 17 20 ; does not return (assumed by noreturn hint)
    .byte $60                   ; 00/2016
sub_002017:
    rts                         ; 00/2017: 60
