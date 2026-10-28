; dumpapple 0.10.0 listing of tests/progs/disp.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o disp.o disp.s
;          ld65 -C disp.cfg -o disp.bin disp.o
; note: auto table $002020: 2 entries used by $002007 (stopped: target outside image)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $40
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    clc                         ; 00/2000: 18
    xce                         ; 00/2001: FB
    rep #$30                    ; 00/2002: C2 30
    .a16
    .i16
    ldx #$0000                  ; 00/2004: A2 00 00
    jmp ($2020,x)               ; 00/2007: 7C 20 20
    .byte $FC,$20,$20,$60,$F4,$27,$20,$60 ; 00/200A
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/2012 hi-ascii "jjjjjjjjjjjjjj"
D002020:
; jump table (auto): 2 word entries, used by $002007, heuristic stopped: target outside image
    .word .loword(L002030)      ; 00/2020 -> $002030
    .word .loword(L002038)      ; 00/2022 -> $002038
    .byte $EA,$EA,$EA,$EA,$A9,$34 ; 00/2024 hi-ascii "jjjj)4"
    .byte $12,$60               ; 00/202A
    .byte $EA,$EA,$EA,$EA       ; 00/202C hi-ascii "jjjj"
L002030:
    lda #$1111                  ; 00/2030: A9 11 11
    rts                         ; 00/2033: 60
    .byte $EA,$EA,$EA,$EA       ; 00/2034 hi-ascii "jjjj"
L002038:
    ldx #$2222                  ; 00/2038: A2 22 22
    rts                         ; 00/203B: 60
    .byte $EA,$EA,$EA,$EA       ; 00/203C hi-ascii "jjjj"
