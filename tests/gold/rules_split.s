; dumpapple 0.10.0 listing of tests/progs/rules_split.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o rules_split.o rules_split.s
;          ld65 -C rules_split.cfg -o rules_split.bin rules_split.o
; note: auto table $002008: 2 entries used by $002002 (stopped: another dispatch site's table starts at $00200C)
; note: auto table $00200C: 2 entries used by $002014 (stopped: target outside image)

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $21
.segment "SEG1"
.org $002000
entry_002000:
    ldx #$00                    ; 00/2000: A2 00
    jmp ($2008,x)               ; 00/2002: 7C 08 20
    .byte $EA,$EA,$EA           ; 00/2005
D002008:
; jump table (auto): 2 word entries, used by $002002, heuristic stopped: another dispatch site's table starts at $00200C
    .word .loword(L002014)      ; 00/2008 -> $002014
    .word .loword(L002018)      ; 00/200A -> $002018
D00200C:
; jump table (auto): 2 word entries, used by $002014, heuristic stopped: target outside image
    .word .loword(L00201C)      ; 00/200C -> $00201C
    .word .loword(L002020)      ; 00/200E -> $002020
    .byte $EA,$EA,$EA,$EA       ; 00/2010 hi-ascii "jjjj"
L002014:
    jmp ($200C,x)               ; 00/2014: 7C 0C 20
    .byte $60                   ; 00/2017
L002018:
    rts                         ; 00/2018: 60
    .byte $00,$00,$00           ; 00/2019
L00201C:
    rts                         ; 00/201C: 60
    .byte $00,$00,$00           ; 00/201D
L002020:
    rts                         ; 00/2020: 60
