; dumpapple 0.10.0 listing of tests/progs/t6_cop.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o t6_cop.o t6_cop.s
;          ld65 -C t6_cop.cfg -o t6_cop.bin t6_cop.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $5
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    cop $05                     ; 00/2000: 02 05
    lda #$01                    ; 00/2002: A9 01
    rts                         ; 00/2004: 60
