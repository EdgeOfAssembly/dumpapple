; dumpapple 0.10.0 listing of tests/cpu_auto/c27_longxjsl.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_c27_longxjsl.o cpuauto_c27_longxjsl.s
;          ld65 -C cpuauto_c27_longxjsl.cfg -o cpuauto_c27_longxjsl.bin cpuauto_c27_longxjsl.o

; cpu: 65816 (auto: 65816-only jsl at $2006 on flow from the entry; --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $B
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    ldx #$00                    ; 00/2000: A2 00
    sta f:$E10000,x             ; 00/2002: 9F 00 00 E1
    jsl f:$E100A8               ; 00/2006: 22 A8 00 E1
    rts                         ; 00/200A: 60
