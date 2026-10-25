; dumpapple 0.9.0 listing of tests/omf/fixture_b.omf
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o omf_base.o omf_base.s
;          ld65 -C omf_base.cfg -o omf_base.bin omf_base.o
; input: OMF v2 load file; output is the relocated loaded image, segments in file order

.setcpu "65816"

; ------------------------------------------------------------
; segment 1 "MAIN" load "" kind $0000 org $0 entry +$0
; base $058000 length $50
.segment "SEG1"
.org $058000
entry_058000:
    .a16
    .i16
    rep #$30                    ; 05/8000: C2 30
    lda #$1234                  ; 05/8002: A9 34 12
    jsl sub_060000              ; 05/8005: 22 00 00 06 [reloc inter 3@+1 -> seg 2+$0]
    lda a:$8030                 ; 05/8009: AD 30 80 [reloc 2@+1 -> seg 1+$30]
    lda f:$058030               ; 05/800C: AF 30 80 05 [reloc 3@+1 -> seg 1+$30]
    ldx #$0007                  ; 05/8010: A2 07 00 [reloc inter 2@+1 -> seg 3+$0] >>16
    ldy #$0004                  ; 05/8013: A0 04 00 [reloc inter 2@+1 -> seg 3+$4]
    pea $0007                   ; 05/8016: F4 07 00 [reloc inter 2@+1 -> seg 3+$0] >>16
    jml L058020                 ; 05/8019: 5C 20 80 05 [reloc 3@+1 -> seg 1+$20]
    .byte $EA,$EA,$EA           ; 05/801D
L058020:
    lda a:$8030                 ; 05/8020: AD 30 80 [reloc 2@+1 -> seg 1+$30]
    jsl sub_060004              ; 05/8023: 22 04 00 06 [reloc inter 3@+1 -> seg 2+$4]
    rtl                         ; 05/8027: 6B
    .byte $C1,$D0,$D0,$CC,$C5,$A0,$C9,$C9 ; 05/8028 hi-ascii "APPLE II"
    .byte $11,$11,$22,$22       ; 05/8030
    .res 28                     ; 05/8034

; ------------------------------------------------------------
; segment 2 "SUB" load "" kind $0000 org $0 entry +$0
; base $060000 length $7
.segment "SEG2"
.org $060000
sub_060000:
    .a16
    .i16
    sep #$20                    ; 06/0000: E2 20
    .a8
    lda #$12                    ; 06/0002: A9 12
sub_060004:
    rep #$20                    ; 06/0004: C2 20
    .a16
    rtl                         ; 06/0006: 6B

; ------------------------------------------------------------
; segment 3 "DATA" load "" kind $0001 org $0 entry +$0
; base $070000 length $27
.segment "SEG3"
.org $070000
    .byte "Hello!"              ; 07/0000
    .res 33                     ; 07/0006
