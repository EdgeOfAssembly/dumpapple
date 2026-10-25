; dumpapple 0.9.0 listing of tests/progs/g2w_gsdp.bin
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o g2w_gsdp.o g2w_gsdp.s
;          ld65 -C g2w_gsdp.cfg -o g2w_gsdp.bin g2w_gsdp.o

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $185
.segment "SEG1"
.org $002000
entry_002000:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $20,$80,$21,$18,$FB,$C2,$30,$A9,$00,$00,$5B,$E2,$30,$38,$FB ; 00/2000
    .byte " @ HELLO"            ; 00/200F
    .byte $00,$60               ; 00/2017
    .res 39                     ; 00/2019
    .byte $68,$85,$F0,$68,$85,$F1,$A0,$00 ; 00/2040
    .byte $C8,$B1,$F0,$F0       ; 00/2048 hi-ascii "H1pp"
    .byte $06,$20,$ED,$FD,$4C,$48,$20,$98,$18,$65,$F0,$85,$F0,$A5,$F1,$69 ; 00/204C
    .byte $00,$48,$A5,$F0,$48,$60 ; 00/205C
    .res 286                    ; 00/2062
    .byte $A9,$BF,$85,$FE,$60   ; 00/2180
