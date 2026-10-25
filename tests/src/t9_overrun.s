; review repro RetroCodeMess 369ba08 (F1): table must stop before code reached later
; 65816: the code right after the table is only reached later (via an entry's
; JSR), and its first bytes ($20 $1x) happen to form an in-image address.
.p816
.a8
.i8
.org $2000
start: ldx #0
  jmp (tbl,x)
tbl: .word t_a, t_b
after: jsr t_b          ; bytes 20 xx 20: as a word = $2020 region, in-image
  rts
t_a: jsr after
  rts
  .res $2020-*, $EA
t_b: rts
