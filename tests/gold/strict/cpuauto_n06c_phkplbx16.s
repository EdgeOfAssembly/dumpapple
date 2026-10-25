; dumpapple 0.9.0 listing of tests/cpu_auto/n06c_phkplbx16.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_n06c_phkplbx16.o cpuauto_n06c_phkplbx16.s
;          ld65 -C cpuauto_n06c_phkplbx16.cfg -o cpuauto_n06c_phkplbx16.bin cpuauto_n06c_phkplbx16.o

; cpu: 65816 (auto: 65816-only rep at $2002 on flow from the entry (3 such instructions); --cpu overrides)
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
    rep #$30                    ; 00/2002: C2 30
    ldx #$10                    ; 00/2004: A2 10
    .byte $00,$A0               ; 00/2006: 00 A0 brk $A0
    .byte $00,$00,$E2,$30,$60   ; 00/2008
