; dumpapple 0.10.0 listing of tests/cpu_auto/c24_longjsl.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_c24_longjsl.o cpuauto_c24_longjsl.s
;          ld65 -C cpuauto_c24_longjsl.cfg -o cpuauto_c24_longjsl.bin cpuauto_c24_longjsl.o

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
    lda f:$E1C029,x             ; 00/2002: BF 29 C0 E1
    jsl f:$E10000               ; 00/2006: 22 00 00 E1
    rts                         ; 00/200A: 60
