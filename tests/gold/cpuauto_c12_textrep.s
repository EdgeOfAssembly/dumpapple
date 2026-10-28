; dumpapple 0.10.0 listing of tests/cpu_auto/c12_textrep.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c12_textrep.o cpuauto_c12_textrep.s
;          ld65 -C cpuauto_c12_textrep.cfg -o cpuauto_c12_textrep.bin cpuauto_c12_textrep.o

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $D
.segment "SEG1"
.org $002000
entry_002000:
    lda #$01                    ; 00/2000: A9 01
    cmp ($C2,x)                 ; 00/2002: C1 C2
; code flow reached here but decoding stopped: undefined 65C02 opcode
    .byte $C3,$E2,$C5,$C6,$C7,$C8,$C9,$CA,$60 ; 00/2004 hi-ascii "CbEFGHIJ`"
