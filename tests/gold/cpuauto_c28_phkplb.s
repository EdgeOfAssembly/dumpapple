; dumpapple 0.10.0 listing of tests/cpu_auto/c28_phkplb.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_c28_phkplb.o cpuauto_c28_phkplb.s
;          ld65 -C cpuauto_c28_phkplb.cfg -o cpuauto_c28_phkplb.bin cpuauto_c28_phkplb.o

; cpu: 65816 (auto: 65816-only rep at $2002 on flow from the entry (2 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $A
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    phk                         ; 00/2000: 4B
    plb                         ; 00/2001: AB
    rep #$30                    ; 00/2002: C2 30
    lda #$34                    ; 00/2004: A9 34
    ora ($E2)                   ; 00/2006: 12 E2
    bmi $00206A                 ; 00/2008: 30 60
