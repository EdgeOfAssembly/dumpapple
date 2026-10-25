; dumpapple 0.9.0 listing of tests/progs/emu.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o emu.o emu.s
;          ld65 -C emu.cfg -o emu.bin emu.o
; note: auto table $00202D: 1 entry used by $00201E (stopped: limit)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $63
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    sei                         ; 00/2000: 78
    cld                         ; 00/2001: D8
    ldx #$FF                    ; 00/2002: A2 FF
    txs                         ; 00/2004: 9A
    lda #$00                    ; 00/2005: A9 00
    sta z:$10                   ; 00/2007: 85 10
    ldy #$00                    ; 00/2009: A0 00
L00200B:
    lda a:$202F,y               ; 00/200B: B9 2F 20
    beq L002016                 ; 00/200E: F0 06
    jsr .loword(sub_002021)     ; 00/2010: 20 21 20
    iny                         ; 00/2013: C8
    bne L00200B                 ; 00/2014: D0 F5
L002016:
    lda #$3C                    ; 00/2016: A9 3C
    sta z:$06                   ; 00/2018: 85 06
    lda #$20                    ; 00/201A: A9 20
    sta z:$07                   ; 00/201C: 85 07
    jmp ($202D)                 ; 00/201E: 6C 2D 20
sub_002021:
    ora #$80                    ; 00/2021: 09 80
    sta a:$C000,x               ; 00/2023: 9D 00 C0
    bit a:$C010                 ; 00/2026: 2C 10 C0
    bvc L00202C                 ; 00/2029: 50 01
    dex                         ; 00/202B: CA
L00202C:
    rts                         ; 00/202C: 60
D00202D:
; jump table (auto): 1 word entry, used by $00201E, heuristic stopped: limit
    .word .loword(entry_002000) ; 00/202D -> $002000
    .byte "HELLO, WORLD"        ; 00/202F
    .byte $00                   ; 00/203B
    .byte $C8,$C9,$A0,$D4,$C8,$C5,$D2,$45 ; 00/203C hi-ascii "HI THERE"
    .byte $01,$02,$03,$04,$05,$22,$5C ; 00/2044
    .res 23                     ; 00/204B
    .byte $FF                   ; 00/2062
