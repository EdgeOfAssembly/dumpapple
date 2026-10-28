; dumpapple 0.10.0 listing of tests/cpu_auto/s01_bbscpx.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_s01_bbscpx.o cpuauto_s01_bbscpx.s
;          ld65 -C cpuauto_s01_bbscpx.cfg -o cpuauto_s01_bbscpx.bin cpuauto_s01_bbscpx.o

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $C
.segment "SEG1"
.org $002000
entry_002000:
    lda #$80                    ; 00/2000: A9 80
    sta z:$12                   ; 00/2002: 85 12
L002004:
    bbs7 $12,L002007            ; 00/2004: FF 12 00
L002007:
    cpx #$C2                    ; 00/2007: E0 C2
    bne L002004                 ; 00/2009: D0 F9
    rts                         ; 00/200B: 60
