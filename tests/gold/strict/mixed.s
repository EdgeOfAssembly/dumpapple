; dumpapple 0.10.0 listing of tests/progs/mixed.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o mixed.o mixed.s
;          ld65 -C mixed.cfg -o mixed.bin mixed.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65816"

; ------------------------------------------------------------
; base $008000 length $3C
.segment "SEG1"
.org $008000
entry_008000:
    .a8
    .i8
    clc                         ; 00/8000: 18
    xce                         ; 00/8001: FB
    sep #$20                    ; 00/8002: E2 20
    rep #$10                    ; 00/8004: C2 10
    .i16
    lda #$01                    ; 00/8006: A9 01
    ldx #$1234                  ; 00/8008: A2 34 12
    cpx #$2000                  ; 00/800B: E0 00 20
    bcc L00801D                 ; 00/800E: 90 0D
    rep #$20                    ; 00/8010: C2 20
    .a16
    sep #$10                    ; 00/8012: E2 10
    .i8
    lda #$1234                  ; 00/8014: A9 34 12
    ldx #$12                    ; 00/8017: A2 12
    sep #$20                    ; 00/8019: E2 20
    .a8
    rep #$10                    ; 00/801B: C2 10
L00801D:
    .i16
    ldy #$ABCD                  ; 00/801D: A0 CD AB
    cpy #$0001                  ; 00/8020: C0 01 00
    sec                         ; 00/8023: 38
    xce                         ; 00/8024: FB
    .i8
    lda #$FF                    ; 00/8025: A9 FF
    ldx #$EE                    ; 00/8027: A2 EE
    cmp #$10                    ; 00/8029: C9 10
    bit #$01                    ; 00/802B: 89 01
    and #$0F                    ; 00/802D: 29 0F
    eor #$F0                    ; 00/802F: 49 F0
    adc #$01                    ; 00/8031: 69 01
    sbc #$02                    ; 00/8033: E9 02
    ora #$03                    ; 00/8035: 09 03
    cpx #$04                    ; 00/8037: E0 04
    cpy #$05                    ; 00/8039: C0 05
    rti                         ; 00/803B: 40
