; dumpapple 0.10.0 listing of tests/progs/g2c_r02.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o g2c_r02.o g2c_r02.s
;          ld65 -C g2c_r02.cfg -o g2c_r02.bin g2c_r02.o
; assumes stores with unknown targets do not modify code
; note: inline-string helper $002300 called at $002019: helper code at $2300 may be changed by the store at $2007 (self-modifying code); bytes after the call left undecoded
; note: unknown-target stores still count for return frames, CSW and inline helpers: COUT $FDED is not trusted (store whose address operand may be modified at $2007; store that may modify code (self-modifying code) at $200D; store that may modify code (self-modifying code) at $2010)

.setcpu "6502"

; ------------------------------------------------------------
; base $002000 length $322
.segment "SEG1"
.org $002000
entry_002000:
    ldx #$01                    ; 00/2000: A2 01
    ldy #$00                    ; 00/2002: A0 00
L002004:
    lda a:$2100,y               ; 00/2004: B9 00 21
    sta a:$2000,y               ; 00/2007: 99 00 20 ; unknown-target store (assumed not to modify code)
    iny                         ; 00/200A: C8
    bne L002004                 ; 00/200B: D0 F7
    inc a:$2006                 ; 00/200D: EE 06 20
    inc a:$2009                 ; 00/2010: EE 09 20
    dex                         ; 00/2013: CA
    beq L002019                 ; 00/2014: F0 03
    jmp .loword(L002004)        ; 00/2016: 4C 04 20
L002019:
    jsr .loword(sub_002300)     ; 00/2019: 20 00 23 ; unknown: inline string after jsr $002300 not proven (helper code at $2300 may be changed by the store at $2007 (self-modifying code))
    .byte "HELLO WORLD"         ; 00/201C
    .byte $00,$60               ; 00/2027
    .res 215                    ; 00/2029
    .byte $A2,$01,$A0,$00,$B9,$00,$21,$99,$00,$20 ; 00/2100
    .byte $C8,$D0,$F7,$EE       ; 00/210A hi-ascii "HPwn"
    .byte $06,$20,$EE,$09,$20,$CA,$F0,$03,$4C,$04,$20,$20,$00 ; 00/210E
    .byte "#HELLO WORLD"        ; 00/211B
    .byte $00,$60               ; 00/2127
    .res 215                    ; 00/2129
    .byte $C8,$60               ; 00/2200
    .res 254                    ; 00/2202
sub_002300:
    pla                         ; 00/2300: 68
    sta z:$F0                   ; 00/2301: 85 F0
    pla                         ; 00/2303: 68
    sta z:$F1                   ; 00/2304: 85 F1
    ldy #$00                    ; 00/2306: A0 00
L002308:
    iny                         ; 00/2308: C8
    lda ($F0),y                 ; 00/2309: B1 F0
    beq L002313                 ; 00/230B: F0 06
    jsr $FDED                   ; 00/230D: 20 ED FD
    jmp .loword(L002308)        ; 00/2310: 4C 08 23
L002313:
    tya                         ; 00/2313: 98
    clc                         ; 00/2314: 18
    adc z:$F0                   ; 00/2315: 65 F0
    sta z:$F0                   ; 00/2317: 85 F0
    lda z:$F1                   ; 00/2319: A5 F1
    adc #$00                    ; 00/231B: 69 00
    pha                         ; 00/231D: 48
    lda z:$F0                   ; 00/231E: A5 F0
    pha                         ; 00/2320: 48
    rts                         ; 00/2321: 60
