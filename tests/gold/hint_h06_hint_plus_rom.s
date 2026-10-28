; dumpapple 0.10.0 listing of tests/src/hint_h06_hint_plus_rom.bin
; cpu 65c02, platform prodos8
; rebuild: ca65 --cpu 65C02 -t none -o hint_h06_hint_plus_rom.o hint_h06_hint_plus_rom.s
;          ld65 -C hint_h06_hint_plus_rom.cfg -o hint_h06_hint_plus_rom.bin hint_h06_hint_plus_rom.o

.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $23
.segment "SEG1"
.org $002000
entry_002000:
    lda a:$0301                 ; 00/2000: AD 01 03
    beq L00200B                 ; 00/2003: F0 06
    jsr .loword(sub_002020)     ; 00/2005: 20 20 20 ; does not return (assumed by noreturn hint)
    .byte $4C,$1B,$20           ; 00/2008
L00200B:
    lda a:$0300                 ; 00/200B: AD 00 03
    beq L002018                 ; 00/200E: F0 08
    lda #$60                    ; 00/2010: A9 60
    sta a:$201B                 ; 00/2012: 8D 1B 20
    jmp .loword(L00201B)        ; 00/2015: 4C 1B 20
L002018:
    jsr $FF69                   ; 00/2018: 20 69 FF ; does not return (Apple II ROM $FF69)
L00201B:
    nop                         ; 00/201B: EA ; changed by a store before it runs: runs as rts (60) (per noreturn hint) (self-modifying code)
    .byte $8D,$00,$C0,$60       ; 00/201C
sub_002020:
    jmp $1234                   ; 00/2020: 4C 34 12
