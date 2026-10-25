; dumpapple 0.9.0 listing of tests/progs/disp.omf
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o disp_omf_notables.o disp_omf_notables.s
;          ld65 -C disp_omf_notables.cfg -o disp_omf_notables.bin disp_omf_notables.o
; input: OMF v2 load file; output is the relocated loaded image, segments in file order

.setcpu "65816"

; ------------------------------------------------------------
; segment 1 "CODE" load "" kind $0000 org $0 entry +$0
; base $020000 length $40
.segment "SEG1"
.org $020000
entry_020000:
    .a16
    .i16
    nop                         ; 02/0000: EA
    nop                         ; 02/0001: EA
    rep #$30                    ; 02/0002: C2 30
    ldx #$0000                  ; 02/0004: A2 00 00
    jmp ($0020,x)               ; 02/0007: 7C 20 00 [reloc 2@+1 -> seg 1+$20]
    .byte $FC,$20,$00,$60,$F4,$27,$00,$60 ; 02/000A [reloc 2@+1 -> seg 1+$20] [reloc 2@+5 -> seg 1+$27]
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 02/0012 hi-ascii "jjjjjjjjjjjjjj"
    .byte $30,$00,$38,$00       ; 02/0020 [reloc 2@+0 -> seg 1+$30] [reloc 2@+2 -> seg 1+$38]
    .byte $EA,$EA,$EA,$EA,$A9,$34 ; 02/0024 hi-ascii "jjjj)4"
    .byte $12,$60               ; 02/002A
    .byte $EA,$EA,$EA,$EA,$A9   ; 02/002C hi-ascii "jjjj)"
    .byte $11,$11,$60           ; 02/0031
    .byte $EA,$EA,$EA,$EA,$A2,$22 ; 02/0034 hi-ascii "jjjj"""
    .byte $22,$60               ; 02/003A
    .byte $EA,$EA,$EA,$EA       ; 02/003C hi-ascii "jjjj"
