; dumpapple 0.10.0 listing of tests/progs/r06.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o r06.o r06.s
;          ld65 -C r06.cfg -o r06.bin r06.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $13
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    clc                         ; 00/2000: 18
    xce                         ; 00/2001: FB
    rep #$20                    ; 00/2002: C2 20
    .a16
    lda #$38EA                  ; 00/2004: A9 EA 38
    sta a:$200C                 ; 00/2007: 8D 0C 20
    sep #$20                    ; 00/200A: E2 20
    .a8
    nop                         ; 00/200C: EA
    clc                         ; 00/200D: 18 ; changed by a store before it runs: runs as sec (38) (self-modifying code)
    bcc $002012                 ; 00/200E: 90 02
    lda #$00                    ; 00/2010: A9 00
    rts                         ; 00/2012: 60
