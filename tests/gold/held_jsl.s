; dumpapple 0.10.0 listing of tests/progs/held_jsl.omf
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o held_jsl.o held_jsl.s
;          ld65 -C held_jsl.cfg -o held_jsl.bin held_jsl.o
; input: OMF v2 load file; output is the relocated loaded image, segments in file order
; note: suggested hint: inline $023000 z (3 call sites look like strings)

.setcpu "65816"

; ------------------------------------------------------------
; segment 1 "CODE" load "TEST" kind $0000 org $0 entry +$0
; base $020000 length $34
.segment "SEG1"
.org $020000
entry_020000:
    .a16
    .i16
    jsr .loword(sub_020010)     ; 02/0000: 20 10 00 [reloc 2@+1 -> seg 1+$10]
    jsr .loword(sub_020018)     ; 02/0003: 20 18 00 [reloc 2@+1 -> seg 1+$18]
    jsr .loword(sub_020028)     ; 02/0006: 20 28 00 [reloc 2@+1 -> seg 1+$28]
    jsl sub_020023              ; 02/0009: 22 23 00 02 [reloc 3@+1 -> seg 1+$23]
    rts                         ; 02/000D: 60
    .byte $00,$00               ; 02/000E
sub_020010:
    jsr $3000                   ; 02/0010: 20 00 30 ; unknown: possible inline data after jsr $023000; see suggested hint
    .byte $41,$42,$00,$60,$00   ; 02/0013
sub_020018:
    jsr $3000                   ; 02/0018: 20 00 30 ; unknown: possible inline data after jsr $023000; see suggested hint
    .byte $43,$44,$00,$60,$00,$20,$00,$30 ; 02/001B
sub_020023:
    eor z:$46                   ; 02/0023: 45 46
    .byte $00,$60               ; 02/0025: 00 60 brk $60
    .byte $00                   ; 02/0027
sub_020028:
    jsr $3000                   ; 02/0028: 20 00 30 ; unknown: possible inline data after jsr $023000; see suggested hint
    .byte $47,$48,$00,$60,$00,$23,$00,$00,$00 ; 02/002B [reloc 2@+5 -> seg 1+$23]
