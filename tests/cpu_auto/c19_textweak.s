; negative: code falls into a high-ASCII message whose bytes include plb/phd/xba ($AB $0B $EB
; are not text but sit among it): weak bytes in text are no evidence.
.setcpu "65C02"
.org $2000
        jsr $FDED
        ora #$EA
        .byte $AB,$BF,$BE,$A5,$CA,$BF,$C1,$EB,$C2,$C3,$C4,$0B,$C5,$C6,$C7,$C8,$C9,$60
