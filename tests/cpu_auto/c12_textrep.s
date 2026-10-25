; negative: flow falls into a high-ASCII message holding $C2/$E2 (rep/sep on a 65816): text, not code.
.setcpu "65C02"
.org $2000
        lda #1
        .byte $C1,$C2,$C3,$E2,$C5,$C6,$C7,$C8,$C9,$CA,$60
