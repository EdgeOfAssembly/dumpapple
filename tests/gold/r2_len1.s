; dumpapple 0.10.0 listing of tests/progs/r2_len1.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o r2_len1.o r2_len1.s
;          ld65 -C r2_len1.cfg -o r2_len1.bin r2_len1.o
; note: auto table $00200B: 1 entry used by $00200A (stopped: index guard)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $13
.segment "SEG1"
.org $002000
entry_002000:
    ldx #$00                    ; 00/2000: A2 00
    lda a:$200C,x               ; 00/2002: BD 0C 20
    pha                         ; 00/2005: 48
    lda a:$200B,x               ; 00/2006: BD 0B 20
    pha                         ; 00/2009: 48
    rts                         ; 00/200A: 60 ; rts dispatch through table $00200B
D00200B:
; jump table (auto): 1 rts (addr-1) entry, used by $00200A, heuristic stopped: index guard
    .word .loword(L00200F-1)    ; 00/200B -> $00200F
    .byte $0F,$20               ; 00/200D
L00200F:
    rts                         ; 00/200F: 60
    .byte $A9,$EA,$60           ; 00/2010
