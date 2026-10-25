; dumpapple 0.9.0 listing of tests/progs/allops.bin
; cpu 65816, platform none
; rebuild: ca65 --cpu 65816 -t none -o allops.o allops.s
;          ld65 -C allops.cfg -o allops.bin allops.o
; assumes stores with unknown targets do not modify code
; note: unknown-target stores still count for return frames, CSW and inline helpers: COUT $FDED is not trusted (unresolved indirect jump at $00E9; store that may reach CSW at $002E; store that may reach CSW at $0076; store that may reach CSW at $00BC; store that may reach CSW at $00FE; store that may reach CSW at $0102; store through an unknown address at $011B; store through an unresolved pointer (12) at $0128; store through an unresolved pointer (12) at $013E; store through an unresolved pointer (12) at $0140; store through an unknown address at $0142; store that may reach CSW at $0144; store that may reach CSW at $0146; store that may reach CSW at $0148; store through an unresolved pointer (12) at $014A; store that may reach CSW at $01D2; store that may reach CSW at $0218; store that may reach CSW at $025E; store that may reach CSW at $02A7; store that may reach CSW at $02EE; store that may reach CSW at $0331; store that may reach CSW at $0335; store through an unknown address at $034E; store through an unresolved pointer (12) at $035B; store through an unresolved pointer (12) at $0372; store through an unresolved pointer (12) at $0374; store through an unknown address at $0376; store that may reach CSW at $0378; store that may reach CSW at $037A; store that may reach CSW at $037C; store through an unresolved pointer (12) at $037E; store that may reach CSW at $0408; store that may reach CSW at $044F; store that may reach CSW at $0494; store that may reach CSW at $04A4; store that may modify code (self-modifying code) at $04A4; store that may reach CSW at $04DC; store that may reach CSW at $04EC; store that may modify code (self-modifying code) at $04EC; store that may reach CSW at $0522; store that may reach CSW at $0533; store that may modify code (self-modifying code) at $0533; store that may reach CSW at $0564; store that may reach CSW at $0568; store that may reach CSW at $0578; store that may modify code (self-modifying code) at $0578; store through an unknown address at $0581; store through an unresolved pointer (12) at $058E; store through an unresolved pointer (12) at $05A4; store through an unresolved pointer (12) at $05A6; store through an unknown address at $05A8; store that may reach CSW at $05AA; store that may reach CSW at $05AC; store that may reach CSW at $05AE; store through an unresolved pointer (12) at $05B0; store that may reach CSW at $05B3; store that may modify code (self-modifying code) at $05B3; store that may reach CSW at $05BB; store that may modify code (self-modifying code) at $05BB; store that may reach CSW at $05BE; store that may modify code (self-modifying code) at $05BE; store that may reach CSW at $063B; store that may reach CSW at $064B; store that may modify code (self-modifying code) at $064B; store that may reach CSW at $0682; store that may reach CSW at $0692; store that may modify code (self-modifying code) at $0692; store that may reach CSW at $06C8; store that may reach CSW at $06D8; store that may modify code (self-modifying code) at $06D8; store that may reach CSW at $0711; store that may reach CSW at $0721; store that may modify code (self-modifying code) at $0721; store that may reach CSW at $0758; store that may reach CSW at $0769; store that may modify code (self-modifying code) at $0769; store that may reach CSW at $079B; store that may reach CSW at $079F; store that may reach CSW at $07AF; store that may modify code (self-modifying code) at $07AF; store through an unknown address at $07B8; store through an unresolved pointer (12) at $07C5; store through an unresolved pointer (12) at $07DC; store through an unresolved pointer (12) at $07DE; store through an unknown address at $07E0; store that may reach CSW at $07E2; store that may reach CSW at $07E4; store that may reach CSW at $07E6; store through an unresolved pointer (12) at $07E8; store that may reach CSW at $07EB; store that may modify code (self-modifying code) at $07EB; store that may reach CSW at $07F3; store that may modify code (self-modifying code) at $07F3; store that may reach CSW at $07F6; store that may modify code (self-modifying code) at $07F6; store that may reach CSW at $0875; store that may reach CSW at $0885; store that may modify code (self-modifying code) at $0885; store that may reach CSW at $08BD; store that may reach CSW at $08CD; store that may modify code (self-modifying code) at $08CD; stack pointer set by tcs at $0037 (stack may not be in page 1); return to an address that is not a caller's frame (rts dispatch) at $008D; return to an address that is not a caller's frame (rts dispatch) at $00E8; stack pointer set by txs at $0150 (stack may not be in page 1); stack pointer set by tcs at $0267 (stack may not be in page 1); return to an address that is not a caller's frame (rts dispatch) at $02BE; return to an address that is not a caller's frame (rts dispatch) at $031B; stack pointer set by txs at $0384 (stack may not be in page 1); stack pointer set by tcs at $049D (stack may not be in page 1); return to an address that is not a caller's frame (rts dispatch) at $04F3; return to an address that is not a caller's frame (rts dispatch) at $053A; return to an address that is not a caller's frame (rts dispatch) at $054E; stack pointer set by txs at $05B6 (stack may not be in page 1); stack pointer set by tcs at $06D1 (stack may not be in page 1); return to an address that is not a caller's frame (rts dispatch) at $0728; return to an address that is not a caller's frame (rts dispatch) at $0770; return to an address that is not a caller's frame (rts dispatch) at $0785; stack pointer set by txs at $07EE (stack may not be in page 1))

.setcpu "65816"

; ------------------------------------------------------------
; base $030000 length $8D4
.segment "SEG1"
.org $030000
entry_030000:
    .a8
    .i8
    .byte $00,$12               ; 03/0000: 00 12 brk $12
entry_030002:
    ora ($12,x)                 ; 03/0002: 01 12
entry_030004:
    cop $12                     ; 03/0004: 02 12
entry_030006:
    ora $12,s                   ; 03/0006: 03 12
entry_030008:
    tsb z:$12                   ; 03/0008: 04 12
entry_03000A:
    ora z:$12                   ; 03/000A: 05 12
entry_03000C:
    asl z:$12                   ; 03/000C: 06 12
entry_03000E:
    ora [$12]                   ; 03/000E: 07 12
entry_030010:
    php                         ; 03/0010: 08
entry_030011:
    ora #$12                    ; 03/0011: 09 12
entry_030013:
    asl a                       ; 03/0013: 0A
entry_030014:
    phd                         ; 03/0014: 0B
entry_030015:
    tsb a:$3412                 ; 03/0015: 0C 12 34
entry_030018:
    ora a:$3412                 ; 03/0018: 0D 12 34
entry_03001B:
    asl a:$3412                 ; 03/001B: 0E 12 34
entry_03001E:
    ora f:$563412               ; 03/001E: 0F 12 34 56
entry_030022:
    bpl entry_030024            ; 03/0022: 10 00
entry_030024:
    ora ($12),y                 ; 03/0024: 11 12
entry_030026:
    ora ($12)                   ; 03/0026: 12 12
entry_030028:
    ora ($12,s),y               ; 03/0028: 13 12
entry_03002A:
    trb z:$12                   ; 03/002A: 14 12
entry_03002C:
    ora z:$12,x                 ; 03/002C: 15 12
entry_03002E:
    asl z:$12,x                 ; 03/002E: 16 12
entry_030030:
    ora [$12],y                 ; 03/0030: 17 12
entry_030032:
    clc                         ; 03/0032: 18
entry_030033:
    ora a:$3412,y               ; 03/0033: 19 12 34
entry_030036:
    inc a                       ; 03/0036: 1A
entry_030037:
    tcs                         ; 03/0037: 1B
entry_030038:
    trb a:$3412                 ; 03/0038: 1C 12 34
entry_03003B:
    ora a:$3412,x               ; 03/003B: 1D 12 34
entry_03003E:
    asl a:$3412,x               ; 03/003E: 1E 12 34
entry_030041:
    ora f:$563412,x             ; 03/0041: 1F 12 34 56
entry_030045:
    jsr $3412                   ; 03/0045: 20 12 34
entry_030048:
    and ($12,x)                 ; 03/0048: 21 12
entry_03004A:
    jsl f:$563412               ; 03/004A: 22 12 34 56
entry_03004E:
    and $12,s                   ; 03/004E: 23 12
entry_030050:
    bit z:$12                   ; 03/0050: 24 12
entry_030052:
    and z:$12                   ; 03/0052: 25 12
entry_030054:
    rol z:$12                   ; 03/0054: 26 12
entry_030056:
    and [$12]                   ; 03/0056: 27 12
entry_030058:
    plp                         ; 03/0058: 28
entry_030059:
    and #$12                    ; 03/0059: 29 12
entry_03005B:
    rol a                       ; 03/005B: 2A
entry_03005C:
    pld                         ; 03/005C: 2B
entry_03005D:
    bit a:$3412                 ; 03/005D: 2C 12 34
entry_030060:
    and a:$3412                 ; 03/0060: 2D 12 34
entry_030063:
    rol a:$3412                 ; 03/0063: 2E 12 34
entry_030066:
    and f:$563412               ; 03/0066: 2F 12 34 56
entry_03006A:
    bmi entry_03006C            ; 03/006A: 30 00
entry_03006C:
    and ($12),y                 ; 03/006C: 31 12
entry_03006E:
    and ($12)                   ; 03/006E: 32 12
entry_030070:
    and ($12,s),y               ; 03/0070: 33 12
entry_030072:
    bit z:$12,x                 ; 03/0072: 34 12
entry_030074:
    and z:$12,x                 ; 03/0074: 35 12
entry_030076:
    rol z:$12,x                 ; 03/0076: 36 12
entry_030078:
    and [$12],y                 ; 03/0078: 37 12
entry_03007A:
    sec                         ; 03/007A: 38
entry_03007B:
    and a:$3412,y               ; 03/007B: 39 12 34
entry_03007E:
    dec a                       ; 03/007E: 3A
entry_03007F:
    tsc                         ; 03/007F: 3B
entry_030080:
    bit a:$3412,x               ; 03/0080: 3C 12 34
entry_030083:
    and a:$3412,x               ; 03/0083: 3D 12 34
entry_030086:
    rol a:$3412,x               ; 03/0086: 3E 12 34
entry_030089:
    and f:$563412,x             ; 03/0089: 3F 12 34 56
entry_03008D:
    rti                         ; 03/008D: 40
entry_03008E:
    eor ($12,x)                 ; 03/008E: 41 12
entry_030090:
    .byte $42,$12               ; 03/0090: 42 12 wdm $12
entry_030092:
    eor $12,s                   ; 03/0092: 43 12
entry_030094:
    mvp #$34,#$12               ; 03/0094: 44 12 34
entry_030097:
    eor z:$12                   ; 03/0097: 45 12
entry_030099:
    lsr z:$12                   ; 03/0099: 46 12
