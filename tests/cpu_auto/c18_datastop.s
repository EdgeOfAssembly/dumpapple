; negative: a data file read as code: the 65C02 decode stops on $44 (mvp on a 65816); the
; 65816 decode runs on into the data and meets $22 (jsl). A weak first hit does not vouch for it.
.setcpu "65C02"
.org $2000
        .byte $66,$E0,$11,$02,$44,$08,$10,$22,$40,$00,$01,$02,$00,$08,$10,$20,$06,$00
