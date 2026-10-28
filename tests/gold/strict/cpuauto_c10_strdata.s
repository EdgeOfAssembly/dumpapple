; dumpapple 0.10.0 listing of tests/cpu_auto/c10_strdata.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o cpuauto_c10_strdata.o cpuauto_c10_strdata.s
;          ld65 -C cpuauto_c10_strdata.cfg -o cpuauto_c10_strdata.bin cpuauto_c10_strdata.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

; cpu: 65C02 (auto: no 65816-only instruction on flow from the entry; --cpu overrides)
.setcpu "65C02"

; ------------------------------------------------------------
; base $002000 length $15
.segment "SEG1"
.org $002000
entry_002000:
    ldx #$00                    ; 00/2000: A2 00
L002002:
    lda a:$200E,x               ; 00/2002: BD 0E 20
    beq L00200D                 ; 00/2005: F0 06
    jsr $FDED                   ; 00/2007: 20 ED FD
    inx                         ; 00/200A: E8
    bne L002002                 ; 00/200B: D0 F5
L00200D:
    rts                         ; 00/200D: 60
    .byte $C2,$30,$E2,$20,$82,$C1,$00 ; 00/200E
