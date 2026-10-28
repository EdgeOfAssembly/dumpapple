; dumpapple 0.10.0 listing of tests/cpu_auto/s02_bbssbc.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_s02_bbssbc.o cpuauto_s02_bbssbc.s
;          ld65 -C cpuauto_s02_bbssbc.cfg -o cpuauto_s02_bbssbc.bin cpuauto_s02_bbssbc.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $A
.segment "SEG1"
.org $002000
entry_002000:
    lda #$80                    ; 00/2000: A9 80
    sta z:$12                   ; 00/2002: 85 12
    bbs7 $12,L002007            ; 00/2004: FF 12 00
L002007:
    sbc ($E2,x)                 ; 00/2007: E1 E2
    rts                         ; 00/2009: 60
