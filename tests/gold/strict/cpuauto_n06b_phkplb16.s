; dumpapple 0.10.0 listing of tests/cpu_auto/n06b_phkplb16.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_n06b_phkplb16.o cpuauto_n06b_phkplb16.s
;          ld65 -C cpuauto_n06b_phkplb16.cfg -o cpuauto_n06b_phkplb16.bin cpuauto_n06b_phkplb16.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

; cpu: 65816 (auto: 65816-only rep at $2002 on flow from the entry (3 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $C
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    phk                         ; 00/2000: 4B
    plb                         ; 00/2001: AB
    rep #$30                    ; 00/2002: C2 30
    lda #$01                    ; 00/2004: A9 01
    .byte $00,$85               ; 00/2006: 00 85 brk $85
    .byte $10,$E2,$30,$60       ; 00/2008
