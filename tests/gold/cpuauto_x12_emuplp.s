; dumpapple 0.9.0 listing of tests/cpu_auto/x12_emuplp.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_x12_emuplp.o cpuauto_x12_emuplp.s
;          ld65 -C cpuauto_x12_emuplp.cfg -o cpuauto_x12_emuplp.bin cpuauto_x12_emuplp.o

; cpu: 65816 (auto: 65816-only rep at $2006 on flow from the entry (4 such instructions); --cpu overrides)
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
    sec                         ; 00/2002: 38
    xce                         ; 00/2003: FB
    php                         ; 00/2004: 08
    plp                         ; 00/2005: 28
    rep #$30                    ; 00/2006: C2 30
    lda #$01                    ; 00/2008: A9 01
    ldx #$02                    ; 00/200A: A2 02
    sta z:$10                   ; 00/200C: 85 10
    sep #$30                    ; 00/200E: E2 30
    rts                         ; 00/2010: 60
