; dumpapple 0.10.0 listing of tests/cpu_auto/c13_three.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_c13_three.o cpuauto_c13_three.s
;          ld65 -C cpuauto_c13_three.cfg -o cpuauto_c13_three.bin cpuauto_c13_three.o

; cpu: 65816 (auto: 65816-only phb at $2000 on flow from the entry (3 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $6
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    phb                         ; 00/2000: 8B
    lda #$01                    ; 00/2001: A9 01
    xba                         ; 00/2003: EB
    plb                         ; 00/2004: AB
    rts                         ; 00/2005: 60
