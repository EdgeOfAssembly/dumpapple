; dumpapple 0.10.0 listing of tests/progs/rts_split.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o rts_split_hint.o rts_split_hint.s
;          ld65 -C rts_split_hint.cfg -o rts_split_hint.bin rts_split_hint.o
; note: table hint at $002018: no jump site found, entry state used
; note: hinted table $002018: 2 entries

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $36
.segment "SEG1"
.org $002000
entry_002000:
    ldx #$01                    ; 00/2000: A2 01
    lda a:$2020,x               ; 00/2002: BD 20 20
    pha                         ; 00/2005: 48
    lda a:$2018,x               ; 00/2006: BD 18 20
    pha                         ; 00/2009: 48
    rts                         ; 00/200A: 60
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 00/200B
D002018:
; jump table (hint): 2 split rts (addr-1) entries, low bytes; high bytes at $002020
    .byte <(L002030-1)          ; 00/2018 -> $002030
    .byte <(L002034-1)          ; 00/2019 -> $002034
    .byte $00,$00,$00,$00,$00,$00 ; 00/201A
D002020:
; jump table (hint): 2 split rts (addr-1) entries, high bytes; low bytes at $002018
    .byte >(L002030-1)          ; 00/2020 -> $002030
    .byte >(L002034-1)          ; 00/2021 -> $002034
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 00/2022
L002030:
    rts                         ; 00/2030: 60
    .byte $00,$00,$00           ; 00/2031
L002034:
    nop                         ; 00/2034: EA
    rts                         ; 00/2035: 60
