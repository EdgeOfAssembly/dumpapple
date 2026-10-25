; dumpapple 0.9.0 listing of tests/progs/disp.omf
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o disp_omf.o disp_omf.s
;          ld65 -C disp_omf.cfg -o disp_omf.bin disp_omf.o
; input: OMF v2 load file; output is the relocated loaded image, segments in file order
; note: auto table $020020: 2 entries used by $020007 (stopped: relocation pattern changed)

.setcpu "65816"

; ------------------------------------------------------------
; segment 1 "CODE" load "" kind $0000 org $0 entry +$0
; base $020000 length $40
.segment "SEG1"
.org $020000
entry_020000:
    .a16
    .i16
    nop                         ; 02/0000: EA
    nop                         ; 02/0001: EA
    rep #$30                    ; 02/0002: C2 30
    ldx #$0000                  ; 02/0004: A2 00 00
    jmp ($0020,x)               ; 02/0007: 7C 20 00 [reloc 2@+1 -> seg 1+$20]
    .byte $FC,$20,$00,$60,$F4,$27,$00,$60 ; 02/000A [reloc 2@+1 -> seg 1+$20] [reloc 2@+5 -> seg 1+$27]
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 02/0012 hi-ascii "jjjjjjjjjjjjjj"
D020020:
; jump table (auto): 2 word entries, used by $020007, heuristic stopped: relocation pattern changed
    .word .loword(L020030)      ; 02/0020 -> $020030 [reloc 2@+0 -> seg 1+$30]
    .word .loword(L020038)      ; 02/0022 -> $020038 [reloc 2@+0 -> seg 1+$38]
    .byte $EA,$EA,$EA,$EA,$A9,$34 ; 02/0024 hi-ascii "jjjj)4"
    .byte $12,$60               ; 02/002A
    .byte $EA,$EA,$EA,$EA       ; 02/002C hi-ascii "jjjj"
L020030:
    lda #$1111                  ; 02/0030: A9 11 11
    rts                         ; 02/0033: 60
    .byte $EA,$EA,$EA,$EA       ; 02/0034 hi-ascii "jjjj"
L020038:
    ldx #$2222                  ; 02/0038: A2 22 22
    rts                         ; 02/003B: 60
    .byte $EA,$EA,$EA,$EA       ; 02/003C hi-ascii "jjjj"
