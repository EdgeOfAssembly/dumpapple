; dumpapple 0.10.0 listing of tests/progs/mvn.omf
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o mvn_omf.o mvn_omf.s
;          ld65 -C mvn_omf.cfg -o mvn_omf.bin mvn_omf.o
; input: OMF v2 load file; output is the relocated loaded image, segments in file order
; note: --strict-smc: seed targets are off (--seed-targets turns them back on)

.setcpu "65816"

; ------------------------------------------------------------
; segment 1 "MAIN" load "" kind $0000 org $0 entry +$0
; base $020000 length $28
.segment "SEG1"
.org $020000
entry_020000:
    .a16
    .i16
    rep #$30                    ; 02/0000: C2 30 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
    lda #$0003                  ; 02/0002: A9 03 00 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
    ldx #$0020                  ; 02/0005: A2 20 00 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
    ldy #$0024                  ; 02/0008: A0 24 00 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
    mvn #$02,#$02               ; 02/000B: 54 02 02 [reloc 1@+1 -> seg 1+$20] >>16 [reloc 1@+2 -> seg 1+$24] >>16 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $44,$02,$02,$6B       ; 02/000E [reloc 1@+1 -> seg 1+$20] >>16 [reloc 1@+2 -> seg 1+$24] >>16
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$41 ; 02/0012 hi-ascii "jjjjjjjjjjjjjjA"
    .byte $42,$43,$44,$00,$00,$00,$00 ; 02/0021
