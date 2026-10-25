; dumpapple 0.9.0 listing of tests/progs/t5_6502push.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o t5_6502push.o t5_6502push.s
;          ld65 -C t5_6502push.cfg -o t5_6502push.bin t5_6502push.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $181
.segment "SEG1"
.org $002000
entry_002000:
    lda #$20                    ; 00/2000: A9 20
    pha                         ; 00/2002: 48
    lda #$06                    ; 00/2003: A9 06
    pha                         ; 00/2005: 48
    rts                         ; 00/2006: 60 ; lda#hi/pha/lda#lo/pha+rts dispatch -> $002007
L002007:
    jmp ($20FF)                 ; 00/2007: 6C FF 20 ; NMOS jmp ($xxFF) page wrap: pointer bytes $0020FF/$002000 -> $00A980
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/200A hi-ascii "jjjjjjjjjjjjjjjj"
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/201A hi-ascii "jjjjjjjjjjjjjjjj"
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/202A hi-ascii "jjjjjjjjjjjjjjjj"
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/203A hi-ascii "jjjjjjjjjjjjjjjj"
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/204A hi-ascii "jjjjjjjjjjjjjjjj"
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/205A hi-ascii "jjjjjjjjjjjjjjjj"
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/206A hi-ascii "jjjjjjjjjjjjjjjj"
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/207A hi-ascii "jjjjjjjjjjjjjjjj"
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/208A hi-ascii "jjjjjjjjjjjjjjjj"
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/209A hi-ascii "jjjjjjjjjjjjjjjj"
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/20AA hi-ascii "jjjjjjjjjjjjjjjj"
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/20BA hi-ascii "jjjjjjjjjjjjjjjj"
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/20CA hi-ascii "jjjjjjjjjjjjjjjj"
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/20DA hi-ascii "jjjjjjjjjjjjjjjj"
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA ; 00/20EA hi-ascii "jjjjjjjjjjjjjjjj"
    .byte $EA,$EA,$EA,$EA,$EA   ; 00/20FA hi-ascii "jjjjj"
    .byte $80,$21               ; 00/20FF
    .res 127                    ; 00/2101
    .byte $60                   ; 00/2180
