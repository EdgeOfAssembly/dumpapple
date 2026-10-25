; dumpapple 0.9.0 listing of tests/progs/native.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o native.o native.s
;          ld65 -C native.cfg -o native.bin native.o

.setcpu "65816"

; ------------------------------------------------------------
; base $002000 length $70
.segment "SEG1"
.org $002000
entry_002000:
    .a8
    .i8
    clc                         ; 00/2000: 18
    xce                         ; 00/2001: FB
    rep #$30                    ; 00/2002: C2 30
    .a16
    .i16
    lda #$1234                  ; 00/2004: A9 34 12
    ldx #$5678                  ; 00/2007: A2 78 56
    ldy #$0000                  ; 00/200A: A0 00 00
    jsr .loword(sub_002055)     ; 00/200D: 20 55 20
    sep #$20                    ; 00/2010: E2 20
    .a8
    lda #$12                    ; 00/2012: A9 12
    lda z:$00                   ; 00/2014: A5 00
    bne L00201F                 ; 00/2016: D0 07
    rep #$20                    ; 00/2018: C2 20
    .a16
    lda #$BEEF                  ; 00/201A: A9 EF BE
    sep #$20                    ; 00/201D: E2 20
L00201F:
    .a8
    lda #$34                    ; 00/201F: A9 34
    php                         ; 00/2021: 08
    rep #$30                    ; 00/2022: C2 30
    .a16
    lda #$FFFF                  ; 00/2024: A9 FF FF
    plp                         ; 00/2027: 28
    .a8
    lda #$56                    ; 00/2028: A9 56
    jsl sub_00205B              ; 00/202A: 22 5B 20 00
    pea $C0DE                   ; 00/202E: F4 DE C0
    per D002051                 ; 00/2031: 62 1D 00
    mvn #$01,#$02               ; 00/2034: 54 02 01
    mvp #$03,#$04               ; 00/2037: 44 04 03
    brl L00203F                 ; 00/203A: 82 02 00
    .byte $EA,$EA               ; 00/203D
L00203F:
    lda f:$E10000               ; 00/203F: AF 00 00 E1
    sta f:$012345,x             ; 00/2043: 9F 45 23 01
    lda [$10],y                 ; 00/2047: B7 10
    lda ($12,s),y               ; 00/2049: B3 12
    lda $03,s                   ; 00/204B: A3 03
    jml L002062                 ; 00/204D: 5C 62 20 00
D002051:
    .byte $11,$11,$22,$22       ; 00/2051
sub_002055:
    .a16
    rep #$30                    ; 00/2055: C2 30
    lda #$0001                  ; 00/2057: A9 01 00
    rts                         ; 00/205A: 60
sub_00205B:
    .a8
    phb                         ; 00/205B: 8B
    phk                         ; 00/205C: 4B
    plb                         ; 00/205D: AB
    lda #$7F                    ; 00/205E: A9 7F
    plb                         ; 00/2060: AB
    rtl                         ; 00/2061: 6B
L002062:
    sep #$30                    ; 00/2062: E2 30
    .i8
    lda z:$20                   ; 00/2064: A5 20
    beq L00206A                 ; 00/2066: F0 02
    bra L00206C                 ; 00/2068: 80 02
L00206A:
    rep #$20                    ; 00/206A: C2 20
L00206C:
; code flow reached here but decoding stopped: accumulator width unknown (M flag conflict)
    .byte $A9,$21,$43,$DB       ; 00/206C
