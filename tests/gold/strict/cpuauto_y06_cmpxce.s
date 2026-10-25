; dumpapple 0.9.0 listing of tests/cpu_auto/y06_cmpxce.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_y06_cmpxce.o cpuauto_y06_cmpxce.s
;          ld65 -C cpuauto_y06_cmpxce.cfg -o cpuauto_y06_cmpxce.bin cpuauto_y06_cmpxce.o

; cpu: 65816 (auto: 65816-only rep at $2008 on flow from the entry (3 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $13
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    phk                         ; 00/2000: 4B
    plb                         ; 00/2001: AB
    sec                         ; 00/2002: 38
    xce                         ; 00/2003: FB
    clc                         ; 00/2004: 18
    cmp #$00                    ; 00/2005: C9 00
    xce                         ; 00/2007: FB
    rep #$30                    ; 00/2008: C2 30
; code flow reached here but decoding stopped: accumulator width unknown (M flag conflict)
    .byte $A9,$01,$A2,$02,$85,$10,$E2,$30,$60 ; 00/200A
