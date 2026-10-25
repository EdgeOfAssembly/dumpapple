; dumpapple 0.9.0 listing of tests/progs/mvn.omf
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o mvn_omf.o mvn_omf.s
;          ld65 -C mvn_omf.cfg -o mvn_omf.bin mvn_omf.o
; input: OMF v2 load file; output is the relocated loaded image, segments in file order

.setcpu "65816"

; ------------------------------------------------------------
; segment 1 "MAIN" load "" kind $0000 org $0 entry +$0
; base $020000 length $28
.segment "SEG1"
.org $020000
entry_020000:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $C2,$30,$A9,$03,$00,$A2,$20,$00,$A0,$24,$00,$54,$02,$02,$44,$02 ; 02/0000 [reloc 1@+C -> seg 1+$20] >>16 [reloc 1@+D -> seg 1+$24] >>16 [reloc 1@+F -> seg 1+$20] >>16
    .byte $02,$6B               ; 02/0010 [reloc 1@+0 -> seg 1+$24] >>16
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$41 ; 02/0012 hi-ascii "jjjjjjjjjjjjjjA"
    .byte $42,$43,$44,$00,$00,$00,$00 ; 02/0021
