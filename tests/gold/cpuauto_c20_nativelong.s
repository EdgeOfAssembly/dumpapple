; dumpapple 0.9.0 listing of tests/cpu_auto/c20_nativelong.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_c20_nativelong.o cpuauto_c20_nativelong.s
;          ld65 -C cpuauto_c20_nativelong.cfg -o cpuauto_c20_nativelong.bin cpuauto_c20_nativelong.o
; assumes stores with unknown targets do not modify code
; note: unknown-target stores still count for return frames, CSW and inline helpers: COUT $FDED is not trusted (store through an unresolved pointer (14) at $2006; return to an address that is not a caller's frame (rts dispatch) at $2014)

; cpu: 65816 (auto: 65816-only clc; xce at $2001 on flow from the entry (3 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $15
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    clc                         ; 00/2000: 18
    xce                         ; 00/2001: FB
    rep #$30                    ; 00/2002: C2 30
    .a16
    .i16
    lda [$10]                   ; 00/2004: A7 10
    sta [$14],y                 ; 00/2006: 97 14 ; unknown-target store (assumed not to modify code)
    lda f:$E12000               ; 00/2008: AF 00 20 E1
    sta f:$E12002               ; 00/200C: 8F 02 20 E1
    sep #$30                    ; 00/2010: E2 30
    .a8
    .i8
    sec                         ; 00/2012: 38
    xce                         ; 00/2013: FB
    rts                         ; 00/2014: 60
