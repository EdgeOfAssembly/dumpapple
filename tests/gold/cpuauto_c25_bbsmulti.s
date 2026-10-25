; dumpapple 0.9.0 listing of tests/cpu_auto/c25_bbsmulti.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c25_bbsmulti.o cpuauto_c25_bbsmulti.s
;          ld65 -C cpuauto_c25_bbsmulti.cfg -o cpuauto_c25_bbsmulti.bin cpuauto_c25_bbsmulti.o

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $F
.segment "SEG1"
.org $002000
entry_002000:
    lda #$FF                    ; 00/2000: A9 FF
    sta z:$12                   ; 00/2002: 85 12
    bbs7 $12,L002007            ; 00/2004: FF 12 00
L002007:
    ldx #$C2                    ; 00/2007: A2 C2
    bbs7 $12,L00200C            ; 00/2009: FF 12 00
L00200C:
    ldy #$22                    ; 00/200C: A0 22
    rts                         ; 00/200E: 60
