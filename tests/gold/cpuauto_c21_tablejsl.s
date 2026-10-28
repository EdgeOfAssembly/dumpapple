; dumpapple 0.10.0 listing of tests/cpu_auto/c21_tablejsl.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_c21_tablejsl.o cpuauto_c21_tablejsl.s
;          ld65 -C cpuauto_c21_tablejsl.cfg -o cpuauto_c21_tablejsl.bin cpuauto_c21_tablejsl.o
; note: auto table $002005: 2 entries used by $002002 (stopped: target outside image)

; cpu: 65816 (auto: 65816-only rep at $200A on flow from the entry (2 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $F
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    ldx #$02                    ; 00/2000: A2 02
    jmp ($2005,x)               ; 00/2002: 7C 05 20
D002005:
; jump table (auto): 2 word entries, used by $002002, heuristic stopped: target outside image
    .word .loword(L002009)      ; 00/2005 -> $002009
    .word .loword(L00200A)      ; 00/2007 -> $00200A
L002009:
    rts                         ; 00/2009: 60
L00200A:
    rep #$30                    ; 00/200A: C2 30
    sep #$30                    ; 00/200C: E2 30
    rts                         ; 00/200E: 60
