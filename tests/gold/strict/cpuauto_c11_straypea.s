; dumpapple 0.10.0 listing of tests/cpu_auto/c11_straypea.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c11_straypea.o cpuauto_c11_straypea.s
;          ld65 -C cpuauto_c11_straypea.cfg -o cpuauto_c11_straypea.bin cpuauto_c11_straypea.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

; cpu: 65C02 (auto: only 1 stray 65816-only byte(s) such as pea at $2007 on flow from the entry, no brl/jsl/jml/rtl/rep/sep/clc;xce; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $B
.segment "SEG1"
.org $002000
entry_002000:
    lda #$01                    ; 00/2000: A9 01
    tsb a:$0709                 ; 00/2002: 0C 09 07
    asl z:$0C                   ; 00/2005: 06 0C
; code flow reached here but decoding stopped: undefined 65C02 opcode
    .byte $F4,$01,$02,$60       ; 00/2007
