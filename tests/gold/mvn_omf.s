; dumpapple 0.10.0 listing of tests/progs/mvn.omf
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o mvn_omf.o mvn_omf.s
;          ld65 -C mvn_omf.cfg -o mvn_omf.bin mvn_omf.o
; input: OMF v2 load file; output is the relocated loaded image, segments in file order
; assumes stores with unknown targets do not modify code
; note: unknown-target stores still count for return frames, CSW and inline helpers: COUT $FDED is not trusted (store that may modify code (self-modifying code) at $000E)

.setcpu "65816"

; ------------------------------------------------------------
; segment 1 "MAIN" load "" kind $0000 org $0 entry +$0
; base $020000 length $28
.segment "SEG1"
.org $020000
entry_020000:
    .a16
    .i16
    rep #$30                    ; 02/0000: C2 30
    lda #$0003                  ; 02/0002: A9 03 00
    ldx #$0020                  ; 02/0005: A2 20 00
    ldy #$0024                  ; 02/0008: A0 24 00
    mvn #$02,#$02               ; 02/000B: 54 02 02 [reloc 1@+1 -> seg 1+$20] >>16 [reloc 1@+2 -> seg 1+$24] >>16
    mvp #$02,#$02               ; 02/000E: 44 02 02 [reloc 1@+1 -> seg 1+$20] >>16 [reloc 1@+2 -> seg 1+$24] >>16 ; unknown-target store (assumed not to modify code)
    rtl                         ; 02/0011: 6B
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$41 ; 02/0012 hi-ascii "jjjjjjjjjjjjjjA"
    .byte $42,$43,$44,$00,$00,$00,$00 ; 02/0021