entry_03009B:
    eor [$12]                   ; 03/009B: 47 12
entry_03009D:
    pha                         ; 03/009D: 48
entry_03009E:
    eor #$12                    ; 03/009E: 49 12
entry_0300A0:
    lsr a                       ; 03/00A0: 4A
entry_0300A1:
    phk                         ; 03/00A1: 4B
entry_0300A2:
    jmp $3412                   ; 03/00A2: 4C 12 34
entry_0300A5:
    eor a:$3412                 ; 03/00A5: 4D 12 34
entry_0300A8:
    lsr a:$3412                 ; 03/00A8: 4E 12 34
entry_0300AB:
    eor f:$563412               ; 03/00AB: 4F 12 34 56
entry_0300AF:
    bvc entry_0300B1            ; 03/00AF: 50 00
entry_0300B1:
    eor ($12),y                 ; 03/00B1: 51 12
entry_0300B3:
    eor ($12)                   ; 03/00B3: 52 12
entry_0300B5:
    eor ($12,s),y               ; 03/00B5: 53 12
entry_0300B7:
    mvn #$34,#$12               ; 03/00B7: 54 12 34
entry_0300BA:
    eor z:$12,x                 ; 03/00BA: 55 12
entry_0300BC:
    lsr z:$12,x                 ; 03/00BC: 56 12
entry_0300BE:
    eor [$12],y                 ; 03/00BE: 57 12
entry_0300C0:
    cli                         ; 03/00C0: 58
entry_0300C1:
    eor a:$3412,y               ; 03/00C1: 59 12 34
entry_0300C4:
    phy                         ; 03/00C4: 5A
entry_0300C5:
    tcd                         ; 03/00C5: 5B
entry_0300C6:
    jml f:$563412               ; 03/00C6: 5C 12 34 56
entry_0300CA:
    eor a:$3412,x               ; 03/00CA: 5D 12 34
entry_0300CD:
    lsr a:$3412,x               ; 03/00CD: 5E 12 34
entry_0300D0:
    eor f:$563412,x             ; 03/00D0: 5F 12 34 56
entry_0300D4:
    rts                         ; 03/00D4: 60
entry_0300D5:
    adc ($12,x)                 ; 03/00D5: 61 12
entry_0300D7:
    per entry_0300DA            ; 03/00D7: 62 00 00
entry_0300DA:
    adc $12,s                   ; 03/00DA: 63 12
entry_0300DC:
    stz z:$12                   ; 03/00DC: 64 12
entry_0300DE:
    adc z:$12                   ; 03/00DE: 65 12
entry_0300E0:
    ror z:$12                   ; 03/00E0: 66 12
entry_0300E2:
    adc [$12]                   ; 03/00E2: 67 12
entry_0300E4:
    pla                         ; 03/00E4: 68
entry_0300E5:
    adc #$12                    ; 03/00E5: 69 12
entry_0300E7:
    ror a                       ; 03/00E7: 6A
entry_0300E8:
    rtl                         ; 03/00E8: 6B
entry_0300E9:
    jmp ($3412)                 ; 03/00E9: 6C 12 34
entry_0300EC:
    adc a:$3412                 ; 03/00EC: 6D 12 34
entry_0300EF:
    ror a:$3412                 ; 03/00EF: 6E 12 34
entry_0300F2:
    adc f:$563412               ; 03/00F2: 6F 12 34 56
entry_0300F6:
    bvs entry_0300F8            ; 03/00F6: 70 00
entry_0300F8:
    adc ($12),y                 ; 03/00F8: 71 12
entry_0300FA:
    adc ($12)                   ; 03/00FA: 72 12
entry_0300FC:
    adc ($12,s),y               ; 03/00FC: 73 12
entry_0300FE:
    stz z:$12,x                 ; 03/00FE: 74 12
entry_030100:
    adc z:$12,x                 ; 03/0100: 75 12
entry_030102:
    ror z:$12,x                 ; 03/0102: 76 12
entry_030104:
    adc [$12],y                 ; 03/0104: 77 12
entry_030106:
    sei                         ; 03/0106: 78
entry_030107:
    adc a:$3412,y               ; 03/0107: 79 12 34
entry_03010A:
    ply                         ; 03/010A: 7A
entry_03010B:
    tdc                         ; 03/010B: 7B
entry_03010C:
    jmp ($3412,x)               ; 03/010C: 7C 12 34
entry_03010F:
    adc a:$3412,x               ; 03/010F: 7D 12 34
entry_030112:
    ror a:$3412,x               ; 03/0112: 7E 12 34
entry_030115:
    adc f:$563412,x             ; 03/0115: 7F 12 34 56
entry_030119:
    bra entry_03011B            ; 03/0119: 80 00
entry_03011B:
    sta ($12,x)                 ; 03/011B: 81 12 ; unknown-target store (assumed not to modify code)
entry_03011D:
    brl entry_030120            ; 03/011D: 82 00 00
entry_030120:
    sta $12,s                   ; 03/0120: 83 12
entry_030122:
    sty z:$12                   ; 03/0122: 84 12
entry_030124:
    sta z:$12                   ; 03/0124: 85 12
entry_030126:
    stx z:$12                   ; 03/0126: 86 12
entry_030128:
    sta [$12]                   ; 03/0128: 87 12 ; unknown-target store (assumed not to modify code)
entry_03012A:
    dey                         ; 03/012A: 88
entry_03012B:
    bit #$12                    ; 03/012B: 89 12
entry_03012D:
    txa                         ; 03/012D: 8A
entry_03012E:
    phb                         ; 03/012E: 8B
entry_03012F:
    sty a:$3412                 ; 03/012F: 8C 12 34
entry_030132:
    sta a:$3412                 ; 03/0132: 8D 12 34
entry_030135:
    stx a:$3412                 ; 03/0135: 8E 12 34
entry_030138:
    sta f:$563412               ; 03/0138: 8F 12 34 56
entry_03013C:
    bcc entry_03013E            ; 03/013C: 90 00
entry_03013E:
    sta ($12),y                 ; 03/013E: 91 12 ; unknown-target store (assumed not to modify code)
entry_030140:
    sta ($12)                   ; 03/0140: 92 12 ; unknown-target store (assumed not to modify code)
entry_030142:
    sta ($12,s),y               ; 03/0142: 93 12 ; unknown-target store (assumed not to modify code)
entry_030144:
    sty z:$12,x                 ; 03/0144: 94 12
entry_030146:
    sta z:$12,x                 ; 03/0146: 95 12
entry_030148:
    stx z:$12,y                 ; 03/0148: 96 12
entry_03014A:
    sta [$12],y                 ; 03/014A: 97 12 ; unknown-target store (assumed not to modify code)
entry_03014C:
    tya                         ; 03/014C: 98
entry_03014D:
    sta a:$3412,y               ; 03/014D: 99 12 34
entry_030150:
    txs                         ; 03/0150: 9A
entry_030151:
    txy                         ; 03/0151: 9B
entry_030152:
    stz a:$3412                 ; 03/0152: 9C 12 34
entry_030155:
    sta a:$3412,x               ; 03/0155: 9D 12 34
entry_030158:
    stz a:$3412,x               ; 03/0158: 9E 12 34
entry_03015B:
    sta f:$563412,x             ; 03/015B: 9F 12 34 56
entry_03015F:
    ldy #$12                    ; 03/015F: A0 12
entry_030161:
    lda ($12,x)                 ; 03/0161: A1 12
entry_030163:
    ldx #$12                    ; 03/0163: A2 12
entry_030165:
    lda $12,s                   ; 03/0165: A3 12
entry_030167:
    ldy z:$12                   ; 03/0167: A4 12
entry_030169:
    lda z:$12                   ; 03/0169: A5 12
entry_03016B:
    ldx z:$12                   ; 03/016B: A6 12
entry_03016D:
    lda [$12]                   ; 03/016D: A7 12
entry_03016F:
    tay                         ; 03/016F: A8
entry_030170:
    lda #$12                    ; 03/0170: A9 12
entry_030172:
    tax                         ; 03/0172: AA
entry_030173:
    plb                         ; 03/0173: AB
entry_030174:
    ldy a:$3412                 ; 03/0174: AC 12 34
entry_030177:
    lda a:$3412                 ; 03/0177: AD 12 34
entry_03017A:
    ldx a:$3412                 ; 03/017A: AE 12 34
entry_03017D:
    lda f:$563412               ; 03/017D: AF 12 34 56
entry_030181:
    bcs entry_030183            ; 03/0181: B0 00
entry_030183:
    lda ($12),y                 ; 03/0183: B1 12
entry_030185:
    lda ($12)                   ; 03/0185: B2 12
entry_030187:
    lda ($12,s),y               ; 03/0187: B3 12
entry_030189:
    ldy z:$12,x                 ; 03/0189: B4 12
entry_03018B:
    lda z:$12,x                 ; 03/018B: B5 12
entry_03018D:
    ldx z:$12,y                 ; 03/018D: B6 12
entry_03018F:
    lda [$12],y                 ; 03/018F: B7 12
entry_030191:
    clv                         ; 03/0191: B8
entry_030192:
    lda a:$3412,y               ; 03/0192: B9 12 34
entry_030195:
    tsx                         ; 03/0195: BA
entry_030196:
    tyx                         ; 03/0196: BB
entry_030197:
    ldy a:$3412,x               ; 03/0197: BC 12 34
entry_03019A:
    lda a:$3412,x               ; 03/019A: BD 12 34
entry_03019D:
    ldx a:$3412,y               ; 03/019D: BE 12 34
entry_0301A0:
    lda f:$563412,x             ; 03/01A0: BF 12 34 56
entry_0301A4:
    cpy #$12                    ; 03/01A4: C0 12
entry_0301A6:
    cmp ($12,x)                 ; 03/01A6: C1 12
entry_0301A8:
    rep #$12                    ; 03/01A8: C2 12
entry_0301AA:
    cmp $12,s                   ; 03/01AA: C3 12
entry_0301AC:
    cpy z:$12                   ; 03/01AC: C4 12
entry_0301AE:
    cmp z:$12                   ; 03/01AE: C5 12
entry_0301B0:
    dec z:$12                   ; 03/01B0: C6 12
entry_0301B2:
    cmp [$12]                   ; 03/01B2: C7 12
entry_0301B4:
    iny                         ; 03/01B4: C8
entry_0301B5:
    cmp #$12                    ; 03/01B5: C9 12
entry_0301B7:
    dex                         ; 03/01B7: CA
entry_0301B8:
    wai                         ; 03/01B8: CB
entry_0301B9:
    cpy a:$3412                 ; 03/01B9: CC 12 34
entry_0301BC:
    cmp a:$3412                 ; 03/01BC: CD 12 34
entry_0301BF:
    dec a:$3412                 ; 03/01BF: CE 12 34
