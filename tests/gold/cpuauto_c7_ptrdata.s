; dumpapple 0.9.0 listing of tests/cpu_auto/c7_ptrdata.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c7_ptrdata.o cpuauto_c7_ptrdata.s
;          ld65 -C cpuauto_c7_ptrdata.cfg -o cpuauto_c7_ptrdata.bin cpuauto_c7_ptrdata.o

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $14
.segment "SEG1"
.org $002000
entry_002000:
    lda a:$0300                 ; 00/2000: AD 00 03
    beq L002008                 ; 00/2003: F0 03
    jmp ($0300)                 ; 00/2005: 6C 00 03
L002008:
    rts                         ; 00/2008: 60
    .byte $18,$FB,$C2,$30,$22,$00,$10,$00,$82,$00,$00 ; 00/2009
