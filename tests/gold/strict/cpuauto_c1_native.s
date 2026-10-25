; dumpapple 0.9.0 listing of tests/cpu_auto/c1_native.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_c1_native.o cpuauto_c1_native.s
;          ld65 -C cpuauto_c1_native.cfg -o cpuauto_c1_native.bin cpuauto_c1_native.o

; cpu: 65816 (auto: 65816-only brl at $2000 on flow from the entry (3 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $14
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    brl L00200A                 ; 00/2000: 82 07 00
    .byte $71,$77,$04           ; 00/2003
    .byte "main"                ; 00/2006
L00200A:
    clc                         ; 00/200A: 18
    xce                         ; 00/200B: FB
    rep #$30                    ; 00/200C: C2 30
    .a16
    .i16
    lda #$1234                  ; 00/200E: A9 34 12
    sec                         ; 00/2011: 38
    xce                         ; 00/2012: FB
    .a8
    .i8
    rts                         ; 00/2013: 60
