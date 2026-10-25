; dumpapple 0.9.0 listing of tests/progs/allops_65c02.bin
; cpu 65c02, platform none
; rebuild: ca65 --cpu 65C02 -t none -o allops_65c02.o allops_65c02.s
;          ld65 -C allops_65c02.cfg -o allops_65c02.bin allops_65c02.o
; assumes stores with unknown targets do not modify code
; note: unknown-target stores still count for return frames, CSW and inline helpers: COUT $FDED is not trusted (unresolved indirect jump at $02B9; store that may reach CSW at $0226; store that may reach CSW at $0262; store that may reach CSW at $0298; store that may reach CSW at $02CB; store that may reach CSW at $02CF; store through an unknown address at $02E6; store through an unresolved pointer (12) at $0302; store through an unresolved pointer (12) at $0304; store that may reach CSW at $0306; store that may reach CSW at $0308; store that may reach CSW at $030A; store that may reach CSW at $0381; store that may reach CSW at $03B8; return to an address that is not a caller's frame (rts dispatch) at $0277; return to an address that is not a caller's frame (rts dispatch) at $02AA)

.setcpu "65C02"

; ------------------------------------------------------------
; base $000200 length $1CA
.segment "SEG1"
.org $000200
entry_000200:
    .byte $00,$12               ; 00/0200: 00 12 brk $12
entry_000202:
    ora ($12,x)                 ; 00/0202: 01 12
entry_000204:
    tsb z:$12                   ; 00/0204: 04 12
entry_000206:
    ora z:$12                   ; 00/0206: 05 12
entry_000208:
    asl z:$12                   ; 00/0208: 06 12
entry_00020A:
    rmb0 z:$12                  ; 00/020A: 07 12
entry_00020C:
    php                         ; 00/020C: 08
entry_00020D:
    ora #$12                    ; 00/020D: 09 12
entry_00020F:
    asl a                       ; 00/020F: 0A
entry_000210:
    tsb a:$3412                 ; 00/0210: 0C 12 34
entry_000213:
    ora a:$3412                 ; 00/0213: 0D 12 34
entry_000216:
    asl a:$3412                 ; 00/0216: 0E 12 34
entry_000219:
    bbr0 $12,entry_00021C       ; 00/0219: 0F 12 00
entry_00021C:
    bpl entry_00021E            ; 00/021C: 10 00
entry_00021E:
    ora ($12),y                 ; 00/021E: 11 12
entry_000220:
    ora ($12)                   ; 00/0220: 12 12
entry_000222:
    trb z:$12                   ; 00/0222: 14 12
entry_000224:
    ora z:$12,x                 ; 00/0224: 15 12
entry_000226:
    asl z:$12,x                 ; 00/0226: 16 12
entry_000228:
    rmb1 z:$12                  ; 00/0228: 17 12
entry_00022A:
    clc                         ; 00/022A: 18
entry_00022B:
    ora a:$3412,y               ; 00/022B: 19 12 34
entry_00022E:
    inc a                       ; 00/022E: 1A
entry_00022F:
    trb a:$3412                 ; 00/022F: 1C 12 34
entry_000232:
    ora a:$3412,x               ; 00/0232: 1D 12 34
entry_000235:
    asl a:$3412,x               ; 00/0235: 1E 12 34
entry_000238:
    bbr1 $12,entry_00023B       ; 00/0238: 1F 12 00
entry_00023B:
    jsr $3412                   ; 00/023B: 20 12 34
entry_00023E:
    and ($12,x)                 ; 00/023E: 21 12
entry_000240:
    bit z:$12                   ; 00/0240: 24 12
entry_000242:
    and z:$12                   ; 00/0242: 25 12
entry_000244:
    rol z:$12                   ; 00/0244: 26 12
entry_000246:
    rmb2 z:$12                  ; 00/0246: 27 12
entry_000248:
    plp                         ; 00/0248: 28
entry_000249:
    and #$12                    ; 00/0249: 29 12
entry_00024B:
    rol a                       ; 00/024B: 2A
entry_00024C:
    bit a:$3412                 ; 00/024C: 2C 12 34
entry_00024F:
    and a:$3412                 ; 00/024F: 2D 12 34
entry_000252:
    rol a:$3412                 ; 00/0252: 2E 12 34
entry_000255:
    bbr2 $12,entry_000258       ; 00/0255: 2F 12 00
entry_000258:
    bmi entry_00025A            ; 00/0258: 30 00
entry_00025A:
    and ($12),y                 ; 00/025A: 31 12
entry_00025C:
    and ($12)                   ; 00/025C: 32 12