entry_0301C2:
    cmp f:$563412               ; 03/01C2: CF 12 34 56
entry_0301C6:
    bne entry_0301C8            ; 03/01C6: D0 00
entry_0301C8:
    cmp ($12),y                 ; 03/01C8: D1 12
entry_0301CA:
    cmp ($12)                   ; 03/01CA: D2 12
entry_0301CC:
    cmp ($12,s),y               ; 03/01CC: D3 12
entry_0301CE:
    pei ($12)                   ; 03/01CE: D4 12
entry_0301D0:
    cmp z:$12,x                 ; 03/01D0: D5 12
entry_0301D2:
    dec z:$12,x                 ; 03/01D2: D6 12
entry_0301D4:
    cmp [$12],y                 ; 03/01D4: D7 12
entry_0301D6:
    cld                         ; 03/01D6: D8
entry_0301D7:
    cmp a:$3412,y               ; 03/01D7: D9 12 34
entry_0301DA:
    phx                         ; 03/01DA: DA
entry_0301DB:
    stp                         ; 03/01DB: DB
entry_0301DC:
    jml [$3412]                 ; 03/01DC: DC 12 34
entry_0301DF:
    cmp a:$3412,x               ; 03/01DF: DD 12 34
entry_0301E2:
    dec a:$3412,x               ; 03/01E2: DE 12 34
entry_0301E5:
    cmp f:$563412,x             ; 03/01E5: DF 12 34 56
entry_0301E9:
    cpx #$12                    ; 03/01E9: E0 12
entry_0301EB:
    sbc ($12,x)                 ; 03/01EB: E1 12
entry_0301ED:
    sep #$12                    ; 03/01ED: E2 12
entry_0301EF:
    sbc $12,s                   ; 03/01EF: E3 12
entry_0301F1:
    cpx z:$12                   ; 03/01F1: E4 12
entry_0301F3:
    sbc z:$12                   ; 03/01F3: E5 12
entry_0301F5:
    inc z:$12                   ; 03/01F5: E6 12
entry_0301F7:
    sbc [$12]                   ; 03/01F7: E7 12
entry_0301F9:
    inx                         ; 03/01F9: E8
entry_0301FA:
    sbc #$12                    ; 03/01FA: E9 12
entry_0301FC:
    nop                         ; 03/01FC: EA
entry_0301FD:
    xba                         ; 03/01FD: EB
entry_0301FE:
    cpx a:$3412                 ; 03/01FE: EC 12 34
entry_030201:
    sbc a:$3412                 ; 03/0201: ED 12 34
entry_030204:
    inc a:$3412                 ; 03/0204: EE 12 34
entry_030207:
    sbc f:$563412               ; 03/0207: EF 12 34 56
entry_03020B:
    beq entry_03020D            ; 03/020B: F0 00
entry_03020D:
    sbc ($12),y                 ; 03/020D: F1 12
entry_03020F:
    sbc ($12)                   ; 03/020F: F2 12
entry_030211:
    sbc ($12,s),y               ; 03/0211: F3 12
entry_030213:
    pea $3412                   ; 03/0213: F4 12 34
entry_030216:
    sbc z:$12,x                 ; 03/0216: F5 12
entry_030218:
    inc z:$12,x                 ; 03/0218: F6 12
entry_03021A:
    sbc [$12],y                 ; 03/021A: F7 12
entry_03021C:
    sed                         ; 03/021C: F8
entry_03021D:
    sbc a:$3412,y               ; 03/021D: F9 12 34
entry_030220:
    plx                         ; 03/0220: FA
entry_030221:
    xce                         ; 03/0221: FB
entry_030222:
    jsr ($3412,x)               ; 03/0222: FC 12 34
entry_030225:
    sbc a:$3412,x               ; 03/0225: FD 12 34
entry_030228:
    inc a:$3412,x               ; 03/0228: FE 12 34
entry_03022B:
    sbc f:$563412,x             ; 03/022B: FF 12 34 56
entry_03022F:
    .a16
    .byte $00,$12               ; 03/022F: 00 12 brk $12
entry_030231:
    ora ($12,x)                 ; 03/0231: 01 12
entry_030233:
    cop $12                     ; 03/0233: 02 12
entry_030235:
    ora $12,s                   ; 03/0235: 03 12
entry_030237:
    tsb z:$12                   ; 03/0237: 04 12
entry_030239:
    ora z:$12                   ; 03/0239: 05 12
entry_03023B:
    asl z:$12                   ; 03/023B: 06 12
entry_03023D:
    ora [$12]                   ; 03/023D: 07 12
entry_03023F:
    php                         ; 03/023F: 08
entry_030240:
    ora #$3412                  ; 03/0240: 09 12 34
entry_030243:
    asl a                       ; 03/0243: 0A
entry_030244:
    phd                         ; 03/0244: 0B
entry_030245:
    tsb a:$3412                 ; 03/0245: 0C 12 34
entry_030248:
    ora a:$3412                 ; 03/0248: 0D 12 34
entry_03024B:
    asl a:$3412                 ; 03/024B: 0E 12 34
entry_03024E:
    ora f:$563412               ; 03/024E: 0F 12 34 56
entry_030252:
    bpl entry_030254            ; 03/0252: 10 00
entry_030254:
    ora ($12),y                 ; 03/0254: 11 12
entry_030256:
    ora ($12)                   ; 03/0256: 12 12
entry_030258:
    ora ($12,s),y               ; 03/0258: 13 12
entry_03025A:
    trb z:$12                   ; 03/025A: 14 12
entry_03025C:
    ora z:$12,x                 ; 03/025C: 15 12
entry_03025E:
    asl z:$12,x                 ; 03/025E: 16 12
entry_030260:
    ora [$12],y                 ; 03/0260: 17 12
entry_030262:
    clc                         ; 03/0262: 18
entry_030263:
    ora a:$3412,y               ; 03/0263: 19 12 34
entry_030266:
    inc a                       ; 03/0266: 1A
entry_030267:
    tcs                         ; 03/0267: 1B
entry_030268:
    trb a:$3412                 ; 03/0268: 1C 12 34
entry_03026B:
    ora a:$3412,x               ; 03/026B: 1D 12 34
entry_03026E:
    asl a:$3412,x               ; 03/026E: 1E 12 34
entry_030271:
    ora f:$563412,x             ; 03/0271: 1F 12 34 56
entry_030275:
    jsr $3412                   ; 03/0275: 20 12 34
entry_030278:
    and ($12,x)                 ; 03/0278: 21 12
entry_03027A:
    jsl f:$563412               ; 03/027A: 22 12 34 56
entry_03027E:
    and $12,s                   ; 03/027E: 23 12
entry_030280:
    bit z:$12                   ; 03/0280: 24 12
entry_030282:
    and z:$12                   ; 03/0282: 25 12
entry_030284:
    rol z:$12                   ; 03/0284: 26 12
entry_030286:
    and [$12]                   ; 03/0286: 27 12
entry_030288:
    plp                         ; 03/0288: 28
entry_030289:
    and #$3412                  ; 03/0289: 29 12 34
entry_03028C:
    rol a                       ; 03/028C: 2A
entry_03028D:
    pld                         ; 03/028D: 2B
entry_03028E:
    bit a:$3412                 ; 03/028E: 2C 12 34
entry_030291:
    and a:$3412                 ; 03/0291: 2D 12 34
entry_030294:
    rol a:$3412                 ; 03/0294: 2E 12 34
entry_030297:
    and f:$563412               ; 03/0297: 2F 12 34 56
entry_03029B:
    bmi entry_03029D            ; 03/029B: 30 00
entry_03029D:
    and ($12),y                 ; 03/029D: 31 12
entry_03029F:
    and ($12)                   ; 03/029F: 32 12
entry_0302A1:
    and ($12,s),y               ; 03/02A1: 33 12
entry_0302A3:
    bit z:$12,x                 ; 03/02A3: 34 12
entry_0302A5:
    and z:$12,x                 ; 03/02A5: 35 12
entry_0302A7:
    rol z:$12,x                 ; 03/02A7: 36 12
entry_0302A9:
    and [$12],y                 ; 03/02A9: 37 12
entry_0302AB:
    sec                         ; 03/02AB: 38
entry_0302AC:
    and a:$3412,y               ; 03/02AC: 39 12 34
entry_0302AF:
    dec a                       ; 03/02AF: 3A
entry_0302B0:
    tsc                         ; 03/02B0: 3B
entry_0302B1:
    bit a:$3412,x               ; 03/02B1: 3C 12 34
entry_0302B4:
    and a:$3412,x               ; 03/02B4: 3D 12 34
entry_0302B7:
    rol a:$3412,x               ; 03/02B7: 3E 12 34
entry_0302BA:
    and f:$563412,x             ; 03/02BA: 3F 12 34 56
entry_0302BE:
    rti                         ; 03/02BE: 40
entry_0302BF:
    eor ($12,x)                 ; 03/02BF: 41 12
entry_0302C1:
    .byte $42,$12               ; 03/02C1: 42 12 wdm $12
entry_0302C3:
    eor $12,s                   ; 03/02C3: 43 12
entry_0302C5:
    mvp #$34,#$12               ; 03/02C5: 44 12 34
entry_0302C8:
    eor z:$12                   ; 03/02C8: 45 12
entry_0302CA:
    lsr z:$12                   ; 03/02CA: 46 12
entry_0302CC:
    eor [$12]                   ; 03/02CC: 47 12
entry_0302CE:
    pha                         ; 03/02CE: 48
entry_0302CF:
    eor #$3412                  ; 03/02CF: 49 12 34
entry_0302D2:
    lsr a                       ; 03/02D2: 4A
entry_0302D3:
    phk                         ; 03/02D3: 4B
entry_0302D4:
    jmp $3412                   ; 03/02D4: 4C 12 34
entry_0302D7:
    eor a:$3412                 ; 03/02D7: 4D 12 34
entry_0302DA:
    lsr a:$3412                 ; 03/02DA: 4E 12 34
entry_0302DD:
    eor f:$563412               ; 03/02DD: 4F 12 34 56
entry_0302E1:
    bvc entry_0302E3            ; 03/02E1: 50 00
entry_0302E3:
    eor ($12),y                 ; 03/02E3: 51 12
entry_0302E5:
    eor ($12)                   ; 03/02E5: 52 12
entry_0302E7:
    eor ($12,s),y               ; 03/02E7: 53 12
entry_0302E9:
    mvn #$34,#$12               ; 03/02E9: 54 12 34
entry_0302EC:
    eor z:$12,x                 ; 03/02EC: 55 12
entry_0302EE:
    lsr z:$12,x                 ; 03/02EE: 56 12
entry_0302F0:
    eor [$12],y                 ; 03/02F0: 57 12
entry_0302F2:
    cli                         ; 03/02F2: 58
entry_0302F3:
    eor a:$3412,y               ; 03/02F3: 59 12 34
