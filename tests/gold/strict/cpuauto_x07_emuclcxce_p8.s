; dumpapple 0.10.0 listing of tests/cpu_auto/x07_emuclcxce.bin
; cpu 65816, platform prodos8
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_x07_emuclcxce_p8.o cpuauto_x07_emuclcxce_p8.s
;          ld65 -C cpuauto_x07_emuclcxce_p8.cfg -o cpuauto_x07_emuclcxce_p8.bin cpuauto_x07_emuclcxce_p8.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

; cpu: 65816 (auto: 65816-only rep at $2002 on flow from the entry (5 such instructions); --cpu overrides)
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
    clc                         ; 00/2004: 18
    xce                         ; 00/2005: FB
    lda #$01                    ; 00/2006: A9 01
    sta z:$00                   ; 00/2008: 85 00
    sep #$30                    ; 00/200A: E2 30
    rts                         ; 00/200C: 60
