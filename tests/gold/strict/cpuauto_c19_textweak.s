; dumpapple 0.10.0 listing of tests/cpu_auto/c19_textweak.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c19_textweak.o cpuauto_c19_textweak.s
;          ld65 -C cpuauto_c19_textweak.cfg -o cpuauto_c19_textweak.bin cpuauto_c19_textweak.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $17
.segment "SEG1"
.org $002000
entry_002000:
    jsr $FDED                   ; 00/2000: 20 ED FD
    ora #$EA                    ; 00/2003: 09 EA
; code flow reached here but decoding stopped: undefined 65C02 opcode
    .byte $AB,$BF,$BE,$A5,$CA,$BF,$C1,$EB,$C2,$C3,$C4 ; 00/2005 hi-ascii "+?>%J?AkBCD"
    .byte $0B                   ; 00/2010
    .byte $C5,$C6,$C7,$C8,$C9,$60 ; 00/2011 hi-ascii "EFGHI`"
