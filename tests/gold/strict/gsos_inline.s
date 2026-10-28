; dumpapple 0.10.0 listing of tests/progs/gsos_inline.bin
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o gsos_inline.o gsos_inline.s
;          ld65 -C gsos_inline.cfg -o gsos_inline.bin gsos_inline.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $29
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    clc                         ; 00/2000: 18
    xce                         ; 00/2001: FB
    rep #$30                    ; 00/2002: C2 30
    .a16
    .i16
    jsl f:$E100A8               ; 00/2004: 22 A8 00 E1 ; returns past 6 inline bytes
; GS/OS inline call number + parameter block pointer after call to $E100A8
    .word $2010                 ; 00/2008 GS/OS call number
    .dword params_002023        ; 00/200A parameter block
    bcs L002021                 ; 00/200E: B0 11
    ldx #$0E03                  ; 00/2010: A2 03 0E
    jsl f:$E10000               ; 00/2013: 22 00 00 E1
    jsl sub_002022              ; 00/2017: 22 22 20 00 ; returns past 3 inline bytes
; inline hint after call to $002022
    .byte $48,$69,$00           ; 00/201B inline
    lda #$0000                  ; 00/201E: A9 00 00
L002021:
    rtl                         ; 00/2021: 6B
sub_002022:
    rtl                         ; 00/2022: 6B
params_002023:
    .byte $02,$00,$00,$00,$00,$00 ; 00/2023
