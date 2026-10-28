; dumpapple 0.10.0 listing of tests/progs/g2w_mvnunk.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o g2w_mvnunk.o g2w_mvnunk.s
;          ld65 -C g2w_mvnunk.cfg -o g2w_mvnunk.bin g2w_mvnunk.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $195
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    jsr .loword(sub_002180)     ; 00/2000: 20 80 21 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte " @ HELLO"            ; 00/2003
    .byte $00,$60               ; 00/200B
    .res 51                     ; 00/200D
    .byte $68,$85,$F0,$68,$85,$F1,$A0,$00 ; 00/2040
    .byte $C8,$B1,$F0,$F0       ; 00/2048 hi-ascii "H1pp"
    .byte $06,$20,$ED,$FD,$4C,$48,$20,$98,$18,$65,$F0,$85,$F0,$A5,$F1,$69 ; 00/204C
    .byte $00,$48,$A5,$F0,$48,$60 ; 00/205C
    .res 286                    ; 00/2062
sub_002180:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $18,$FB,$C2,$30,$AC,$00,$03,$A2,$00,$00,$A9,$0F,$00,$54,$00,$00 ; 00/2180
    .byte $E2,$30,$38,$FB,$60   ; 00/2190
