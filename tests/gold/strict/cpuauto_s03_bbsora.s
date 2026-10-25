; dumpapple 0.9.0 listing of tests/cpu_auto/s03_bbsora.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_s03_bbsora.o cpuauto_s03_bbsora.s
;          ld65 -C cpuauto_s03_bbsora.cfg -o cpuauto_s03_bbsora.bin cpuauto_s03_bbsora.o

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
    ora ($C2,x)                 ; 00/2007: 01 C2
    rts                         ; 00/2009: 60
