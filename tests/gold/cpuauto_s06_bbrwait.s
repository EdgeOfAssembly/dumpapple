; dumpapple 0.10.0 listing of tests/cpu_auto/s06_bbrwait.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_s06_bbrwait.o cpuauto_s06_bbrwait.s
;          ld65 -C cpuauto_s06_bbrwait.cfg -o cpuauto_s06_bbrwait.bin cpuauto_s06_bbrwait.o

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $8
.segment "SEG1"
.org $002000
entry_002000:
    bbr7 $C0,entry_002000       ; 00/2000: 7F C0 FD
    cpx #$E2                    ; 00/2003: E0 E2
    beq entry_002000            ; 00/2005: F0 F9
    rts                         ; 00/2007: 60
