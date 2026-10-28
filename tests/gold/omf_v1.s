; dumpapple 0.10.0 listing of tests/omf/fixture_v1.omf
; cpu 65816, platform gsos
; rebuild: ca65 --cpu 65816 -t none -o omf_v1.o omf_v1.s
;          ld65 -C omf_v1.cfg -o omf_v1.bin omf_v1.o
; input: OMF v1 load file; output is the relocated loaded image, segments in file order

.setcpu "65816"

; ------------------------------------------------------------
; segment 1 "MAIN" load "" kind $0000 org $0 entry +$0
; base $020000 length $50
.segment "SEG1"
.org $020000
entry_020000:
    .a16
    .i16
    rep #$30                    ; 02/0000: C2 30
    lda #$1234                  ; 02/0002: A9 34 12
    jsl sub_030000              ; 02/0005: 22 00 00 03 [reloc inter 3@+1 -> seg 2+$0]
    lda a:$0030                 ; 02/0009: AD 30 00 [reloc 2@+1 -> seg 1+$30]
    lda f:$020030               ; 02/000C: AF 30 00 02 [reloc 3@+1 -> seg 1+$30]
    ldx #$0004                  ; 02/0010: A2 04 00 [reloc inter 2@+1 -> seg 3+$0] >>16
    ldy #$0004                  ; 02/0013: A0 04 00 [reloc inter 2@+1 -> seg 3+$4]
    pea $0004                   ; 02/0016: F4 04 00 [reloc inter 2@+1 -> seg 3+$0] >>16
    jml L020020                 ; 02/0019: 5C 20 00 02 [reloc 3@+1 -> seg 1+$20]
    .byte $EA,$EA,$EA           ; 02/001D
L020020:
    lda a:$0030                 ; 02/0020: AD 30 00 [reloc 2@+1 -> seg 1+$30]
    jsl sub_030004              ; 02/0023: 22 04 00 03 [reloc inter 3@+1 -> seg 2+$4]
    rtl                         ; 02/0027: 6B
    .byte $C1,$D0,$D0,$CC,$C5,$A0,$C9,$C9 ; 02/0028 hi-ascii "APPLE II"
    .byte $11,$11,$22,$22       ; 02/0030
    .res 28                     ; 02/0034

; ------------------------------------------------------------
; segment 2 "SUB" load "" kind $0000 org $0 entry +$0
; base $030000 length $7
.segment "SEG2"
.org $030000
sub_030000:
    .a16
    .i16
    sep #$20                    ; 03/0000: E2 20
    .a8
    lda #$12                    ; 03/0002: A9 12
sub_030004:
    rep #$20                    ; 03/0004: C2 20
    .a16
    rtl                         ; 03/0006: 6B

; ------------------------------------------------------------
; segment 3 "DATA" load "" kind $0001 org $0 entry +$0
; base $040000 length $27
.segment "SEG3"
.org $040000
    .byte "Hello!"              ; 04/0000
    .res 33                     ; 04/0006
