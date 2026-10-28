; dumpapple 0.10.0 listing of tests/progs/r8_brk.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o r8_brk.o r8_brk.s
;          ld65 -C r8_brk.cfg -o r8_brk.bin r8_brk.o
; note: auto table $002005: 1 entry used by $002002 (stopped: target inside the instruction at $00200B)

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $F
.segment "SEG1"
.org $002000
entry_002000:
    ldx #$00                    ; 00/2000: A2 00
    jmp ($2005,x)               ; 00/2002: 7C 05 20
D002005:
; jump table (auto): 1 word entry, used by $002002, heuristic stopped: target inside the instruction at $00200B
    .word .loword(L002009)      ; 00/2005 -> $002009
    .byte $0C,$20               ; 00/2007
L002009:
    lda #$01                    ; 00/2009: A9 01
    .byte $00,$A9               ; 00/200B: 00 A9 brk $A9
    .byte $FF,$60               ; 00/200D