entry_00025E:
    bit z:$12,x                 ; 00/025E: 34 12
entry_000260:
    and z:$12,x                 ; 00/0260: 35 12
entry_000262:
    rol z:$12,x                 ; 00/0262: 36 12
entry_000264:
    rmb3 z:$12                  ; 00/0264: 37 12
entry_000266:
    sec                         ; 00/0266: 38
entry_000267:
    and a:$3412,y               ; 00/0267: 39 12 34
entry_00026A:
    dec a                       ; 00/026A: 3A
entry_00026B:
    bit a:$3412,x               ; 00/026B: 3C 12 34
entry_00026E:
    and a:$3412,x               ; 00/026E: 3D 12 34
entry_000271:
    rol a:$3412,x               ; 00/0271: 3E 12 34
entry_000274:
    bbr3 $12,entry_000277       ; 00/0274: 3F 12 00
entry_000277:
    rti                         ; 00/0277: 40
entry_000278:
    eor ($12,x)                 ; 00/0278: 41 12
entry_00027A:
    eor z:$12                   ; 00/027A: 45 12
entry_00027C:
    lsr z:$12                   ; 00/027C: 46 12
entry_00027E:
    rmb4 z:$12                  ; 00/027E: 47 12
entry_000280:
    pha                         ; 00/0280: 48
entry_000281:
    eor #$12                    ; 00/0281: 49 12
entry_000283:
    lsr a                       ; 00/0283: 4A
entry_000284:
    jmp $3412                   ; 00/0284: 4C 12 34
entry_000287:
    eor a:$3412                 ; 00/0287: 4D 12 34
entry_00028A:
    lsr a:$3412                 ; 00/028A: 4E 12 34
entry_00028D:
    bbr4 $12,entry_000290       ; 00/028D: 4F 12 00
entry_000290:
    bvc entry_000292            ; 00/0290: 50 00
entry_000292:
    eor ($12),y                 ; 00/0292: 51 12
entry_000294:
    eor ($12)                   ; 00/0294: 52 12
entry_000296:
    eor z:$12,x                 ; 00/0296: 55 12
entry_000298:
    lsr z:$12,x                 ; 00/0298: 56 12
entry_00029A:
    rmb5 z:$12                  ; 00/029A: 57 12
entry_00029C:
    cli                         ; 00/029C: 58
entry_00029D:
    eor a:$3412,y               ; 00/029D: 59 12 34
entry_0002A0:
    phy                         ; 00/02A0: 5A
entry_0002A1:
    eor a:$3412,x               ; 00/02A1: 5D 12 34
entry_0002A4:
    lsr a:$3412,x               ; 00/02A4: 5E 12 34
entry_0002A7:
    bbr5 $12,entry_0002AA       ; 00/02A7: 5F 12 00
entry_0002AA:
    rts                         ; 00/02AA: 60
entry_0002AB:
    adc ($12,x)                 ; 00/02AB: 61 12
entry_0002AD:
    stz z:$12                   ; 00/02AD: 64 12
entry_0002AF:
    adc z:$12                   ; 00/02AF: 65 12
entry_0002B1:
    ror z:$12                   ; 00/02B1: 66 12
entry_0002B3:
    rmb6 z:$12                  ; 00/02B3: 67 12
entry_0002B5:
    pla                         ; 00/02B5: 68
entry_0002B6:
    adc #$12                    ; 00/02B6: 69 12
entry_0002B8:
    ror a                       ; 00/02B8: 6A
entry_0002B9:
    jmp ($3412)                 ; 00/02B9: 6C 12 34
entry_0002BC:
    adc a:$3412                 ; 00/02BC: 6D 12 34
entry_0002BF:
    ror a:$3412                 ; 00/02BF: 6E 12 34
entry_0002C2:
    bbr6 $12,entry_0002C5       ; 00/02C2: 6F 12 00
entry_0002C5:
    bvs entry_0002C7            ; 00/02C5: 70 00
entry_0002C7:
    adc ($12),y                 ; 00/02C7: 71 12
entry_0002C9:
    adc ($12)                   ; 00/02C9: 72 12
entry_0002CB:
    stz z:$12,x                 ; 00/02CB: 74 12
entry_0002CD:
    adc z:$12,x                 ; 00/02CD: 75 12
entry_0002CF:
    ror z:$12,x                 ; 00/02CF: 76 12
entry_0002D1:
    rmb7 z:$12                  ; 00/02D1: 77 12
entry_0002D3:
    sei                         ; 00/02D3: 78
