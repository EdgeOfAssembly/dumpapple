; dumpapple 0.10.0 listing of tests/progs/rsplit.omf
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o rsplit_omf.o rsplit_omf.s
;          ld65 -C rsplit_omf.cfg -o rsplit_omf.bin rsplit_omf.o
; input: OMF v2 load file; output is the relocated loaded image, segments in file order

.setcpu "65816"

; ------------------------------------------------------------
; segment 1 "DATA" load "" kind $0001 org $0 entry +$0
; base $020000 length $20
.segment "SEG1"
.org $020000
    .byte $01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F ; 02/0000
    .byte $10,$00,$02,$13,$14,$15,$16,$17,$18,$19,$1A,$1B,$1C,$1D,$1E,$1F ; 02/000F [reloc 3@+0 -> seg 1+$10]
    .byte $20                   ; 02/001F
