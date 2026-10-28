; dumpapple 0.10.0 listing of tests/cpu_auto/c14_bbsdesync.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c14_bbsdesync.o cpuauto_c14_bbsdesync.s
;          ld65 -C cpuauto_c14_bbsdesync.cfg -o cpuauto_c14_bbsdesync.bin cpuauto_c14_bbsdesync.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $D
.segment "SEG1"
.org $002000
entry_002000:
    lda #$01                    ; 00/2000: A9 01
    sta z:$10                   ; 00/2002: 85 10
    bbs1 $10,L002007            ; 00/2004: 9F 10 00
L002007:
    lda #$E2                    ; 00/2007: A9 E2
    sta a:$0400                 ; 00/2009: 8D 00 04
    rts                         ; 00/200C: 60
