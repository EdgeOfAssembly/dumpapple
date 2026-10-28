; dumpapple 0.10.0 listing of tests/cpu_auto/x08_xce16.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_x08_xce16.o cpuauto_x08_xce16.s
;          ld65 -C cpuauto_x08_xce16.cfg -o cpuauto_x08_xce16.bin cpuauto_x08_xce16.o

; cpu: 65816 (auto: 65816-only rep at $2002 on flow from the entry (4 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $E
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    phk                         ; 00/2000: 4B
    plb                         ; 00/2001: AB
    rep #$30                    ; 00/2002: C2 30
    clc                         ; 00/2004: 18
    xce                         ; 00/2005: FB
    lda #$01                    ; 00/2006: A9 01
    .byte $00,$85               ; 00/2008: 00 85 brk $85
    .byte $10,$E2,$30,$60       ; 00/200A
