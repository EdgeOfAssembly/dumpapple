; dumpapple 0.9.0 listing of tests/progs/gsos.omf
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o gsos_omf.o gsos_omf.s
;          ld65 -C gsos_omf.cfg -o gsos_omf.bin gsos_omf.o
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
    jsl f:$E100A8               ; 02/0002: 22 A8 00 E1 ; returns past 6 inline bytes
; GS/OS inline call number + parameter block pointer after call to $E100A8
    .word $2010                 ; 02/0006 GS/OS call number
    .dword params_020014        ; 02/0008 parameter block [reloc 3@+0 -> seg 1+$14]
    lda #$0000                  ; 02/000C: A9 00 00
    rtl                         ; 02/000F: 6B
    .byte $00,$00,$00,$00       ; 02/0010
params_020014:
    .byte $02,$00,$00,$00       ; 02/0014
