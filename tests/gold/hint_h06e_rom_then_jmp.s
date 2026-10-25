; dumpapple 0.9.0 listing of tests/src/hint_h06e_rom_then_jmp.bin
; cpu 65c02, platform prodos8
; rebuild: ca65 --cpu 65C02 -t none -o hint_h06e_rom_then_jmp.o hint_h06e_rom_then_jmp.s
;          ld65 -C hint_h06e_rom_then_jmp.cfg -o hint_h06e_rom_then_jmp.bin hint_h06e_rom_then_jmp.o

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $1D
.segment "SEG1"
.org $002000
entry_002000:
    lda a:$0301                 ; 00/2000: AD 01 03
    beq L00200B                 ; 00/2003: F0 06
    jsr $FF69                   ; 00/2005: 20 69 FF ; does not return (Apple II ROM $FF69)
    .byte $4C,$13,$20           ; 00/2008
L00200B:
    lda #$60                    ; 00/200B: A9 60
    sta a:$2013                 ; 00/200D: 8D 13 20
    jmp .loword(L002013)        ; 00/2010: 4C 13 20
L002013:
    nop                         ; 00/2013: EA ; changed by a store before it runs: runs as rts (60) (self-modifying code)
    .byte $8D,$00,$C0,$60,$20,$1C,$20,$60,$60 ; 00/2014