entry_0302F6:
    phy                         ; 03/02F6: 5A
entry_0302F7:
    tcd                         ; 03/02F7: 5B
entry_0302F8:
    jml f:$563412               ; 03/02F8: 5C 12 34 56
entry_0302FC:
    eor a:$3412,x               ; 03/02FC: 5D 12 34
entry_0302FF:
    lsr a:$3412,x               ; 03/02FF: 5E 12 34
entry_030302:
    eor f:$563412,x             ; 03/0302: 5F 12 34 56
entry_030306:
    rts                         ; 03/0306: 60
entry_030307:
    adc ($12,x)                 ; 03/0307: 61 12
entry_030309:
    per entry_03030C            ; 03/0309: 62 00 00
entry_03030C:
    adc $12,s                   ; 03/030C: 63 12
entry_03030E:
    stz z:$12                   ; 03/030E: 64 12
entry_030310:
    adc z:$12                   ; 03/0310: 65 12
entry_030312:
    ror z:$12                   ; 03/0312: 66 12
entry_030314:
    adc [$12]                   ; 03/0314: 67 12
entry_030316:
    pla                         ; 03/0316: 68
entry_030317:
    adc #$3412                  ; 03/0317: 69 12 34
entry_03031A:
    ror a                       ; 03/031A: 6A
entry_03031B:
    rtl                         ; 03/031B: 6B
entry_03031C:
    jmp ($3412)                 ; 03/031C: 6C 12 34
entry_03031F:
    adc a:$3412                 ; 03/031F: 6D 12 34
entry_030322:
    ror a:$3412                 ; 03/0322: 6E 12 34
entry_030325:
    adc f:$563412               ; 03/0325: 6F 12 34 56
entry_030329:
    bvs entry_03032B            ; 03/0329: 70 00
entry_03032B:
    adc ($12),y                 ; 03/032B: 71 12
entry_03032D:
    adc ($12)                   ; 03/032D: 72 12
entry_03032F:
    adc ($12,s),y               ; 03/032F: 73 12
entry_030331:
    stz z:$12,x                 ; 03/0331: 74 12
entry_030333:
    adc z:$12,x                 ; 03/0333: 75 12
entry_030335:
    ror z:$12,x                 ; 03/0335: 76 12
entry_030337:
    adc [$12],y                 ; 03/0337: 77 12
entry_030339:
    sei                         ; 03/0339: 78
entry_03033A:
    adc a:$3412,y               ; 03/033A: 79 12 34
entry_03033D:
    ply                         ; 03/033D: 7A
entry_03033E:
    tdc                         ; 03/033E: 7B
entry_03033F:
    jmp ($3412,x)               ; 03/033F: 7C 12 34
entry_030342:
    adc a:$3412,x               ; 03/0342: 7D 12 34
entry_030345:
    ror a:$3412,x               ; 03/0345: 7E 12 34
entry_030348:
    adc f:$563412,x             ; 03/0348: 7F 12 34 56
entry_03034C:
    bra entry_03034E            ; 03/034C: 80 00
entry_03034E:
    sta ($12,x)                 ; 03/034E: 81 12 ; unknown-target store (assumed not to modify code)
entry_030350:
    brl entry_030353            ; 03/0350: 82 00 00
entry_030353:
    sta $12,s                   ; 03/0353: 83 12
entry_030355:
    sty z:$12                   ; 03/0355: 84 12
entry_030357:
    sta z:$12                   ; 03/0357: 85 12
entry_030359:
    stx z:$12                   ; 03/0359: 86 12
entry_03035B:
    sta [$12]                   ; 03/035B: 87 12 ; unknown-target store (assumed not to modify code)
entry_03035D:
    dey                         ; 03/035D: 88
entry_03035E:
    bit #$3412                  ; 03/035E: 89 12 34
entry_030361:
    txa                         ; 03/0361: 8A
entry_030362:
    phb                         ; 03/0362: 8B
entry_030363:
    sty a:$3412                 ; 03/0363: 8C 12 34
entry_030366:
    sta a:$3412                 ; 03/0366: 8D 12 34
entry_030369:
    stx a:$3412                 ; 03/0369: 8E 12 34
entry_03036C:
    sta f:$563412               ; 03/036C: 8F 12 34 56
entry_030370:
    bcc entry_030372            ; 03/0370: 90 00
entry_030372:
    sta ($12),y                 ; 03/0372: 91 12 ; unknown-target store (assumed not to modify code)
entry_030374:
    sta ($12)                   ; 03/0374: 92 12 ; unknown-target store (assumed not to modify code)
entry_030376:
    sta ($12,s),y               ; 03/0376: 93 12 ; unknown-target store (assumed not to modify code)
entry_030378:
    sty z:$12,x                 ; 03/0378: 94 12
entry_03037A:
    sta z:$12,x                 ; 03/037A: 95 12
entry_03037C:
    stx z:$12,y                 ; 03/037C: 96 12
entry_03037E:
    sta [$12],y                 ; 03/037E: 97 12 ; unknown-target store (assumed not to modify code)
entry_030380:
    tya                         ; 03/0380: 98
entry_030381:
    sta a:$3412,y               ; 03/0381: 99 12 34
entry_030384:
    txs                         ; 03/0384: 9A
entry_030385:
    txy                         ; 03/0385: 9B
entry_030386:
    stz a:$3412                 ; 03/0386: 9C 12 34
entry_030389:
    sta a:$3412,x               ; 03/0389: 9D 12 34
entry_03038C:
    stz a:$3412,x               ; 03/038C: 9E 12 34
entry_03038F:
    sta f:$563412,x             ; 03/038F: 9F 12 34 56
entry_030393:
    ldy #$12                    ; 03/0393: A0 12
entry_030395:
    lda ($12,x)                 ; 03/0395: A1 12
entry_030397:
    ldx #$12                    ; 03/0397: A2 12
entry_030399:
    lda $12,s                   ; 03/0399: A3 12
entry_03039B:
    ldy z:$12                   ; 03/039B: A4 12
entry_03039D:
    lda z:$12                   ; 03/039D: A5 12
entry_03039F:
    ldx z:$12                   ; 03/039F: A6 12
entry_0303A1:
    lda [$12]                   ; 03/03A1: A7 12
entry_0303A3:
    tay                         ; 03/03A3: A8
entry_0303A4:
    lda #$3412                  ; 03/03A4: A9 12 34
entry_0303A7:
    tax                         ; 03/03A7: AA
entry_0303A8:
    plb                         ; 03/03A8: AB
entry_0303A9:
    ldy a:$3412                 ; 03/03A9: AC 12 34
entry_0303AC:
    lda a:$3412                 ; 03/03AC: AD 12 34
entry_0303AF:
    ldx a:$3412                 ; 03/03AF: AE 12 34
entry_0303B2:
    lda f:$563412               ; 03/03B2: AF 12 34 56
entry_0303B6:
    bcs entry_0303B8            ; 03/03B6: B0 00
entry_0303B8:
    lda ($12),y                 ; 03/03B8: B1 12
entry_0303BA:
    lda ($12)                   ; 03/03BA: B2 12
entry_0303BC:
    lda ($12,s),y               ; 03/03BC: B3 12
entry_0303BE:
    ldy z:$12,x                 ; 03/03BE: B4 12
entry_0303C0:
    lda z:$12,x                 ; 03/03C0: B5 12
entry_0303C2:
    ldx z:$12,y                 ; 03/03C2: B6 12
entry_0303C4:
    lda [$12],y                 ; 03/03C4: B7 12
entry_0303C6:
    clv                         ; 03/03C6: B8
entry_0303C7:
    lda a:$3412,y               ; 03/03C7: B9 12 34
entry_0303CA:
    tsx                         ; 03/03CA: BA
entry_0303CB:
    tyx                         ; 03/03CB: BB
entry_0303CC:
    ldy a:$3412,x               ; 03/03CC: BC 12 34
entry_0303CF:
    lda a:$3412,x               ; 03/03CF: BD 12 34
entry_0303D2:
    ldx a:$3412,y               ; 03/03D2: BE 12 34
entry_0303D5:
    lda f:$563412,x             ; 03/03D5: BF 12 34 56
entry_0303D9:
    cpy #$12                    ; 03/03D9: C0 12
entry_0303DB:
    cmp ($12,x)                 ; 03/03DB: C1 12
entry_0303DD:
    rep #$12                    ; 03/03DD: C2 12
entry_0303DF:
    cmp $12,s                   ; 03/03DF: C3 12
entry_0303E1:
    cpy z:$12                   ; 03/03E1: C4 12
entry_0303E3:
    cmp z:$12                   ; 03/03E3: C5 12
entry_0303E5:
    dec z:$12                   ; 03/03E5: C6 12
entry_0303E7:
    cmp [$12]                   ; 03/03E7: C7 12
entry_0303E9:
    iny                         ; 03/03E9: C8
entry_0303EA:
    cmp #$3412                  ; 03/03EA: C9 12 34
entry_0303ED:
    dex                         ; 03/03ED: CA
entry_0303EE:
    wai                         ; 03/03EE: CB
entry_0303EF:
    cpy a:$3412                 ; 03/03EF: CC 12 34
entry_0303F2:
    cmp a:$3412                 ; 03/03F2: CD 12 34
entry_0303F5:
    dec a:$3412                 ; 03/03F5: CE 12 34
entry_0303F8:
    cmp f:$563412               ; 03/03F8: CF 12 34 56
entry_0303FC:
    bne entry_0303FE            ; 03/03FC: D0 00
entry_0303FE:
    cmp ($12),y                 ; 03/03FE: D1 12
entry_030400:
    cmp ($12)                   ; 03/0400: D2 12
entry_030402:
    cmp ($12,s),y               ; 03/0402: D3 12
entry_030404:
    pei ($12)                   ; 03/0404: D4 12
entry_030406:
    cmp z:$12,x                 ; 03/0406: D5 12
entry_030408:
    dec z:$12,x                 ; 03/0408: D6 12
entry_03040A:
    cmp [$12],y                 ; 03/040A: D7 12
entry_03040C:
    cld                         ; 03/040C: D8
entry_03040D:
    cmp a:$3412,y               ; 03/040D: D9 12 34
entry_030410:
    phx                         ; 03/0410: DA
entry_030411:
    stp                         ; 03/0411: DB
entry_030412:
    jml [$3412]                 ; 03/0412: DC 12 34
entry_030415:
    cmp a:$3412,x               ; 03/0415: DD 12 34
entry_030418:
    dec a:$3412,x               ; 03/0418: DE 12 34
entry_03041B:
    cmp f:$563412,x             ; 03/041B: DF 12 34 56
entry_03041F:
    cpx #$12                    ; 03/041F: E0 12
entry_030421:
    sbc ($12,x)                 ; 03/0421: E1 12
