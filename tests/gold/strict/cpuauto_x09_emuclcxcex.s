; dumpapple 0.9.0 listing of tests/cpu_auto/x09_emuclcxcex.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_x09_emuclcxcex.o cpuauto_x09_emuclcxcex.s
;          ld65 -C cpuauto_x09_emuclcxcex.cfg -o cpuauto_x09_emuclcxcex.bin cpuauto_x09_emuclcxcex.o

; cpu: 65816 (auto: 65816-only rep at $2002 on flow from the entry (5 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $11
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
    ldx #$02                    ; 00/2008: A2 02
    stx z:$11                   ; 00/200A: 86 11
    sta z:$10                   ; 00/200C: 85 10
    sep #$30                    ; 00/200E: E2 30
    rts                         ; 00/2010: 60
