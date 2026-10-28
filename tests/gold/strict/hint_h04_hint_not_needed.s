; dumpapple 0.10.0 listing of tests/src/hint_h04_hint_not_needed.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o hint_h04_hint_not_needed.o hint_h04_hint_not_needed.s
;          ld65 -C hint_h04_hint_not_needed.cfg -o hint_h04_hint_not_needed.bin hint_h04_hint_not_needed.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $1A
.segment "SEG1"
.org $002000
entry_002000:
    lda a:$0301                 ; 00/2000: AD 01 03
    beq L002009                 ; 00/2003: F0 04
    jsr .loword(sub_002017)     ; 00/2005: 20 17 20 ; does not return (assumed by noreturn hint)
    .byte $60                   ; 00/2008
L002009:
    lda #$60                    ; 00/2009: A9 60
    sta a:$2012                 ; 00/200B: 8D 12 20
    jsr .loword(sub_002012)     ; 00/200E: 20 12 20
    rts                         ; 00/2011: 60
sub_002012:
    nop                         ; 00/2012: EA ; changed by a store before it runs: runs as rts (60) (self-modifying code)
    .byte $8D,$00,$C0,$60       ; 00/2013
sub_002017:
    jmp $1234                   ; 00/2017: 4C 34 12
