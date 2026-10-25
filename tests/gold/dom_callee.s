; dumpapple 0.9.0 listing of tests/progs/dom_callee.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o dom_callee.o dom_callee.s
;          ld65 -C dom_callee.cfg -o dom_callee.bin dom_callee.o

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $13
.segment "SEG1"
.org $002000
entry_002000:
    jsr .loword(sub_002006)     ; 00/2000: 20 06 20
    jmp .loword(L00200C)        ; 00/2003: 4C 0C 20
sub_002006:
    lda #$60                    ; 00/2006: A9 60
    sta a:$200C                 ; 00/2008: 8D 0C 20
    rts                         ; 00/200B: 60
L00200C:
    bbr5 $00,$00200F            ; 00/200C: 5F 00 00 ; changed by a store before it runs: runs as rts (60) (self-modifying code)
    .byte $8D,$00,$C0,$60       ; 00/200F
