; dumpapple 0.9.0 listing of tests/cpu_auto/c30_endbra.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c30_endbra.o cpuauto_c30_endbra.s
;          ld65 -C cpuauto_c30_endbra.cfg -o cpuauto_c30_endbra.bin cpuauto_c30_endbra.o

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $20
.segment "SEG1"
.org $002000
entry_002000:
    bbs7 $10,L002003            ; 00/2000: FF 10 00
L002003:
    lda #$01                    ; 00/2003: A9 01
    bra L00201F                 ; 00/2005: 80 18
    .byte $FB,$C2,$30           ; 00/2007
    .res 21                     ; 00/200A
L00201F:
    rts                         ; 00/201F: 60
