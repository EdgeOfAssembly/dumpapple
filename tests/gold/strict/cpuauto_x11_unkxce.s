; dumpapple 0.10.0 listing of tests/cpu_auto/x11_unkxce.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_x11_unkxce.o cpuauto_x11_unkxce.s
;          ld65 -C cpuauto_x11_unkxce.cfg -o cpuauto_x11_unkxce.bin cpuauto_x11_unkxce.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

; cpu: 65816 (auto: 65816-only rep at $2003 on flow from the entry (2 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $D
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    phk                         ; 00/2000: 4B
    plb                         ; 00/2001: AB
    xce                         ; 00/2002: FB
    rep #$30                    ; 00/2003: C2 30
; code flow reached here but decoding stopped: accumulator width unknown (M flag conflict)
    .byte $A9,$01,$00,$85,$10,$E2,$30,$60 ; 00/2005
