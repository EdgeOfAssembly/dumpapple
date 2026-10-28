; dumpapple 0.10.0 listing of tests/progs/disp2.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o entry_state.o entry_state.s
;          ld65 -C entry_state.cfg -o entry_state.bin entry_state.o

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $64
.segment "SEG1"
.org $002000
    .byte $18,$FB,$C2,$30,$A2,$00,$00,$FC,$40,$20,$A5,$00,$F0,$03,$7C,$44 ; 00/2000
    .byte $20,$F4,$1F,$20,$60   ; 00/2010
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$4B ; 00/2015 hi-ascii "jjjjjjjjjjjK"
    .byte $F4,$27,$20,$6B       ; 00/2021
    .byte $EA,$EA,$EA,$E2,$20   ; 00/2025 hi-ascii "jjjb "
    .byte $A9,$20,$48,$A9,$30,$48,$60,$C2,$20,$DC,$48,$20 ; 00/202A
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$50 ; 00/2036 hi-ascii "jjjjjjjjjjP"
    .byte " X ` "               ; 00/2041
    .byte $EA,$EA,$5C,$20,$00   ; 00/2046
    .byte $EA,$EA,$EA,$EA,$EA   ; 00/204B hi-ascii "jjjjj"
entry_002050:
    .a16
    .i16
    lda #$1111                  ; 00/2050: A9 11 11
    rts                         ; 00/2053: 60
    .byte $EA,$EA,$EA,$EA       ; 00/2054 hi-ascii "jjjj"
entry_002058:
    .a8
    .i8
    ldx #$22                    ; 00/2058: A2 22
    jsl f:$EA6060               ; 00/205A: 22 60 60 EA
    nop                         ; 00/205E: EA
    nop                         ; 00/205F: EA
    ldy #$33                    ; 00/2060: A0 33
    and ($60,s),y               ; 00/2062: 33 60
