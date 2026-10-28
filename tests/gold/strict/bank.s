; dumpapple 0.10.0 listing of tests/progs/bank.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o bank.o bank.s
;          ld65 -C bank.cfg -o bank.bin bank.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65816"

; ------------------------------------------------------------
; base $021000 length $46
.segment "SEG1"
.org $021000
; program start
entry_021000:
    .a8
    .i8
    rep #$30                    ; 02/1000: C2 30
    .a16
    .i16
    jsr .loword(sub_02100D)     ; 02/1002: 20 0D 10
    lda #$0002                  ; 02/1005: A9 02 00
    asl a                       ; 02/1008: 0A
    tax                         ; 02/1009: AA
    jmp ($1036,x)               ; 02/100A: 7C 36 10
sub_02100D:
    stz z:$00                   ; 02/100D: 64 00
    stz a:$1234                 ; 02/100F: 9C 34 12
    lda ($10)                   ; 02/1012: B2 10
    lda [$10]                   ; 02/1014: A7 10
    lda ($10,x)                 ; 02/1016: A1 10
    lda ($10),y                 ; 02/1018: B1 10
    lda a:$1234,y               ; 02/101A: B9 34 12
    lda f:$123456               ; 02/101D: AF 56 34 12
    lda f:$123456,x             ; 02/1021: BF 56 34 12
    jsl f:$E10000               ; 02/1025: 22 00 00 E1
    jml [$00F0]                 ; 02/1029: DC F0 00
entry_02102C:
    jmp ($1000)                 ; 02/102C: 6C 00 10
entry_02102F:
    cop $05                     ; 02/102F: 02 05
entry_021031:
    .byte $00,$00               ; 02/1031: 00 00 brk $00
entry_021033:
    .byte $42,$42               ; 02/1033: 42 42 wdm $42
    rts                         ; 02/1035: 60
jtab:
    .word $103C,$103E,$1040     ; 02/1036
handler0:
    inc a                       ; 02/103C: 1A
    rts                         ; 02/103D: 60
entry_02103E:
    dec a                       ; 02/103E: 3A
    rts                         ; 02/103F: 60
entry_021040:
    xba                         ; 02/1040: EB
    tcd                         ; 02/1041: 5B
    tdc                         ; 02/1042: 7B
    txy                         ; 02/1043: 9B
    tyx                         ; 02/1044: BB
    rts                         ; 02/1045: 60
