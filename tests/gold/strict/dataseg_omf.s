; dumpapple 0.9.0 listing of tests/progs/dataseg.omf
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o dataseg_omf.o dataseg_omf.s
;          ld65 -C dataseg_omf.cfg -o dataseg_omf.bin dataseg_omf.o
; input: OMF v2 load file; output is the relocated loaded image, segments in file order

.setcpu "65816"

; ------------------------------------------------------------
; segment 1 "MAIN" load "" kind $0000 org $0 entry +$0
; base $020000 length $6
.segment "SEG1"
.org $020000
entry_020000:
    .a16
    .i16
    rep #$30                    ; 02/0000: C2 30
    lda #$0001                  ; 02/0002: A9 01 00
    rtl                         ; 02/0005: 6B

; ------------------------------------------------------------
; segment 2 "OTHER" load "" kind $0000 org $0 entry +$0
; base $030000 length $4
.segment "SEG2"
.org $030000
    .byte $A9,$02,$00,$6B       ; 03/0000

; ------------------------------------------------------------
; segment 3 "SHAPES" load "" kind $0001 org $0 entry +$0
; base $040000 length $6
.segment "SEG3"
.org $040000
    .byte $A9,$55,$00,$60,$12,$34 ; 04/0000
