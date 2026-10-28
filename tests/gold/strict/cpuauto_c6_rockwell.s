; dumpapple 0.10.0 listing of tests/cpu_auto/c6_rockwell.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c6_rockwell.o cpuauto_c6_rockwell.s
;          ld65 -C cpuauto_c6_rockwell.cfg -o cpuauto_c6_rockwell.bin cpuauto_c6_rockwell.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $F
.segment "SEG1"
.org $002000
entry_002000:
    rmb0 z:$10                  ; 00/2000: 07 10
    smb7 z:$11                  ; 00/2002: F7 11
    bbr1 $10,L00200A            ; 00/2004: 1F 10 03
    lda a:$1234                 ; 00/2007: AD 34 12
L00200A:
    bbs2 $11,L00200E            ; 00/200A: AF 11 01
    nop                         ; 00/200D: EA
L00200E:
    rts                         ; 00/200E: 60
