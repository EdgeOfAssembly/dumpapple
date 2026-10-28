; dumpapple 0.10.0 listing of tests/progs/w05.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o w05.o w05.s
;          ld65 -C w05.cfg -o w05.bin w05.o
; assumes stores with unknown targets do not modify code
; note: unknown-target stores still count for return frames, CSW and inline helpers: COUT $FDED is not trusted (store that may reach CSW at $2004; store that may modify code (self-modifying code) at $2004)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $13
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    pla                         ; 00/2000: 68
    tcd                         ; 00/2001: 5B
    lda #$38                    ; 00/2002: A9 38
    sta z:$10                   ; 00/2004: 85 10 ; unknown-target store (assumed not to modify code)
    clc                         ; 00/2006: 18
    xce                         ; 00/2007: FB
    rep #$20                    ; 00/2008: C2 20
    .a16
    lda #$6060                  ; 00/200A: A9 60 60
    lda #$8D00                  ; 00/200D: A9 00 8D
    .byte $00,$C0               ; 00/2010: 00 C0 brk $C0
    .byte $60                   ; 00/2012
