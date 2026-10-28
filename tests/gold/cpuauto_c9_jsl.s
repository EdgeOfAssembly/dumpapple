; dumpapple 0.10.0 listing of tests/cpu_auto/c9_jsl.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_c9_jsl.o cpuauto_c9_jsl.s
;          ld65 -C cpuauto_c9_jsl.cfg -o cpuauto_c9_jsl.bin cpuauto_c9_jsl.o

; cpu: 65816 (auto: 65816-only jsl at $2002 on flow from the entry; --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $7
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    lda #$01                    ; 00/2000: A9 01
    jsl f:$E10000               ; 00/2002: 22 00 00 E1
    rts                         ; 00/2006: 60
