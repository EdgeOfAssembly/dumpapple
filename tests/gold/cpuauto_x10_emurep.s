; dumpapple 0.10.0 listing of tests/cpu_auto/x10_emurep.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_x10_emurep.o cpuauto_x10_emurep.s
;          ld65 -C cpuauto_x10_emurep.cfg -o cpuauto_x10_emurep.bin cpuauto_x10_emurep.o

; cpu: 65816 (auto: 65816-only rep at $2004 on flow from the entry (3 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $F
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    phk                         ; 00/2000: 4B
    plb                         ; 00/2001: AB
    sec                         ; 00/2002: 38
    xce                         ; 00/2003: FB
    rep #$30                    ; 00/2004: C2 30
    lda #$01                    ; 00/2006: A9 01
    ldx #$02                    ; 00/2008: A2 02
    sta z:$10                   ; 00/200A: 85 10
    sep #$30                    ; 00/200C: E2 30
    rts                         ; 00/200E: 60
