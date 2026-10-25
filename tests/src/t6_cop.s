; review repro RetroCodeMess 369ba08 (F3)
; 65816 native: COP returns (RTI to after the signature byte)
.p816
.a8
.i8
.org $2000
start: cop $05
  lda #1
  rts