entry_030423:
    sep #$12                    ; 03/0423: E2 12
entry_030425:
    sbc $12,s                   ; 03/0425: E3 12
entry_030427:
    cpx z:$12                   ; 03/0427: E4 12
entry_030429:
    sbc z:$12                   ; 03/0429: E5 12
entry_03042B:
    inc z:$12                   ; 03/042B: E6 12
entry_03042D:
    sbc [$12]                   ; 03/042D: E7 12
entry_03042F:
    inx                         ; 03/042F: E8
entry_030430:
    sbc #$3412                  ; 03/0430: E9 12 34
entry_030433:
    nop                         ; 03/0433: EA
entry_030434:
    xba                         ; 03/0434: EB
entry_030435:
    cpx a:$3412                 ; 03/0435: EC 12 34
entry_030438:
    sbc a:$3412                 ; 03/0438: ED 12 34
entry_03043B:
    inc a:$3412                 ; 03/043B: EE 12 34
entry_03043E:
    sbc f:$563412               ; 03/043E: EF 12 34 56
entry_030442:
    beq entry_030444            ; 03/0442: F0 00
entry_030444:
    sbc ($12),y                 ; 03/0444: F1 12
entry_030446:
    sbc ($12)                   ; 03/0446: F2 12
entry_030448:
    sbc ($12,s),y               ; 03/0448: F3 12
entry_03044A:
    pea $3412                   ; 03/044A: F4 12 34
entry_03044D:
    sbc z:$12,x                 ; 03/044D: F5 12
entry_03044F:
    inc z:$12,x                 ; 03/044F: F6 12
entry_030451:
    sbc [$12],y                 ; 03/0451: F7 12
entry_030453:
    sed                         ; 03/0453: F8
entry_030454:
    sbc a:$3412,y               ; 03/0454: F9 12 34
entry_030457:
    plx                         ; 03/0457: FA
entry_030458:
    xce                         ; 03/0458: FB
entry_030459:
    jsr ($3412,x)               ; 03/0459: FC 12 34
entry_03045C:
    sbc a:$3412,x               ; 03/045C: FD 12 34
entry_03045F:
    inc a:$3412,x               ; 03/045F: FE 12 34
entry_030462:
    sbc f:$563412,x             ; 03/0462: FF 12 34 56
entry_030466:
    .a8
    .i16
    .byte $00,$12               ; 03/0466: 00 12 brk $12
entry_030468:
    ora ($12,x)                 ; 03/0468: 01 12
entry_03046A:
    cop $12                     ; 03/046A: 02 12
entry_03046C:
    ora $12,s                   ; 03/046C: 03 12
entry_03046E:
    tsb z:$12                   ; 03/046E: 04 12
entry_030470:
    ora z:$12                   ; 03/0470: 05 12
entry_030472:
    asl z:$12                   ; 03/0472: 06 12
entry_030474:
    ora [$12]                   ; 03/0474: 07 12
entry_030476:
    php                         ; 03/0476: 08
entry_030477:
    ora #$12                    ; 03/0477: 09 12
entry_030479:
    asl a                       ; 03/0479: 0A
entry_03047A:
    phd                         ; 03/047A: 0B
entry_03047B:
    tsb a:$3412                 ; 03/047B: 0C 12 34
entry_03047E:
    ora a:$3412                 ; 03/047E: 0D 12 34
entry_030481:
    asl a:$3412                 ; 03/0481: 0E 12 34
entry_030484:
    ora f:$563412               ; 03/0484: 0F 12 34 56
entry_030488:
    bpl entry_03048A            ; 03/0488: 10 00
entry_03048A:
    ora ($12),y                 ; 03/048A: 11 12
entry_03048C:
    ora ($12)                   ; 03/048C: 12 12
entry_03048E:
    ora ($12,s),y               ; 03/048E: 13 12
entry_030490:
    trb z:$12                   ; 03/0490: 14 12
entry_030492:
    ora z:$12,x                 ; 03/0492: 15 12
entry_030494:
    asl z:$12,x                 ; 03/0494: 16 12
entry_030496:
    ora [$12],y                 ; 03/0496: 17 12
entry_030498:
    clc                         ; 03/0498: 18
entry_030499:
    ora a:$3412,y               ; 03/0499: 19 12 34
entry_03049C:
    inc a                       ; 03/049C: 1A
entry_03049D:
    tcs                         ; 03/049D: 1B
entry_03049E:
    trb a:$3412                 ; 03/049E: 1C 12 34
entry_0304A1:
    ora a:$3412,x               ; 03/04A1: 1D 12 34
entry_0304A4:
    asl a:$3412,x               ; 03/04A4: 1E 12 34 ; unknown-target store (assumed not to modify code)
entry_0304A7:
    ora f:$563412,x             ; 03/04A7: 1F 12 34 56
entry_0304AB:
    jsr $3412                   ; 03/04AB: 20 12 34
entry_0304AE:
    and ($12,x)                 ; 03/04AE: 21 12
entry_0304B0:
    jsl f:$563412               ; 03/04B0: 22 12 34 56
entry_0304B4:
    and $12,s                   ; 03/04B4: 23 12
entry_0304B6:
    bit z:$12                   ; 03/04B6: 24 12
entry_0304B8:
    and z:$12                   ; 03/04B8: 25 12
entry_0304BA:
    rol z:$12                   ; 03/04BA: 26 12
entry_0304BC:
    and [$12]                   ; 03/04BC: 27 12
entry_0304BE:
    plp                         ; 03/04BE: 28
entry_0304BF:
    and #$12                    ; 03/04BF: 29 12
entry_0304C1:
    rol a                       ; 03/04C1: 2A
entry_0304C2:
    pld                         ; 03/04C2: 2B
entry_0304C3:
    bit a:$3412                 ; 03/04C3: 2C 12 34
entry_0304C6:
    and a:$3412                 ; 03/04C6: 2D 12 34
entry_0304C9:
    rol a:$3412                 ; 03/04C9: 2E 12 34
entry_0304CC:
    and f:$563412               ; 03/04CC: 2F 12 34 56
entry_0304D0:
    bmi entry_0304D2            ; 03/04D0: 30 00
entry_0304D2:
    and ($12),y                 ; 03/04D2: 31 12
entry_0304D4:
    and ($12)                   ; 03/04D4: 32 12
entry_0304D6:
    and ($12,s),y               ; 03/04D6: 33 12
entry_0304D8:
    bit z:$12,x                 ; 03/04D8: 34 12
entry_0304DA:
    and z:$12,x                 ; 03/04DA: 35 12
entry_0304DC:
    rol z:$12,x                 ; 03/04DC: 36 12
entry_0304DE:
    and [$12],y                 ; 03/04DE: 37 12
entry_0304E0:
    sec                         ; 03/04E0: 38
entry_0304E1:
    and a:$3412,y               ; 03/04E1: 39 12 34
entry_0304E4:
    dec a                       ; 03/04E4: 3A
entry_0304E5:
    tsc                         ; 03/04E5: 3B
entry_0304E6:
    bit a:$3412,x               ; 03/04E6: 3C 12 34
entry_0304E9:
    and a:$3412,x               ; 03/04E9: 3D 12 34
entry_0304EC:
    rol a:$3412,x               ; 03/04EC: 3E 12 34 ; unknown-target store (assumed not to modify code)
entry_0304EF:
    and f:$563412,x             ; 03/04EF: 3F 12 34 56
entry_0304F3:
    rti                         ; 03/04F3: 40
entry_0304F4:
    eor ($12,x)                 ; 03/04F4: 41 12
entry_0304F6:
    .byte $42,$12               ; 03/04F6: 42 12 wdm $12
entry_0304F8:
    eor $12,s                   ; 03/04F8: 43 12
entry_0304FA:
    mvp #$34,#$12               ; 03/04FA: 44 12 34
entry_0304FD:
    eor z:$12                   ; 03/04FD: 45 12
entry_0304FF:
    lsr z:$12                   ; 03/04FF: 46 12
entry_030501:
    eor [$12]                   ; 03/0501: 47 12
entry_030503:
    pha                         ; 03/0503: 48
entry_030504:
    eor #$12                    ; 03/0504: 49 12
entry_030506:
    lsr a                       ; 03/0506: 4A
entry_030507:
    phk                         ; 03/0507: 4B
entry_030508:
    jmp $3412                   ; 03/0508: 4C 12 34
entry_03050B:
    eor a:$3412                 ; 03/050B: 4D 12 34
entry_03050E:
    lsr a:$3412                 ; 03/050E: 4E 12 34
entry_030511:
    eor f:$563412               ; 03/0511: 4F 12 34 56
entry_030515:
    bvc entry_030517            ; 03/0515: 50 00
entry_030517:
    eor ($12),y                 ; 03/0517: 51 12
entry_030519:
    eor ($12)                   ; 03/0519: 52 12
entry_03051B:
    eor ($12,s),y               ; 03/051B: 53 12
entry_03051D:
    mvn #$34,#$12               ; 03/051D: 54 12 34
entry_030520:
    eor z:$12,x                 ; 03/0520: 55 12
entry_030522:
    lsr z:$12,x                 ; 03/0522: 56 12
entry_030524:
    eor [$12],y                 ; 03/0524: 57 12
entry_030526:
    cli                         ; 03/0526: 58
entry_030527:
    eor a:$3412,y               ; 03/0527: 59 12 34
entry_03052A:
    phy                         ; 03/052A: 5A
entry_03052B:
    tcd                         ; 03/052B: 5B
entry_03052C:
    jml f:$563412               ; 03/052C: 5C 12 34 56
entry_030530:
    eor a:$3412,x               ; 03/0530: 5D 12 34
entry_030533:
    lsr a:$3412,x               ; 03/0533: 5E 12 34 ; unknown-target store (assumed not to modify code)
entry_030536:
    eor f:$563412,x             ; 03/0536: 5F 12 34 56
entry_03053A:
    rts                         ; 03/053A: 60
entry_03053B:
    adc ($12,x)                 ; 03/053B: 61 12
entry_03053D:
    per entry_030540            ; 03/053D: 62 00 00
entry_030540:
    adc $12,s                   ; 03/0540: 63 12
entry_030542:
    stz z:$12                   ; 03/0542: 64 12
entry_030544:
    adc z:$12                   ; 03/0544: 65 12
entry_030546:
    ror z:$12                   ; 03/0546: 66 12
entry_030548:
    adc [$12]                   ; 03/0548: 67 12
entry_03054A:
    pla                         ; 03/054A: 68
entry_03054B:
    adc #$12                    ; 03/054B: 69 12
entry_03054D:
    ror a                       ; 03/054D: 6A
entry_03054E:
    rtl                         ; 03/054E: 6B
entry_03054F:
    jmp ($3412)                 ; 03/054F: 6C 12 34
entry_030552:
    adc a:$3412                 ; 03/0552: 6D 12 34
