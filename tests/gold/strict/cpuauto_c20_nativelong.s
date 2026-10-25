; dumpapple 0.9.0 listing of tests/cpu_auto/c20_nativelong.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o cpuauto_c20_nativelong.o cpuauto_c20_nativelong.s
;          ld65 -C cpuauto_c20_nativelong.cfg -o cpuauto_c20_nativelong.bin cpuauto_c20_nativelong.o

; cpu: 65816 (auto: 65816-only clc; xce at $2001 on flow from the entry (3 such instructions); --cpu overrides)
.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $15
.segment "SEG1"
.org $002000
entry_002000:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $18,$FB,$C2,$30,$A7,$10,$97,$14,$AF,$00,$20,$E1,$8F,$02,$20,$E1 ; 00/2000
    .byte $E2,$30,$38,$FB,$60   ; 00/2010
