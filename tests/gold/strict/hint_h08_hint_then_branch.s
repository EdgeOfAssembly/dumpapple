; dumpapple 0.10.0 listing of tests/src/hint_h08_hint_then_branch.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o hint_h08_hint_then_branch.o hint_h08_hint_then_branch.s
;          ld65 -C hint_h08_hint_then_branch.cfg -o hint_h08_hint_then_branch.bin hint_h08_hint_then_branch.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $17
.segment "SEG1"
.org $002000
entry_002000:
    lda a:$0301                 ; 00/2000: AD 01 03
    beq L00200A                 ; 00/2003: F0 05
    jsr .loword(sub_002016)     ; 00/2005: 20 16 20 ; does not return (assumed by noreturn hint)
    .byte $80,$07               ; 00/2008
L00200A:
    lda #$60                    ; 00/200A: A9 60
    sta a:$2011                 ; 00/200C: 8D 11 20
    bra L002011                 ; 00/200F: 80 00
L002011:
    nop                         ; 00/2011: EA ; changed by a store before it runs: runs as rts (60) (per noreturn hint) (self-modifying code)
    .byte $8D,$00,$C0,$60       ; 00/2012
sub_002016:
    rts                         ; 00/2016: 60