entry_030555:
    ror a:$3412                 ; 03/0555: 6E 12 34
entry_030558:
    adc f:$563412               ; 03/0558: 6F 12 34 56
entry_03055C:
    bvs entry_03055E            ; 03/055C: 70 00
entry_03055E:
    adc ($12),y                 ; 03/055E: 71 12
entry_030560:
    adc ($12)                   ; 03/0560: 72 12
entry_030562:
    adc ($12,s),y               ; 03/0562: 73 12
entry_030564:
    stz z:$12,x                 ; 03/0564: 74 12
entry_030566:
    adc z:$12,x                 ; 03/0566: 75 12
entry_030568:
    ror z:$12,x                 ; 03/0568: 76 12
entry_03056A:
    adc [$12],y                 ; 03/056A: 77 12
entry_03056C:
    sei                         ; 03/056C: 78
entry_03056D:
    adc a:$3412,y               ; 03/056D: 79 12 34
entry_030570:
    ply                         ; 03/0570: 7A
entry_030571:
    tdc                         ; 03/0571: 7B
entry_030572:
    jmp ($3412,x)               ; 03/0572: 7C 12 34
entry_030575:
    adc a:$3412,x               ; 03/0575: 7D 12 34
entry_030578:
    ror a:$3412,x               ; 03/0578: 7E 12 34 ; unknown-target store (assumed not to modify code)
entry_03057B:
    adc f:$563412,x             ; 03/057B: 7F 12 34 56
entry_03057F:
    bra entry_030581            ; 03/057F: 80 00
entry_030581:
    sta ($12,x)                 ; 03/0581: 81 12 ; unknown-target store (assumed not to modify code)
entry_030583:
    brl entry_030586            ; 03/0583: 82 00 00
entry_030586:
    sta $12,s                   ; 03/0586: 83 12
entry_030588:
    sty z:$12                   ; 03/0588: 84 12
entry_03058A:
    sta z:$12                   ; 03/058A: 85 12
entry_03058C:
    stx z:$12                   ; 03/058C: 86 12
entry_03058E:
    sta [$12]                   ; 03/058E: 87 12 ; unknown-target store (assumed not to modify code)
entry_030590:
    dey                         ; 03/0590: 88
entry_030591:
    bit #$12                    ; 03/0591: 89 12
entry_030593:
    txa                         ; 03/0593: 8A
entry_030594:
    phb                         ; 03/0594: 8B
entry_030595:
    sty a:$3412                 ; 03/0595: 8C 12 34
entry_030598:
    sta a:$3412                 ; 03/0598: 8D 12 34
entry_03059B:
    stx a:$3412                 ; 03/059B: 8E 12 34
entry_03059E:
    sta f:$563412               ; 03/059E: 8F 12 34 56
entry_0305A2:
    bcc entry_0305A4            ; 03/05A2: 90 00
entry_0305A4:
    sta ($12),y                 ; 03/05A4: 91 12 ; unknown-target store (assumed not to modify code)
entry_0305A6:
    sta ($12)                   ; 03/05A6: 92 12 ; unknown-target store (assumed not to modify code)
entry_0305A8:
    sta ($12,s),y               ; 03/05A8: 93 12 ; unknown-target store (assumed not to modify code)
entry_0305AA:
    sty z:$12,x                 ; 03/05AA: 94 12
entry_0305AC:
    sta z:$12,x                 ; 03/05AC: 95 12
entry_0305AE:
    stx z:$12,y                 ; 03/05AE: 96 12
entry_0305B0:
    sta [$12],y                 ; 03/05B0: 97 12 ; unknown-target store (assumed not to modify code)
entry_0305B2:
    tya                         ; 03/05B2: 98
entry_0305B3:
    sta a:$3412,y               ; 03/05B3: 99 12 34 ; unknown-target store (assumed not to modify code)
entry_0305B6:
    txs                         ; 03/05B6: 9A
entry_0305B7:
    txy                         ; 03/05B7: 9B
entry_0305B8:
    stz a:$3412                 ; 03/05B8: 9C 12 34
entry_0305BB:
    sta a:$3412,x               ; 03/05BB: 9D 12 34 ; unknown-target store (assumed not to modify code)
entry_0305BE:
    stz a:$3412,x               ; 03/05BE: 9E 12 34 ; unknown-target store (assumed not to modify code)
entry_0305C1:
    sta f:$563412,x             ; 03/05C1: 9F 12 34 56
entry_0305C5:
    ldy #$3412                  ; 03/05C5: A0 12 34
entry_0305C8:
    lda ($12,x)                 ; 03/05C8: A1 12
entry_0305CA:
    ldx #$3412                  ; 03/05CA: A2 12 34
entry_0305CD:
    lda $12,s                   ; 03/05CD: A3 12
entry_0305CF:
    ldy z:$12                   ; 03/05CF: A4 12
entry_0305D1:
    lda z:$12                   ; 03/05D1: A5 12
entry_0305D3:
    ldx z:$12                   ; 03/05D3: A6 12
entry_0305D5:
    lda [$12]                   ; 03/05D5: A7 12
entry_0305D7:
    tay                         ; 03/05D7: A8
entry_0305D8:
    lda #$12                    ; 03/05D8: A9 12
entry_0305DA:
    tax                         ; 03/05DA: AA
entry_0305DB:
    plb                         ; 03/05DB: AB
entry_0305DC:
    ldy a:$3412                 ; 03/05DC: AC 12 34
entry_0305DF:
    lda a:$3412                 ; 03/05DF: AD 12 34
entry_0305E2:
    ldx a:$3412                 ; 03/05E2: AE 12 34
entry_0305E5:
    lda f:$563412               ; 03/05E5: AF 12 34 56
entry_0305E9:
    bcs entry_0305EB            ; 03/05E9: B0 00
entry_0305EB:
    lda ($12),y                 ; 03/05EB: B1 12
entry_0305ED:
    lda ($12)                   ; 03/05ED: B2 12
entry_0305EF:
    lda ($12,s),y               ; 03/05EF: B3 12
entry_0305F1:
    ldy z:$12,x                 ; 03/05F1: B4 12
entry_0305F3:
    lda z:$12,x                 ; 03/05F3: B5 12
entry_0305F5:
    ldx z:$12,y                 ; 03/05F5: B6 12
entry_0305F7:
    lda [$12],y                 ; 03/05F7: B7 12
entry_0305F9:
    clv                         ; 03/05F9: B8
entry_0305FA:
    lda a:$3412,y               ; 03/05FA: B9 12 34
entry_0305FD:
    tsx                         ; 03/05FD: BA
entry_0305FE:
    tyx                         ; 03/05FE: BB
entry_0305FF:
    ldy a:$3412,x               ; 03/05FF: BC 12 34
entry_030602:
    lda a:$3412,x               ; 03/0602: BD 12 34
entry_030605:
    ldx a:$3412,y               ; 03/0605: BE 12 34
entry_030608:
    lda f:$563412,x             ; 03/0608: BF 12 34 56
entry_03060C:
    cpy #$3412                  ; 03/060C: C0 12 34
entry_03060F:
    cmp ($12,x)                 ; 03/060F: C1 12
entry_030611:
    rep #$12                    ; 03/0611: C2 12
entry_030613:
    cmp $12,s                   ; 03/0613: C3 12
entry_030615:
    cpy z:$12                   ; 03/0615: C4 12
entry_030617:
    cmp z:$12                   ; 03/0617: C5 12
entry_030619:
    dec z:$12                   ; 03/0619: C6 12
entry_03061B:
    cmp [$12]                   ; 03/061B: C7 12
entry_03061D:
    iny                         ; 03/061D: C8
entry_03061E:
    cmp #$12                    ; 03/061E: C9 12
entry_030620:
    dex                         ; 03/0620: CA
entry_030621:
    wai                         ; 03/0621: CB
entry_030622:
    cpy a:$3412                 ; 03/0622: CC 12 34
entry_030625:
    cmp a:$3412                 ; 03/0625: CD 12 34
entry_030628:
    dec a:$3412                 ; 03/0628: CE 12 34
entry_03062B:
    cmp f:$563412               ; 03/062B: CF 12 34 56
entry_03062F:
    bne entry_030631            ; 03/062F: D0 00
entry_030631:
    cmp ($12),y                 ; 03/0631: D1 12
entry_030633:
    cmp ($12)                   ; 03/0633: D2 12
entry_030635:
    cmp ($12,s),y               ; 03/0635: D3 12
entry_030637:
    pei ($12)                   ; 03/0637: D4 12
entry_030639:
    cmp z:$12,x                 ; 03/0639: D5 12
entry_03063B:
    dec z:$12,x                 ; 03/063B: D6 12
entry_03063D:
    cmp [$12],y                 ; 03/063D: D7 12
entry_03063F:
    cld                         ; 03/063F: D8
entry_030640:
    cmp a:$3412,y               ; 03/0640: D9 12 34
entry_030643:
    phx                         ; 03/0643: DA
entry_030644:
    stp                         ; 03/0644: DB
entry_030645:
    jml [$3412]                 ; 03/0645: DC 12 34
entry_030648:
    cmp a:$3412,x               ; 03/0648: DD 12 34
entry_03064B:
    dec a:$3412,x               ; 03/064B: DE 12 34 ; unknown-target store (assumed not to modify code)
entry_03064E:
    cmp f:$563412,x             ; 03/064E: DF 12 34 56
entry_030652:
    cpx #$3412                  ; 03/0652: E0 12 34
entry_030655:
    sbc ($12,x)                 ; 03/0655: E1 12
entry_030657:
    sep #$12                    ; 03/0657: E2 12
entry_030659:
    sbc $12,s                   ; 03/0659: E3 12
entry_03065B:
    cpx z:$12                   ; 03/065B: E4 12
entry_03065D:
    sbc z:$12                   ; 03/065D: E5 12
entry_03065F:
    inc z:$12                   ; 03/065F: E6 12
entry_030661:
    sbc [$12]                   ; 03/0661: E7 12
entry_030663:
    inx                         ; 03/0663: E8
entry_030664:
    sbc #$12                    ; 03/0664: E9 12
entry_030666:
    nop                         ; 03/0666: EA
entry_030667:
    xba                         ; 03/0667: EB
entry_030668:
    cpx a:$3412                 ; 03/0668: EC 12 34
entry_03066B:
    sbc a:$3412                 ; 03/066B: ED 12 34
entry_03066E:
    inc a:$3412                 ; 03/066E: EE 12 34
entry_030671:
    sbc f:$563412               ; 03/0671: EF 12 34 56
entry_030675:
    beq entry_030677            ; 03/0675: F0 00
entry_030677:
    sbc ($12),y                 ; 03/0677: F1 12
entry_030679:
    sbc ($12)                   ; 03/0679: F2 12
