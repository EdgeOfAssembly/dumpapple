; review repro RetroCodeMess 369ba08 (F4)
; 6502: lda #>t-1 / pha / lda #<t-1 / pha / rts ; and jmp ($20FF) page-wrap
.setcpu "6502"
.org $2000
start: lda #>(t1-1)
  pha
  lda #<(t1-1)
  pha
  rts
t1: jmp ($20FF)        ; NMOS: hi byte read from $2000, not $2100
  .res $20FF-*, $EA
  .byte <t2           ; $20FF
  .res $2100-*, 0
  .byte >t2           ; $2100 (what a 65C02 would read)
  .res $2180-*, 0
t2: rts
