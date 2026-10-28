; dumpapple 0.10.0 listing of tests/progs/mvn_reloc.omf
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o mvn_reloc.o mvn_reloc.s
;          ld65 -C mvn_reloc.cfg -o mvn_reloc.bin mvn_reloc.o
; input: OMF v2 load file; output is the relocated loaded image, segments in file order
; note: --strict-smc: seed targets are off (--seed-targets turns them back on)

.setcpu "65816"

; ------------------------------------------------------------
; segment 1 "CODE" load "TEST" kind $0000 org $0 entry +$0
; base $020000 length $40
.segment "SEG1"
.org $020000
entry_020000:
    .a16
    .i16
    ldx #$0020                  ; 02/0000: A2 20 00 [reloc 2@+1 -> seg 1+$20]
    ldy #$0030                  ; 02/0003: A0 30 00
    lda #$0003                  ; 02/0006: A9 03 00
    mvn #$02,#$02               ; 02/0009: 54 02 02 [reloc 1@+1 -> seg 1+$30] >>16 [reloc 1@+2 -> seg 1+$20] >>16
    nop                         ; 02/000C: EA
    rts                         ; 02/000D: 60
    .res 50                     ; 02/000E
