; dumpapple 0.9.0 listing of tests/progs/wrap01.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o wrap01.o wrap01.s
;          ld65 -C wrap01.cfg -o wrap01.bin wrap01.o

.setcpu "65816"

; ------------------------------------------------------------
; base $7F0000 length $10000
.segment "SEG1"
.org $7F0000
    .byte $12                   ; 7F/0000
    .a8
    .i8
    rts                         ; 7F/0001: 60
    .byte $EA                   ; 7F/0002
    .res 65517                  ; 7F/0003
entry_7FFFF0:
    nop                         ; 7F/FFF0: EA
    nop                         ; 7F/FFF1: EA
    nop                         ; 7F/FFF2: EA
    nop                         ; 7F/FFF3: EA
    nop                         ; 7F/FFF4: EA
    nop                         ; 7F/FFF5: EA
    nop                         ; 7F/FFF6: EA
    nop                         ; 7F/FFF7: EA
    nop                         ; 7F/FFF8: EA
    nop                         ; 7F/FFF9: EA
    nop                         ; 7F/FFFA: EA
    nop                         ; 7F/FFFB: EA
    bne L7FFFFE                 ; 7F/FFFC: D0 00
L7FFFFE:
    .byte $AD,$34               ; 7F/FFFE: AD 34 12 lda a:$1234 (operand wraps to $7F/0000)
