; dumpapple 0.10.0 listing of tests/progs/rules_tblload.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o rules_tblload.o rules_tblload.s
;          ld65 -C rules_tblload.cfg -o rules_tblload.bin rules_tblload.o
; note: auto table $002006: 2 entries used by $002000 (stopped: read by a load at $00200A)

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $1C
.segment "SEG1"
.org $002000
entry_002000:
    jmp ($2006,x)               ; 00/2000: 7C 06 20
    .byte $00,$00,$00           ; 00/2003
D002006:
; jump table (auto): 2 word entries, used by $002000, heuristic stopped: read by a load at $00200A
    .word .loword(L00200C)      ; 00/2006 -> $00200C
    .word .loword(L002010)      ; 00/2008 -> $002010
    .byte $14,$20               ; 00/200A
L00200C:
    lda a:$200A                 ; 00/200C: AD 0A 20
    rts                         ; 00/200F: 60
L002010:
    nop                         ; 00/2010: EA
    rts                         ; 00/2011: 60
    .byte $00,$00               ; 00/2012
    .byte "ABCDEFG"             ; 00/2014
    .byte $00                   ; 00/201B
