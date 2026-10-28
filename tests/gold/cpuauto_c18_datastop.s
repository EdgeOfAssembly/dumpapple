; dumpapple 0.10.0 listing of tests/cpu_auto/c18_datastop.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c18_datastop.o cpuauto_c18_datastop.s
;          ld65 -C cpuauto_c18_datastop.cfg -o cpuauto_c18_datastop.bin cpuauto_c18_datastop.o

; cpu: 65C02 (auto: only 1 stray 65816-only byte(s) such as mvp at $2004 on flow from the entry, no brl/jsl/jml/rtl/rep/sep/clc;xce; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $12
.segment "SEG1"
.org $002000
entry_002000:
    ror z:$E0                   ; 00/2000: 66 E0
    ora ($02),y                 ; 00/2002: 11 02
; code flow reached here but decoding stopped: undefined 65C02 opcode
    .byte $44,$08,$10,$22,$40,$00,$01,$02,$00,$08,$10,$20,$06,$00 ; 00/2004