entry_0002D4:
    adc a:$3412,y               ; 00/02D4: 79 12 34
entry_0002D7:
    ply                         ; 00/02D7: 7A
entry_0002D8:
    jmp ($3412,x)               ; 00/02D8: 7C 12 34
entry_0002DB:
    adc a:$3412,x               ; 00/02DB: 7D 12 34
entry_0002DE:
    ror a:$3412,x               ; 00/02DE: 7E 12 34
entry_0002E1:
    bbr7 $12,entry_0002E4       ; 00/02E1: 7F 12 00
entry_0002E4:
    bra entry_0002E6            ; 00/02E4: 80 00
entry_0002E6:
    sta ($12,x)                 ; 00/02E6: 81 12 ; unknown-target store (assumed not to modify code)
entry_0002E8:
    sty z:$12                   ; 00/02E8: 84 12
entry_0002EA:
    sta z:$12                   ; 00/02EA: 85 12
entry_0002EC:
    stx z:$12                   ; 00/02EC: 86 12
entry_0002EE:
    smb0 z:$12                  ; 00/02EE: 87 12
entry_0002F0:
    dey                         ; 00/02F0: 88
entry_0002F1:
    bit #$12                    ; 00/02F1: 89 12
entry_0002F3:
    txa                         ; 00/02F3: 8A
entry_0002F4:
    sty a:$3412                 ; 00/02F4: 8C 12 34
entry_0002F7:
    sta a:$3412                 ; 00/02F7: 8D 12 34
entry_0002FA:
    stx a:$3412                 ; 00/02FA: 8E 12 34
entry_0002FD:
    bbs0 $12,entry_000300       ; 00/02FD: 8F 12 00
entry_000300:
    bcc entry_000302            ; 00/0300: 90 00
entry_000302:
    sta ($12),y                 ; 00/0302: 91 12 ; unknown-target store (assumed not to modify code)
entry_000304:
    sta ($12)                   ; 00/0304: 92 12 ; unknown-target store (assumed not to modify code)
entry_000306:
    sty z:$12,x                 ; 00/0306: 94 12
entry_000308:
    sta z:$12,x                 ; 00/0308: 95 12
entry_00030A:
    stx z:$12,y                 ; 00/030A: 96 12
entry_00030C:
    smb1 z:$12                  ; 00/030C: 97 12
entry_00030E:
    tya                         ; 00/030E: 98
entry_00030F:
    sta a:$3412,y               ; 00/030F: 99 12 34
entry_000312:
    txs                         ; 00/0312: 9A
entry_000313:
    stz a:$3412                 ; 00/0313: 9C 12 34
entry_000316:
    sta a:$3412,x               ; 00/0316: 9D 12 34
entry_000319:
    stz a:$3412,x               ; 00/0319: 9E 12 34
entry_00031C:
    bbs1 $12,entry_00031F       ; 00/031C: 9F 12 00
entry_00031F:
    ldy #$12                    ; 00/031F: A0 12
entry_000321:
    lda ($12,x)                 ; 00/0321: A1 12
entry_000323:
    ldx #$12                    ; 00/0323: A2 12
entry_000325:
    ldy z:$12                   ; 00/0325: A4 12
entry_000327:
    lda z:$12                   ; 00/0327: A5 12
entry_000329:
    ldx z:$12                   ; 00/0329: A6 12
entry_00032B:
    smb2 z:$12                  ; 00/032B: A7 12
entry_00032D:
    tay                         ; 00/032D: A8
entry_00032E:
    lda #$12                    ; 00/032E: A9 12
entry_000330:
    tax                         ; 00/0330: AA
entry_000331:
    ldy a:$3412                 ; 00/0331: AC 12 34
entry_000334:
    lda a:$3412                 ; 00/0334: AD 12 34
entry_000337:
    ldx a:$3412                 ; 00/0337: AE 12 34
entry_00033A:
    bbs2 $12,entry_00033D       ; 00/033A: AF 12 00
entry_00033D:
    bcs entry_00033F            ; 00/033D: B0 00
entry_00033F:
    lda ($12),y                 ; 00/033F: B1 12
entry_000341:
    lda ($12)                   ; 00/0341: B2 12
entry_000343:
    ldy z:$12,x                 ; 00/0343: B4 12
entry_000345:
    lda z:$12,x                 ; 00/0345: B5 12
entry_000347:
    ldx z:$12,y                 ; 00/0347: B6 12
entry_000349:
    smb3 z:$12                  ; 00/0349: B7 12
entry_00034B:
    clv                         ; 00/034B: B8
entry_00034C:
    lda a:$3412,y               ; 00/034C: B9 12 34
