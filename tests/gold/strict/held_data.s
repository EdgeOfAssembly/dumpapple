; dumpapple 0.10.0 listing of tests/progs/held_data.omf
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o held_data.o held_data.s
;          ld65 -C held_data.cfg -o held_data.bin held_data.o
; input: OMF v2 load file; output is the relocated loaded image, segments in file order
; note: --strict-smc: seed targets are off (--seed-targets turns them back on)
; note: relocated pointer at $020030 -> $020023 points into held-back bytes after a call; data pointer, not decoded
; note: suggested hint: inline $023000 z (4 call sites look like strings)

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
    jsr .loword(sub_020020)     ; 02/0009: 20 20 00 [reloc 2@+1 -> seg 1+$20]
    rts                         ; 02/000C: 60
    .byte $60,$00,$00           ; 02/000D
sub_020010:
    jsr $3000                   ; 02/0010: 20 00 30 ; unknown: possible inline data after jsr $023000; see suggested hint
    .byte $41,$42,$00,$60,$00   ; 02/0013
sub_020018:
    jsr $3000                   ; 02/0018: 20 00 30 ; unknown: possible inline data after jsr $023000; see suggested hint
    .byte $43,$44,$00,$60,$00   ; 02/001B
sub_020020:
    jsr $3000                   ; 02/0020: 20 00 30 ; unknown: possible inline data after jsr $023000; see suggested hint
    .byte $45,$46,$00,$60,$00   ; 02/0023
sub_020028:
    jsr $3000                   ; 02/0028: 20 00 30 ; unknown: possible inline data after jsr $023000; see suggested hint
    .byte $47,$48,$00,$60,$00,$23,$00,$00,$00 ; 02/002B [reloc 2@+5 -> seg 1+$23]
