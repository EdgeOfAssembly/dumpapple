; dumpapple 0.10.0 listing of tests/cpu_auto/c17_midjump.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c17_midjump.o cpuauto_c17_midjump.s
;          ld65 -C cpuauto_c17_midjump.cfg -o cpuauto_c17_midjump.bin cpuauto_c17_midjump.o

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $C
.segment "SEG1"
.org $002000
entry_002000:
    ldx a:$0300                 ; 00/2000: AE 00 03
    bne L002006                 ; 00/2003: D0 01
    sta z:$82                   ; 00/2005: 85 82
    stx z:$83                   ; 00/2007: 86 83
    lda #$A2                    ; 00/2009: A9 A2
    rts                         ; 00/200B: 60

; labels that do not start a listing line
L002006 = $002006
