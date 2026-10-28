; dumpapple 0.10.0 listing of tests/cpu_auto/c15_bbrdesync.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c15_bbrdesync.o cpuauto_c15_bbrdesync.s
;          ld65 -C cpuauto_c15_bbrdesync.cfg -o cpuauto_c15_bbrdesync.bin cpuauto_c15_bbrdesync.o

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $E
.segment "SEG1"
.org $002000
entry_002000:
    lda #$00                    ; 00/2000: A9 00
    sta z:$12                   ; 00/2002: 85 12
    bbr0 $12,L002007            ; 00/2004: 0F 12 00
L002007:
    ldx #$C2                    ; 00/2007: A2 C2
    ldy #$E2                    ; 00/2009: A0 E2
    lda #$22                    ; 00/200B: A9 22
    rts                         ; 00/200D: 60
