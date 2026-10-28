; dumpapple 0.10.0 listing of tests/src/hint_h06c_hint_then_jmp.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o hint_h06c_hint_then_jmp.o hint_h06c_hint_then_jmp.s
;          ld65 -C hint_h06c_hint_then_jmp.cfg -o hint_h06c_hint_then_jmp.bin hint_h06c_hint_then_jmp.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $19
.segment "SEG1"
.org $002000
entry_002000:
    lda a:$0301                 ; 00/2000: AD 01 03
    beq L00200B                 ; 00/2003: F0 06
    jsr .loword(sub_002018)     ; 00/2005: 20 18 20 ; does not return (assumed by noreturn hint)
    .byte $4C,$13,$20           ; 00/2008
L00200B:
    lda #$60                    ; 00/200B: A9 60
    sta a:$2013                 ; 00/200D: 8D 13 20
    jmp .loword(L002013)        ; 00/2010: 4C 13 20
L002013:
    nop                         ; 00/2013: EA ; changed by a store before it runs: runs as rts (60) (per noreturn hint) (self-modifying code)
    .byte $8D,$00,$C0,$60       ; 00/2014
sub_002018:
    rts                         ; 00/2018: 60
