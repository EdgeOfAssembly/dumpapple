; dumpapple 0.9.0 listing of tests/progs/gsos.omf
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o gsos_omf_none.o gsos_omf_none.s
;          ld65 -C gsos_omf_none.cfg -o gsos_omf_none.bin gsos_omf_none.o
; input: OMF v2 load file; output is the relocated loaded image, segments in file order

.setcpu "65816"

; ------------------------------------------------------------
; segment 1 "MAIN" load "" kind $0000 org $0 entry +$0
; base $020000 length $18
.segment "SEG1"
.org $020000
entry_020000:
    .a16
    .i16
    rep #$30                    ; 02/0000: C2 30
    jsl f:$E100A8               ; 02/0002: 22 A8 00 E1
    bpl $020028                 ; 02/0006: 10 20
; code flow reached here but decoding stopped: relocation misaligned with operand (likely data, not code)
    .byte $14,$00,$02,$00,$A9,$00,$00,$6B,$00,$00,$00,$00,$02,$00,$00,$00 ; 02/0008 [reloc 3@+0 -> seg 1+$14]
