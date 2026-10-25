; dumpapple 0.9.0 listing of tests/cpu_auto/d02_phbrep16.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_d02_phbrep16.o cpuauto_d02_phbrep16.s
;          ld65 -C cpuauto_d02_phbrep16.cfg -o cpuauto_d02_phbrep16.bin cpuauto_d02_phbrep16.o

; cpu: 65816 (auto: 65816-only rep at $2003 on flow from the entry (4 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $E
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    phb                         ; 00/2000: 8B
    phk                         ; 00/2001: 4B
    plb                         ; 00/2002: AB
    rep #$10                    ; 00/2003: C2 10
    ldx #$00                    ; 00/2005: A2 00
    .byte $00,$A9               ; 00/2007: 00 A9 brk $A9
    .byte $00,$E2,$10,$AB,$60   ; 00/2009
