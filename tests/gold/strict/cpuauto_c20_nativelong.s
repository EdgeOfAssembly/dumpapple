; dumpapple 0.10.0 listing of tests/cpu_auto/c20_nativelong.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_c20_nativelong.o cpuauto_c20_nativelong.s
;          ld65 -C cpuauto_c20_nativelong.cfg -o cpuauto_c20_nativelong.bin cpuauto_c20_nativelong.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

; cpu: 65816 (auto: 65816-only clc; xce at $2001 on flow from the entry (3 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $15
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    clc                         ; 00/2000: 18 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
    xce                         ; 00/2001: FB ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
    rep #$30                    ; 00/2002: C2 30 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
    lda [$10]                   ; 00/2004: A7 10 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
    sta [$14],y                 ; 00/2006: 97 14 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $AF,$00,$20,$E1,$8F,$02,$20,$E1,$E2,$30,$38,$FB,$60 ; 00/2008