entry_00034F:
    tsx                         ; 00/034F: BA
entry_000350:
    ldy a:$3412,x               ; 00/0350: BC 12 34
entry_000353:
    lda a:$3412,x               ; 00/0353: BD 12 34
entry_000356:
    ldx a:$3412,y               ; 00/0356: BE 12 34
entry_000359:
    bbs3 $12,entry_00035C       ; 00/0359: BF 12 00
entry_00035C:
    cpy #$12                    ; 00/035C: C0 12
entry_00035E:
    cmp ($12,x)                 ; 00/035E: C1 12
entry_000360:
    cpy z:$12                   ; 00/0360: C4 12
entry_000362:
    cmp z:$12                   ; 00/0362: C5 12
entry_000364:
    dec z:$12                   ; 00/0364: C6 12
entry_000366:
    smb4 z:$12                  ; 00/0366: C7 12
entry_000368:
    iny                         ; 00/0368: C8
entry_000369:
    cmp #$12                    ; 00/0369: C9 12
entry_00036B:
    dex                         ; 00/036B: CA
entry_00036C:
    wai                         ; 00/036C: CB
entry_00036D:
    cpy a:$3412                 ; 00/036D: CC 12 34
entry_000370:
    cmp a:$3412                 ; 00/0370: CD 12 34
entry_000373:
    dec a:$3412                 ; 00/0373: CE 12 34
entry_000376:
    bbs4 $12,entry_000379       ; 00/0376: CF 12 00
entry_000379:
    bne entry_00037B            ; 00/0379: D0 00
entry_00037B:
    cmp ($12),y                 ; 00/037B: D1 12
entry_00037D:
    cmp ($12)                   ; 00/037D: D2 12
entry_00037F:
    cmp z:$12,x                 ; 00/037F: D5 12
entry_000381:
    dec z:$12,x                 ; 00/0381: D6 12
entry_000383:
    smb5 z:$12                  ; 00/0383: D7 12
entry_000385:
    cld                         ; 00/0385: D8
entry_000386:
    cmp a:$3412,y               ; 00/0386: D9 12 34
entry_000389:
    phx                         ; 00/0389: DA
entry_00038A:
    stp                         ; 00/038A: DB
entry_00038B:
    cmp a:$3412,x               ; 00/038B: DD 12 34
entry_00038E:
    dec a:$3412,x               ; 00/038E: DE 12 34
entry_000391:
    bbs5 $12,entry_000394       ; 00/0391: DF 12 00
entry_000394:
    cpx #$12                    ; 00/0394: E0 12
entry_000396:
    sbc ($12,x)                 ; 00/0396: E1 12
entry_000398:
    cpx z:$12                   ; 00/0398: E4 12
entry_00039A:
    sbc z:$12                   ; 00/039A: E5 12
entry_00039C:
    inc z:$12                   ; 00/039C: E6 12
entry_00039E:
    smb6 z:$12                  ; 00/039E: E7 12
entry_0003A0:
    inx                         ; 00/03A0: E8
entry_0003A1:
    sbc #$12                    ; 00/03A1: E9 12
entry_0003A3:
    nop                         ; 00/03A3: EA
entry_0003A4:
    cpx a:$3412                 ; 00/03A4: EC 12 34
entry_0003A7:
    sbc a:$3412                 ; 00/03A7: ED 12 34
entry_0003AA:
    inc a:$3412                 ; 00/03AA: EE 12 34
entry_0003AD:
    bbs6 $12,entry_0003B0       ; 00/03AD: EF 12 00
entry_0003B0:
    beq entry_0003B2            ; 00/03B0: F0 00
entry_0003B2:
    sbc ($12),y                 ; 00/03B2: F1 12
entry_0003B4:
    sbc ($12)                   ; 00/03B4: F2 12
entry_0003B6:
    sbc z:$12,x                 ; 00/03B6: F5 12
entry_0003B8:
    inc z:$12,x                 ; 00/03B8: F6 12
entry_0003BA:
    smb7 z:$12                  ; 00/03BA: F7 12
entry_0003BC:
    sed                         ; 00/03BC: F8
entry_0003BD:
    sbc a:$3412,y               ; 00/03BD: F9 12 34
entry_0003C0:
    plx                         ; 00/03C0: FA
entry_0003C1:
    sbc a:$3412,x               ; 00/03C1: FD 12 34
entry_0003C4:
    inc a:$3412,x               ; 00/03C4: FE 12 34
entry_0003C7:
    bbs7 $12,$0003CA            ; 00/03C7: FF 12 00
