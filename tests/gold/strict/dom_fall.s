; dumpapple 0.10.0 listing of tests/progs/dom_fall.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o dom_fall.o dom_fall.s
;          ld65 -C dom_fall.cfg -o dom_fall.bin dom_fall.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $10
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_00200A)     ; 00/2000: 20 0A 20
    bbr5 $00,$002006            ; 00/2003: 5F 00 00 ; changed by a store before it runs: runs as rts (60) (self-modifying code)
    .byte $8D,$00,$C0,$60       ; 00/2006
sub_00200A:
    lda #$60                    ; 00/200A: A9 60
    sta a:$2003                 ; 00/200C: 8D 03 20
    rts                         ; 00/200F: 60
