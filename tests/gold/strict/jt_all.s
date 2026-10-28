; dumpapple 0.10.0 listing of tests/progs/jt.omf
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o jt_all.o jt_all.s
;          ld65 -C jt_all.cfg -o jt_all.bin jt_all.o
; input: OMF v2 load file; output is the relocated loaded image, segments in file order
; note: --strict-smc: seed targets are off (--seed-targets turns them back on)
; note: flow into data at $040012 not followed
; note: flow into data at $040020 not followed

.setcpu "65816"

; ------------------------------------------------------------
; segment 1 "~ExpressLoad" load "TEST" kind $8001 org $0 entry +$0
; base $020000 length $10
.segment "SEG1"
.org $020000
    .byte $A9,$00,$00,$8D,$00,$10,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 02/0000

; ------------------------------------------------------------
; segment 2 "MAIN" load "TEST" kind $0000 org $0 entry +$0
; base $030000 length $9
.segment "SEG2"
.org $030000
entry_030000:
    .a16
    .i16
    jsl sub_040012              ; 03/0000: 22 12 00 04 [reloc inter 3@+1 -> seg 3+$12]
    jsl sub_040020              ; 03/0004: 22 20 00 04 [reloc inter 3@+1 -> seg 3+$20]
    rtl                         ; 03/0008: 6B

; ------------------------------------------------------------
; segment 3 "JUMPTABLE" load "TEST" kind $0002 org $0 entry +$0
; base $040000 length $28
.segment "SEG3"
.org $040000
; OMF jump table header
    .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 04/0000 inline
jt_040008:
; OMF jump table entry -> segment 4 (DYNCODE) + $0
    .word $0000                 ; 04/0008 user ID
    .word $0001                 ; 04/000A load-file number
    .word $0004                 ; 04/000C load-segment number
    .dword $00000000            ; 04/000E segment offset -> entry_050000
    .byte $22,$00,$00,$00       ; 04/0012 JSL to loader (data, unpatched)
jt_040016:
; OMF jump table entry -> segment 4 (DYNCODE) + $6
    .word $0000                 ; 04/0016 user ID
    .word $0001                 ; 04/0018 load-file number
    .word $0004                 ; 04/001A load-segment number
    .dword $00000006            ; 04/001C segment offset -> entry_050006
    .byte $22,$00,$00,$00       ; 04/0020 JSL to loader (data, unpatched)
; OMF jump table end (load-file number 0)
    .byte $00,$00,$00,$00       ; 04/0024 inline

; ------------------------------------------------------------
; segment 4 "DYNCODE" load "TEST" kind $8000 org $0 entry +$0
; base $050000 length $C
.segment "SEG4"
.org $050000
entry_050000:
    .a16
    .i16
    lda #$0001                  ; 05/0000: A9 01 00
    nop                         ; 05/0003: EA
    nop                         ; 05/0004: EA
    rtl                         ; 05/0005: 6B
entry_050006:
    lda #$0002                  ; 05/0006: A9 02 00
    nop                         ; 05/0009: EA
    nop                         ; 05/000A: EA
    rtl                         ; 05/000B: 6B

; labels that do not start a listing line
sub_040012 = $040012
sub_040020 = $040020
