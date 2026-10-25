; dumpapple 0.9.0 listing of tests/src/hint_h06b_rom_only_guard.bin
; cpu 65c02, platform prodos8
; rebuild: ca65 --cpu 65C02 -t none -o hint_h06b_rom_only_guard.o hint_h06b_rom_only_guard.s
;          ld65 -C hint_h06b_rom_only_guard.cfg -o hint_h06b_rom_only_guard.bin hint_h06b_rom_only_guard.o

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $1C
.segment "SEG1"
.org $002000
entry_002000:
    lda a:$0300                 ; 00/2000: AD 00 03
    beq L00200D                 ; 00/2003: F0 08
    lda #$60                    ; 00/2005: A9 60
    sta a:$2010                 ; 00/2007: 8D 10 20
    jmp .loword(L002010)        ; 00/200A: 4C 10 20
L00200D:
    jsr $FF69                   ; 00/200D: 20 69 FF ; does not return (Apple II ROM $FF69)
L002010:
    nop                         ; 00/2010: EA ; changed by a store before it runs: runs as rts (60) (self-modifying code)
    .byte $8D,$00,$C0,$60,$20,$19 ; 00/2011
    .byte " `L4"                ; 00/2017
    .byte $12                   ; 00/201B
