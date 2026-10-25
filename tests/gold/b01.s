; dumpapple 0.9.0 listing of tests/progs/b01.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o b01.o b01.s
;          ld65 -C b01.cfg -o b01.bin b01.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $13
.segment "SEG1"
.org $002000
entry_002000:
    lda a:$0300                 ; 00/2000: AD 00 03
    bpl L00200A                 ; 00/2003: 10 05
    lda #$38                    ; 00/2005: A9 38
    sta a:$200A                 ; 00/2007: 8D 0A 20
L00200A:
    clc                         ; 00/200A: 18 ; may also run as sec (38) (self-modifying code)
    bcc L002010                 ; 00/200B: 90 03
    lda #$01                    ; 00/200D: A9 01
    rts                         ; 00/200F: 60
L002010:
    lda #$02                    ; 00/2010: A9 02
    rts                         ; 00/2012: 60
