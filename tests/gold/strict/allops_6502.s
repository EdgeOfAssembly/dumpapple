; dumpapple 0.10.0 listing of tests/progs/allops_6502.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o allops_6502.o allops_6502.s
;          ld65 -C allops_6502.cfg -o allops_6502.bin allops_6502.o
; note: --strict-smc: seed targets and auto regions are off (--seed-targets / --auto-region turn them back on)

.setcpu "6502"

; ------------------------------------------------------------
; base $000200 length $142
.segment "SEG1"
.org $000200
entry_000200:
    .byte $00,$12               ; 00/0200: 00 12 brk $12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000202:
    ora ($12,x)                 ; 00/0202: 01 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000204:
    ora z:$12                   ; 00/0204: 05 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000206:
    asl z:$12                   ; 00/0206: 06 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000208:
    php                         ; 00/0208: 08 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000209:
    ora #$12                    ; 00/0209: 09 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00020B:
    asl a                       ; 00/020B: 0A ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00020C:
    ora a:$3412                 ; 00/020C: 0D 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00020F:
    asl a:$3412                 ; 00/020F: 0E 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000212:
    bpl entry_000214            ; 00/0212: 10 00 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000214:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $11,$12               ; 00/0214
entry_000216:
    ora z:$12,x                 ; 00/0216: 15 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000218:
    asl z:$12,x                 ; 00/0218: 16 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00021A:
    clc                         ; 00/021A: 18 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00021B:
    ora a:$3412,y               ; 00/021B: 19 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00021E:
    ora a:$3412,x               ; 00/021E: 1D 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000221:
    asl a:$3412,x               ; 00/0221: 1E 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000224:
    jsr $3412                   ; 00/0224: 20 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000227:
    and ($12,x)                 ; 00/0227: 21 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000229:
    bit z:$12                   ; 00/0229: 24 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00022B:
    and z:$12                   ; 00/022B: 25 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00022D:
    rol z:$12                   ; 00/022D: 26 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00022F:
    plp                         ; 00/022F: 28 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000230:
    and #$12                    ; 00/0230: 29 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000232:
    rol a                       ; 00/0232: 2A ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000233:
    bit a:$3412                 ; 00/0233: 2C 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000236:
    and a:$3412                 ; 00/0236: 2D 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000239:
    rol a:$3412                 ; 00/0239: 2E 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00023C:
    bmi entry_00023E            ; 00/023C: 30 00 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00023E:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $31,$12               ; 00/023E
entry_000240:
    and z:$12,x                 ; 00/0240: 35 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000242:
    rol z:$12,x                 ; 00/0242: 36 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000244:
    sec                         ; 00/0244: 38 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000245:
    and a:$3412,y               ; 00/0245: 39 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000248:
    and a:$3412,x               ; 00/0248: 3D 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00024B:
    rol a:$3412,x               ; 00/024B: 3E 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00024E:
    rti                         ; 00/024E: 40 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00024F:
    eor ($12,x)                 ; 00/024F: 41 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000251:
    eor z:$12                   ; 00/0251: 45 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000253:
    lsr z:$12                   ; 00/0253: 46 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000255:
    pha                         ; 00/0255: 48 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000256:
    eor #$12                    ; 00/0256: 49 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000258:
    lsr a                       ; 00/0258: 4A ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000259:
    jmp $3412                   ; 00/0259: 4C 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00025C:
    eor a:$3412                 ; 00/025C: 4D 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00025F:
    lsr a:$3412                 ; 00/025F: 4E 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000262:
    bvc entry_000264            ; 00/0262: 50 00 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000264:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $51,$12               ; 00/0264
entry_000266:
    eor z:$12,x                 ; 00/0266: 55 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000268:
    lsr z:$12,x                 ; 00/0268: 56 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00026A:
    cli                         ; 00/026A: 58 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00026B:
    eor a:$3412,y               ; 00/026B: 59 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00026E:
    eor a:$3412,x               ; 00/026E: 5D 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000271:
    lsr a:$3412,x               ; 00/0271: 5E 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000274:
    rts                         ; 00/0274: 60 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000275:
    adc ($12,x)                 ; 00/0275: 61 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000277:
    adc z:$12                   ; 00/0277: 65 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000279:
    ror z:$12                   ; 00/0279: 66 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00027B:
    pla                         ; 00/027B: 68 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00027C:
    adc #$12                    ; 00/027C: 69 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00027E:
    ror a                       ; 00/027E: 6A ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00027F:
    jmp ($3412)                 ; 00/027F: 6C 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000282:
    adc a:$3412                 ; 00/0282: 6D 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000285:
    ror a:$3412                 ; 00/0285: 6E 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000288:
    bvs entry_00028A            ; 00/0288: 70 00 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00028A:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $71,$12               ; 00/028A
entry_00028C:
    adc z:$12,x                 ; 00/028C: 75 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00028E:
    ror z:$12,x                 ; 00/028E: 76 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000290:
    sei                         ; 00/0290: 78 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000291:
    adc a:$3412,y               ; 00/0291: 79 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000294:
    adc a:$3412,x               ; 00/0294: 7D 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000297:
    ror a:$3412,x               ; 00/0297: 7E 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00029A:
    sta ($12,x)                 ; 00/029A: 81 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00029C:
    sty z:$12                   ; 00/029C: 84 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00029E:
    sta z:$12                   ; 00/029E: 85 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002A0:
    stx z:$12                   ; 00/02A0: 86 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002A2:
    dey                         ; 00/02A2: 88 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002A3:
    txa                         ; 00/02A3: 8A ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002A4:
    sty a:$3412                 ; 00/02A4: 8C 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002A7:
    sta a:$3412                 ; 00/02A7: 8D 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002AA:
    stx a:$3412                 ; 00/02AA: 8E 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002AD:
    bcc entry_0002AF            ; 00/02AD: 90 00 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002AF:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $91,$12               ; 00/02AF