entry_03067B:
    sbc ($12,s),y               ; 03/067B: F3 12
entry_03067D:
    pea $3412                   ; 03/067D: F4 12 34
entry_030680:
    sbc z:$12,x                 ; 03/0680: F5 12
entry_030682:
    inc z:$12,x                 ; 03/0682: F6 12
entry_030684:
    sbc [$12],y                 ; 03/0684: F7 12
entry_030686:
    sed                         ; 03/0686: F8
entry_030687:
    sbc a:$3412,y               ; 03/0687: F9 12 34
entry_03068A:
    plx                         ; 03/068A: FA
entry_03068B:
    xce                         ; 03/068B: FB
entry_03068C:
    jsr ($3412,x)               ; 03/068C: FC 12 34
entry_03068F:
    sbc a:$3412,x               ; 03/068F: FD 12 34
entry_030692:
    inc a:$3412,x               ; 03/0692: FE 12 34 ; unknown-target store (assumed not to modify code)
entry_030695:
    sbc f:$563412,x             ; 03/0695: FF 12 34 56
entry_030699:
    .a16
    .byte $00,$12               ; 03/0699: 00 12 brk $12
entry_03069B:
    ora ($12,x)                 ; 03/069B: 01 12
entry_03069D:
    cop $12                     ; 03/069D: 02 12
entry_03069F:
    ora $12,s                   ; 03/069F: 03 12
entry_0306A1:
    tsb z:$12                   ; 03/06A1: 04 12
entry_0306A3:
    ora z:$12                   ; 03/06A3: 05 12
entry_0306A5:
    asl z:$12                   ; 03/06A5: 06 12
entry_0306A7:
    ora [$12]                   ; 03/06A7: 07 12
entry_0306A9:
    php                         ; 03/06A9: 08
entry_0306AA:
    ora #$3412                  ; 03/06AA: 09 12 34
entry_0306AD:
    asl a                       ; 03/06AD: 0A
entry_0306AE:
    phd                         ; 03/06AE: 0B
entry_0306AF:
    tsb a:$3412                 ; 03/06AF: 0C 12 34
entry_0306B2:
    ora a:$3412                 ; 03/06B2: 0D 12 34
entry_0306B5:
    asl a:$3412                 ; 03/06B5: 0E 12 34
entry_0306B8:
    ora f:$563412               ; 03/06B8: 0F 12 34 56
entry_0306BC:
    bpl entry_0306BE            ; 03/06BC: 10 00
entry_0306BE:
    ora ($12),y                 ; 03/06BE: 11 12
entry_0306C0:
    ora ($12)                   ; 03/06C0: 12 12
entry_0306C2:
    ora ($12,s),y               ; 03/06C2: 13 12
entry_0306C4:
    trb z:$12                   ; 03/06C4: 14 12
entry_0306C6:
    ora z:$12,x                 ; 03/06C6: 15 12
entry_0306C8:
    asl z:$12,x                 ; 03/06C8: 16 12
entry_0306CA:
    ora [$12],y                 ; 03/06CA: 17 12
entry_0306CC:
    clc                         ; 03/06CC: 18
entry_0306CD:
    ora a:$3412,y               ; 03/06CD: 19 12 34
entry_0306D0:
    inc a                       ; 03/06D0: 1A
entry_0306D1:
    tcs                         ; 03/06D1: 1B
entry_0306D2:
    trb a:$3412                 ; 03/06D2: 1C 12 34
entry_0306D5:
    ora a:$3412,x               ; 03/06D5: 1D 12 34
entry_0306D8:
    asl a:$3412,x               ; 03/06D8: 1E 12 34 ; unknown-target store (assumed not to modify code)
entry_0306DB:
    ora f:$563412,x             ; 03/06DB: 1F 12 34 56
entry_0306DF:
    jsr $3412                   ; 03/06DF: 20 12 34
entry_0306E2:
    and ($12,x)                 ; 03/06E2: 21 12
entry_0306E4:
    jsl f:$563412               ; 03/06E4: 22 12 34 56
entry_0306E8:
    and $12,s                   ; 03/06E8: 23 12
entry_0306EA:
    bit z:$12                   ; 03/06EA: 24 12
entry_0306EC:
    and z:$12                   ; 03/06EC: 25 12
entry_0306EE:
    rol z:$12                   ; 03/06EE: 26 12
entry_0306F0:
    and [$12]                   ; 03/06F0: 27 12
entry_0306F2:
    plp                         ; 03/06F2: 28
entry_0306F3:
    and #$3412                  ; 03/06F3: 29 12 34
entry_0306F6:
    rol a                       ; 03/06F6: 2A
entry_0306F7:
    pld                         ; 03/06F7: 2B
entry_0306F8:
    bit a:$3412                 ; 03/06F8: 2C 12 34
entry_0306FB:
    and a:$3412                 ; 03/06FB: 2D 12 34
entry_0306FE:
    rol a:$3412                 ; 03/06FE: 2E 12 34
entry_030701:
    and f:$563412               ; 03/0701: 2F 12 34 56
entry_030705:
    bmi entry_030707            ; 03/0705: 30 00
entry_030707:
    and ($12),y                 ; 03/0707: 31 12
entry_030709:
    and ($12)                   ; 03/0709: 32 12
entry_03070B:
    and ($12,s),y               ; 03/070B: 33 12
entry_03070D:
    bit z:$12,x                 ; 03/070D: 34 12
entry_03070F:
    and z:$12,x                 ; 03/070F: 35 12
entry_030711:
    rol z:$12,x                 ; 03/0711: 36 12
entry_030713:
    and [$12],y                 ; 03/0713: 37 12
entry_030715:
    sec                         ; 03/0715: 38
entry_030716:
    and a:$3412,y               ; 03/0716: 39 12 34
entry_030719:
    dec a                       ; 03/0719: 3A
entry_03071A:
    tsc                         ; 03/071A: 3B
entry_03071B:
    bit a:$3412,x               ; 03/071B: 3C 12 34
entry_03071E:
    and a:$3412,x               ; 03/071E: 3D 12 34
entry_030721:
    rol a:$3412,x               ; 03/0721: 3E 12 34 ; unknown-target store (assumed not to modify code)
entry_030724:
    and f:$563412,x             ; 03/0724: 3F 12 34 56
entry_030728:
    rti                         ; 03/0728: 40
entry_030729:
    eor ($12,x)                 ; 03/0729: 41 12
entry_03072B:
    .byte $42,$12               ; 03/072B: 42 12 wdm $12
entry_03072D:
    eor $12,s                   ; 03/072D: 43 12
entry_03072F:
    mvp #$34,#$12               ; 03/072F: 44 12 34
entry_030732:
    eor z:$12                   ; 03/0732: 45 12
entry_030734:
    lsr z:$12                   ; 03/0734: 46 12
entry_030736:
    eor [$12]                   ; 03/0736: 47 12
entry_030738:
    pha                         ; 03/0738: 48
entry_030739:
    eor #$3412                  ; 03/0739: 49 12 34
entry_03073C:
    lsr a                       ; 03/073C: 4A
entry_03073D:
    phk                         ; 03/073D: 4B
entry_03073E:
    jmp $3412                   ; 03/073E: 4C 12 34
entry_030741:
    eor a:$3412                 ; 03/0741: 4D 12 34
entry_030744:
    lsr a:$3412                 ; 03/0744: 4E 12 34
entry_030747:
    eor f:$563412               ; 03/0747: 4F 12 34 56
entry_03074B:
    bvc entry_03074D            ; 03/074B: 50 00
entry_03074D:
    eor ($12),y                 ; 03/074D: 51 12
entry_03074F:
    eor ($12)                   ; 03/074F: 52 12
entry_030751:
    eor ($12,s),y               ; 03/0751: 53 12
entry_030753:
    mvn #$34,#$12               ; 03/0753: 54 12 34
entry_030756:
    eor z:$12,x                 ; 03/0756: 55 12
entry_030758:
    lsr z:$12,x                 ; 03/0758: 56 12
entry_03075A:
    eor [$12],y                 ; 03/075A: 57 12
entry_03075C:
    cli                         ; 03/075C: 58
entry_03075D:
    eor a:$3412,y               ; 03/075D: 59 12 34
entry_030760:
    phy                         ; 03/0760: 5A
entry_030761:
    tcd                         ; 03/0761: 5B
entry_030762:
    jml f:$563412               ; 03/0762: 5C 12 34 56
entry_030766:
    eor a:$3412,x               ; 03/0766: 5D 12 34
entry_030769:
    lsr a:$3412,x               ; 03/0769: 5E 12 34 ; unknown-target store (assumed not to modify code)
entry_03076C:
    eor f:$563412,x             ; 03/076C: 5F 12 34 56
entry_030770:
    rts                         ; 03/0770: 60
entry_030771:
    adc ($12,x)                 ; 03/0771: 61 12
entry_030773:
    per entry_030776            ; 03/0773: 62 00 00
entry_030776:
    adc $12,s                   ; 03/0776: 63 12
entry_030778:
    stz z:$12                   ; 03/0778: 64 12
entry_03077A:
    adc z:$12                   ; 03/077A: 65 12
entry_03077C:
    ror z:$12                   ; 03/077C: 66 12
entry_03077E:
    adc [$12]                   ; 03/077E: 67 12
entry_030780:
    pla                         ; 03/0780: 68
entry_030781:
    adc #$3412                  ; 03/0781: 69 12 34
entry_030784:
    ror a                       ; 03/0784: 6A
entry_030785:
    rtl                         ; 03/0785: 6B
entry_030786:
    jmp ($3412)                 ; 03/0786: 6C 12 34
entry_030789:
    adc a:$3412                 ; 03/0789: 6D 12 34
entry_03078C:
    ror a:$3412                 ; 03/078C: 6E 12 34
entry_03078F:
    adc f:$563412               ; 03/078F: 6F 12 34 56
entry_030793:
    bvs entry_030795            ; 03/0793: 70 00
entry_030795:
    adc ($12),y                 ; 03/0795: 71 12
entry_030797:
    adc ($12)                   ; 03/0797: 72 12
entry_030799:
    adc ($12,s),y               ; 03/0799: 73 12
entry_03079B:
    stz z:$12,x                 ; 03/079B: 74 12
entry_03079D:
    adc z:$12,x                 ; 03/079D: 75 12
entry_03079F:
    ror z:$12,x                 ; 03/079F: 76 12
entry_0307A1:
    adc [$12],y                 ; 03/07A1: 77 12
entry_0307A3:
    sei                         ; 03/07A3: 78
entry_0307A4:
    adc a:$3412,y               ; 03/07A4: 79 12 34
entry_0307A7:
    ply                         ; 03/07A7: 7A
entry_0307A8:
    tdc                         ; 03/07A8: 7B
entry_0307A9:
    jmp ($3412,x)               ; 03/07A9: 7C 12 34
