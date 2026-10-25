; GS/OS inline parameters: JSL $E100A8 is followed by a call number and a
; 4-byte parameter block pointer (--platform gsos); $E10000 (toolbox) has none.
.p816
.org $2000
start:  clc
        xce
        rep #$30
        .a16
        .i16
        jsl $E100A8
        .word $2010             ; Open
        .dword parms
        bcs err
        ldx #$0E03
        jsl $E10000             ; toolbox call: no inline bytes
        jsl myprint
        .byte "Hi", 0           ; inline hint: 3 bytes
        lda #$0000
err:    rtl
myprint: rtl
parms:  .word 2, 0, 0
