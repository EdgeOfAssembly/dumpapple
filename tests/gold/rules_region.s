; dumpapple 0.10.0 listing of tests/progs/rules_region.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o rules_region.o rules_region.s
;          ld65 -C rules_region.cfg -o rules_region.bin rules_region.o

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $E
.segment "SEG1"
.org $002000
entry_002000:
    ldy #$00                    ; 00/2000: A0 00
L002002:
    lda a:$200E,y               ; 00/2002: B9 0E 20
    sta a:$0280,y               ; 00/2005: 99 80 02
    iny                         ; 00/2008: C8
    bne L002002                 ; 00/2009: D0 F7
    jmp .loword(L000280)        ; 00/200B: 4C 80 02

; ------------------------------------------------------------
; base $000280 length $8
.segment "SEG2"
.org $000280
L000280:
    lda #$C1                    ; 00/0280: A9 C1
    jsr $FDED                   ; 00/0282: 20 ED FD
    jmp .loword(L000280)        ; 00/0285: 4C 80 02