entry_0002B1:
    sty z:$12,x                 ; 00/02B1: 94 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002B3:
    sta z:$12,x                 ; 00/02B3: 95 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002B5:
    stx z:$12,y                 ; 00/02B5: 96 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002B7:
    tya                         ; 00/02B7: 98 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002B8:
    sta a:$3412,y               ; 00/02B8: 99 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002BB:
    txs                         ; 00/02BB: 9A ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002BC:
    sta a:$3412,x               ; 00/02BC: 9D 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002BF:
    ldy #$12                    ; 00/02BF: A0 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002C1:
    lda ($12,x)                 ; 00/02C1: A1 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002C3:
    ldx #$12                    ; 00/02C3: A2 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002C5:
    ldy z:$12                   ; 00/02C5: A4 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002C7:
    lda z:$12                   ; 00/02C7: A5 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002C9:
    ldx z:$12                   ; 00/02C9: A6 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002CB:
    tay                         ; 00/02CB: A8 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002CC:
    lda #$12                    ; 00/02CC: A9 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002CE:
    tax                         ; 00/02CE: AA ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002CF:
    ldy a:$3412                 ; 00/02CF: AC 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002D2:
    lda a:$3412                 ; 00/02D2: AD 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002D5:
    ldx a:$3412                 ; 00/02D5: AE 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002D8:
    bcs entry_0002DA            ; 00/02D8: B0 00 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002DA:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $B1,$12               ; 00/02DA
entry_0002DC:
    ldy z:$12,x                 ; 00/02DC: B4 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002DE:
    lda z:$12,x                 ; 00/02DE: B5 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002E0:
    ldx z:$12,y                 ; 00/02E0: B6 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002E2:
    clv                         ; 00/02E2: B8 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002E3:
    lda a:$3412,y               ; 00/02E3: B9 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002E6:
    tsx                         ; 00/02E6: BA ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002E7:
    ldy a:$3412,x               ; 00/02E7: BC 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002EA:
    lda a:$3412,x               ; 00/02EA: BD 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002ED:
    ldx a:$3412,y               ; 00/02ED: BE 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002F0:
    cpy #$12                    ; 00/02F0: C0 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002F2:
    cmp ($12,x)                 ; 00/02F2: C1 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002F4:
    cpy z:$12                   ; 00/02F4: C4 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002F6:
    cmp z:$12                   ; 00/02F6: C5 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002F8:
    dec z:$12                   ; 00/02F8: C6 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002FA:
    iny                         ; 00/02FA: C8 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002FB:
    cmp #$12                    ; 00/02FB: C9 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002FD:
    dex                         ; 00/02FD: CA ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_0002FE:
    cpy a:$3412                 ; 00/02FE: CC 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000301:
    cmp a:$3412                 ; 00/0301: CD 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000304:
    dec a:$3412                 ; 00/0304: CE 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000307:
    bne entry_000309            ; 00/0307: D0 00 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000309:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $D1,$12               ; 00/0309
entry_00030B:
    cmp z:$12,x                 ; 00/030B: D5 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00030D:
    dec z:$12,x                 ; 00/030D: D6 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00030F:
    cld                         ; 00/030F: D8 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000310:
    cmp a:$3412,y               ; 00/0310: D9 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000313:
    cmp a:$3412,x               ; 00/0313: DD 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000316:
    dec a:$3412,x               ; 00/0316: DE 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000319:
    cpx #$12                    ; 00/0319: E0 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00031B:
    sbc ($12,x)                 ; 00/031B: E1 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00031D:
    cpx z:$12                   ; 00/031D: E4 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00031F:
    sbc z:$12                   ; 00/031F: E5 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000321:
    inc z:$12                   ; 00/0321: E6 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000323:
    inx                         ; 00/0323: E8 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000324:
    sbc #$12                    ; 00/0324: E9 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000326:
    nop                         ; 00/0326: EA ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000327:
    cpx a:$3412                 ; 00/0327: EC 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00032A:
    sbc a:$3412                 ; 00/032A: ED 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00032D:
    inc a:$3412                 ; 00/032D: EE 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000330:
    beq entry_000332            ; 00/0330: F0 00 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000332:
; code flow reached here but decoding stopped: opcode may be changed by a store to an unknown value or to one of several values (self-modifying code)
    .byte $F1,$12               ; 00/0332
entry_000334:
    sbc z:$12,x                 ; 00/0334: F5 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000336:
    inc z:$12,x                 ; 00/0336: F6 12 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000338:
    sed                         ; 00/0338: F8 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_000339:
    sbc a:$3412,y               ; 00/0339: F9 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00033C:
    sbc a:$3412,x               ; 00/033C: FD 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
entry_00033F:
    inc a:$3412,x               ; 00/033F: FE 12 34 ; decoded as on disk: runs from the entry before any store (--strict-smc); later runs may differ