entry_0307AC:
    adc a:$3412,x               ; 03/07AC: 7D 12 34
entry_0307AF:
    ror a:$3412,x               ; 03/07AF: 7E 12 34 ; unknown-target store (assumed not to modify code)
entry_0307B2:
    adc f:$563412,x             ; 03/07B2: 7F 12 34 56
entry_0307B6:
    bra entry_0307B8            ; 03/07B6: 80 00
entry_0307B8:
    sta ($12,x)                 ; 03/07B8: 81 12 ; unknown-target store (assumed not to modify code)
entry_0307BA:
    brl entry_0307BD            ; 03/07BA: 82 00 00
entry_0307BD:
    sta $12,s                   ; 03/07BD: 83 12
entry_0307BF:
    sty z:$12                   ; 03/07BF: 84 12
entry_0307C1:
    sta z:$12                   ; 03/07C1: 85 12
entry_0307C3:
    stx z:$12                   ; 03/07C3: 86 12
entry_0307C5:
    sta [$12]                   ; 03/07C5: 87 12 ; unknown-target store (assumed not to modify code)
entry_0307C7:
    dey                         ; 03/07C7: 88
entry_0307C8:
    bit #$3412                  ; 03/07C8: 89 12 34
entry_0307CB:
    txa                         ; 03/07CB: 8A
entry_0307CC:
    phb                         ; 03/07CC: 8B
entry_0307CD:
    sty a:$3412                 ; 03/07CD: 8C 12 34
entry_0307D0:
    sta a:$3412                 ; 03/07D0: 8D 12 34
entry_0307D3:
    stx a:$3412                 ; 03/07D3: 8E 12 34
entry_0307D6:
    sta f:$563412               ; 03/07D6: 8F 12 34 56
entry_0307DA:
    bcc entry_0307DC            ; 03/07DA: 90 00
entry_0307DC:
    sta ($12),y                 ; 03/07DC: 91 12 ; unknown-target store (assumed not to modify code)
entry_0307DE:
    sta ($12)                   ; 03/07DE: 92 12 ; unknown-target store (assumed not to modify code)
entry_0307E0:
    sta ($12,s),y               ; 03/07E0: 93 12 ; unknown-target store (assumed not to modify code)
entry_0307E2:
    sty z:$12,x                 ; 03/07E2: 94 12
entry_0307E4:
    sta z:$12,x                 ; 03/07E4: 95 12
entry_0307E6:
    stx z:$12,y                 ; 03/07E6: 96 12
entry_0307E8:
    sta [$12],y                 ; 03/07E8: 97 12 ; unknown-target store (assumed not to modify code)
entry_0307EA:
    tya                         ; 03/07EA: 98
entry_0307EB:
    sta a:$3412,y               ; 03/07EB: 99 12 34 ; unknown-target store (assumed not to modify code)
entry_0307EE:
    txs                         ; 03/07EE: 9A
entry_0307EF:
    txy                         ; 03/07EF: 9B
entry_0307F0:
    stz a:$3412                 ; 03/07F0: 9C 12 34
entry_0307F3:
    sta a:$3412,x               ; 03/07F3: 9D 12 34 ; unknown-target store (assumed not to modify code)
entry_0307F6:
    stz a:$3412,x               ; 03/07F6: 9E 12 34 ; unknown-target store (assumed not to modify code)
entry_0307F9:
    sta f:$563412,x             ; 03/07F9: 9F 12 34 56
entry_0307FD:
    ldy #$3412                  ; 03/07FD: A0 12 34
entry_030800:
    lda ($12,x)                 ; 03/0800: A1 12
entry_030802:
    ldx #$3412                  ; 03/0802: A2 12 34
entry_030805:
    lda $12,s                   ; 03/0805: A3 12
entry_030807:
    ldy z:$12                   ; 03/0807: A4 12
entry_030809:
    lda z:$12                   ; 03/0809: A5 12
entry_03080B:
    ldx z:$12                   ; 03/080B: A6 12
entry_03080D:
    lda [$12]                   ; 03/080D: A7 12
entry_03080F:
    tay                         ; 03/080F: A8
entry_030810:
    lda #$3412                  ; 03/0810: A9 12 34
entry_030813:
    tax                         ; 03/0813: AA
entry_030814:
    plb                         ; 03/0814: AB
entry_030815:
    ldy a:$3412                 ; 03/0815: AC 12 34
entry_030818:
    lda a:$3412                 ; 03/0818: AD 12 34
entry_03081B:
    ldx a:$3412                 ; 03/081B: AE 12 34
entry_03081E:
    lda f:$563412               ; 03/081E: AF 12 34 56
entry_030822:
    bcs entry_030824            ; 03/0822: B0 00
entry_030824:
    lda ($12),y                 ; 03/0824: B1 12
entry_030826:
    lda ($12)                   ; 03/0826: B2 12
entry_030828:
    lda ($12,s),y               ; 03/0828: B3 12
entry_03082A:
    ldy z:$12,x                 ; 03/082A: B4 12
entry_03082C:
    lda z:$12,x                 ; 03/082C: B5 12
entry_03082E:
    ldx z:$12,y                 ; 03/082E: B6 12
entry_030830:
    lda [$12],y                 ; 03/0830: B7 12
entry_030832:
    clv                         ; 03/0832: B8
entry_030833:
    lda a:$3412,y               ; 03/0833: B9 12 34
entry_030836:
    tsx                         ; 03/0836: BA
entry_030837:
    tyx                         ; 03/0837: BB
entry_030838:
    ldy a:$3412,x               ; 03/0838: BC 12 34
entry_03083B:
    lda a:$3412,x               ; 03/083B: BD 12 34
entry_03083E:
    ldx a:$3412,y               ; 03/083E: BE 12 34
entry_030841:
    lda f:$563412,x             ; 03/0841: BF 12 34 56
entry_030845:
    cpy #$3412                  ; 03/0845: C0 12 34
entry_030848:
    cmp ($12,x)                 ; 03/0848: C1 12
entry_03084A:
    rep #$12                    ; 03/084A: C2 12
entry_03084C:
    cmp $12,s                   ; 03/084C: C3 12
entry_03084E:
    cpy z:$12                   ; 03/084E: C4 12
entry_030850:
    cmp z:$12                   ; 03/0850: C5 12
entry_030852:
    dec z:$12                   ; 03/0852: C6 12
entry_030854:
    cmp [$12]                   ; 03/0854: C7 12
entry_030856:
    iny                         ; 03/0856: C8
entry_030857:
    cmp #$3412                  ; 03/0857: C9 12 34
entry_03085A:
    dex                         ; 03/085A: CA
entry_03085B:
    wai                         ; 03/085B: CB
entry_03085C:
    cpy a:$3412                 ; 03/085C: CC 12 34
entry_03085F:
    cmp a:$3412                 ; 03/085F: CD 12 34
entry_030862:
    dec a:$3412                 ; 03/0862: CE 12 34
entry_030865:
    cmp f:$563412               ; 03/0865: CF 12 34 56
entry_030869:
    bne entry_03086B            ; 03/0869: D0 00
entry_03086B:
    cmp ($12),y                 ; 03/086B: D1 12
entry_03086D:
    cmp ($12)                   ; 03/086D: D2 12
entry_03086F:
    cmp ($12,s),y               ; 03/086F: D3 12
entry_030871:
    pei ($12)                   ; 03/0871: D4 12
entry_030873:
    cmp z:$12,x                 ; 03/0873: D5 12
entry_030875:
    dec z:$12,x                 ; 03/0875: D6 12
entry_030877:
    cmp [$12],y                 ; 03/0877: D7 12
entry_030879:
    cld                         ; 03/0879: D8
entry_03087A:
    cmp a:$3412,y               ; 03/087A: D9 12 34
entry_03087D:
    phx                         ; 03/087D: DA
entry_03087E:
    stp                         ; 03/087E: DB
entry_03087F:
    jml [$3412]                 ; 03/087F: DC 12 34
entry_030882:
    cmp a:$3412,x               ; 03/0882: DD 12 34
entry_030885:
    dec a:$3412,x               ; 03/0885: DE 12 34 ; unknown-target store (assumed not to modify code)
entry_030888:
    cmp f:$563412,x             ; 03/0888: DF 12 34 56
entry_03088C:
    cpx #$3412                  ; 03/088C: E0 12 34
entry_03088F:
    sbc ($12,x)                 ; 03/088F: E1 12
entry_030891:
    sep #$12                    ; 03/0891: E2 12
entry_030893:
    sbc $12,s                   ; 03/0893: E3 12
entry_030895:
    cpx z:$12                   ; 03/0895: E4 12
entry_030897:
    sbc z:$12                   ; 03/0897: E5 12
entry_030899:
    inc z:$12                   ; 03/0899: E6 12
entry_03089B:
    sbc [$12]                   ; 03/089B: E7 12
entry_03089D:
    inx                         ; 03/089D: E8
entry_03089E:
    sbc #$3412                  ; 03/089E: E9 12 34
entry_0308A1:
    nop                         ; 03/08A1: EA
entry_0308A2:
    xba                         ; 03/08A2: EB
entry_0308A3:
    cpx a:$3412                 ; 03/08A3: EC 12 34
entry_0308A6:
    sbc a:$3412                 ; 03/08A6: ED 12 34
entry_0308A9:
    inc a:$3412                 ; 03/08A9: EE 12 34
entry_0308AC:
    sbc f:$563412               ; 03/08AC: EF 12 34 56
entry_0308B0:
    beq entry_0308B2            ; 03/08B0: F0 00
entry_0308B2:
    sbc ($12),y                 ; 03/08B2: F1 12
entry_0308B4:
    sbc ($12)                   ; 03/08B4: F2 12
entry_0308B6:
    sbc ($12,s),y               ; 03/08B6: F3 12
entry_0308B8:
    pea $3412                   ; 03/08B8: F4 12 34
entry_0308BB:
    sbc z:$12,x                 ; 03/08BB: F5 12
entry_0308BD:
    inc z:$12,x                 ; 03/08BD: F6 12
entry_0308BF:
    sbc [$12],y                 ; 03/08BF: F7 12
entry_0308C1:
    sed                         ; 03/08C1: F8
entry_0308C2:
    sbc a:$3412,y               ; 03/08C2: F9 12 34
entry_0308C5:
    plx                         ; 03/08C5: FA
entry_0308C6:
    xce                         ; 03/08C6: FB
entry_0308C7:
    jsr ($3412,x)               ; 03/08C7: FC 12 34
entry_0308CA:
    sbc a:$3412,x               ; 03/08CA: FD 12 34
entry_0308CD:
    inc a:$3412,x               ; 03/08CD: FE 12 34 ; unknown-target store (assumed not to modify code)
entry_0308D0:
    sbc f:$563412,x             ; 03/08D0: FF 12 34 56
