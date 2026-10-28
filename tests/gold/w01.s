; dumpapple 0.10.0 listing of tests/progs/w01.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o w01.o w01.s
;          ld65 -C w01.cfg -o w01.bin w01.o
; assumes stores with unknown targets do not modify code
; note: unknown-target stores still count for return frames, CSW and inline helpers: COUT $FDED is not trusted (store that may modify code (self-modifying code) at $2005)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $15
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    ldy a:$0300                 ; 00/2000: AC 00 03
    lda #$38                    ; 00/2003: A9 38
    sta a:$2008,y               ; 00/2005: 99 08 20 ; unknown-target store (assumed not to modify code)
    clc                         ; 00/2008: 18
    xce                         ; 00/2009: FB
    rep #$20                    ; 00/200A: C2 20
    .a16
    lda #$6060                  ; 00/200C: A9 60 60
    lda #$8D00                  ; 00/200F: A9 00 8D
    .byte $00,$C0               ; 00/2012: 00 C0 brk $C0
    .byte $60                   ; 00/2014
