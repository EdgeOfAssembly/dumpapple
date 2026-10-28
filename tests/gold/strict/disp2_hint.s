; dumpapple 0.10.0 listing of tests/progs/disp2.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o disp2_hint.o disp2_hint.s
;          ld65 -C disp2_hint.cfg -o disp2_hint.bin disp2_hint.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)
; note: hinted table $002040: 1 entry used by $002007
; note: auto table $002044: 1 entry used by $00200E (stopped: target outside image)
; note: auto table $002048: 1 entry used by $002033 (stopped: limit)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $64
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
    jsr ($2040,x)               ; 00/2007: FC 40 20
    lda z:$00                   ; 00/200A: A5 00
    beq L002011                 ; 00/200C: F0 03
    jmp ($2044,x)               ; 00/200E: 7C 44 20
L002011:
    pea $201F                   ; 00/2011: F4 1F 20
    rts                         ; 00/2014: 60 ; pea+rts dispatch -> $002020
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/2015 hi-ascii "jjjjjjjjjjj"
L002020:
    phk                         ; 00/2020: 4B
    pea $2027                   ; 00/2021: F4 27 20
    rtl                         ; 00/2024: 6B ; phk+pea+rtl dispatch -> $002028
    .byte $EA,$EA,$EA           ; 00/2025
L002028:
    sep #$20                    ; 00/2028: E2 20
    .a8
    lda #$20                    ; 00/202A: A9 20
    pha                         ; 00/202C: 48
    lda #$30                    ; 00/202D: A9 30
    pha                         ; 00/202F: 48
    rts                         ; 00/2030: 60 ; lda#hi/pha/lda#lo/pha+rts dispatch -> $002031
L002031:
    rep #$20                    ; 00/2031: C2 20
    .a16
    jml [$2048]                 ; 00/2033: DC 48 20
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/2036 hi-ascii "jjjjjjjjjj"
D002040:
; jump table (hint): 1 word entry, used by $002007
    .word .loword(L002050)      ; 00/2040 -> $002050
    .byte $58,$20               ; 00/2042
D002044:
; jump table (auto): 1 word entry, used by $00200E, heuristic stopped: target outside image
    .word .loword(L002060)      ; 00/2044 -> $002060
    .byte $EA,$EA               ; 00/2046
D002048:
; jump table (auto): 1 long entry, used by $002033, heuristic stopped: limit
    .faraddr L00205C            ; 00/2048 -> $00205C
    .byte $EA,$EA,$EA,$EA,$EA   ; 00/204B hi-ascii "jjjjj"
L002050:
    lda #$1111                  ; 00/2050: A9 11 11
    rts                         ; 00/2053: 60
    .byte $EA,$EA,$EA,$EA,$A2,$22 ; 00/2054 hi-ascii "jjjj"""
    .byte $22,$60               ; 00/205A
L00205C:
    rts                         ; 00/205C: 60
    .byte $EA,$EA,$EA           ; 00/205D
L002060:
    ldy #$3333                  ; 00/2060: A0 33 33
    rts                         ; 00/2063: 60
