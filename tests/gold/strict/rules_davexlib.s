; dumpapple 0.9.0 listing of tests/progs/rules_davex.bin
; cpu 6502, platform none
; rebuild: ca65 --cpu 6502 -t none -o rules_davexlib.o rules_davexlib.s
;          ld65 -C rules_davexlib.cfg -o rules_davexlib.bin rules_davexlib.o

.setcpu "6502"

; ------------------------------------------------------------
; base $009000 length $D
.segment "SEG1"
.org $009000
entry_009000:
    jsr .loword(xmess)          ; 00/9000: 20 06 B0 ; returns past 3 inline bytes (zero-terminated)
; zero-terminated inline string after call to $00B006 (hint)
    .byte $4F,$4B,$00           ; 00/9003 "OK."
    jsr .loword(sub_009009)     ; 00/9006: 20 09 90
sub_009009:
    jmp .loword(xerr)           ; 00/9009: 4C 48 B0
    .byte $60                   ; 00/900C

; labels that do not start a listing line
xgetparm_ch = $00B000
xgetparm_n = $00B003
xmess = $00B006
xprint_ftype = $00B009
xprint_access = $00B00C
xprdec_2 = $00B00F
xprdec_3 = $00B012
xprdec_pad = $00B015
xprint_path = $00B018
xbuild_local = $00B01B
xprint_sd = $00B01E
xprint_drvr = $00B021
xredirect = $00B024
xpercent = $00B027
xyesno = $00B02A
xgetln = $00B02D
xbell = $00B030
xdowncase = $00B033
xplural = $00B036
xcheck_wait = $00B039
xpr_date_ay = $00B03C
xpr_time_ay = $00B03F
xProDOS_err = $00B042
xProDOS_er = $00B045
xerr = $00B048
xprdec_pady = $00B04B
xdir_setup = $00B04E
xdir_finish = $00B051
xread1dir = $00B054
xpmgr = $00B057
xmmgr = $00B05A
xpoll_io = $00B05D
xprint_ver = $00B060
xpush_level = $00B063
xfman_open = $00B066
xfman_read = $00B069
xrdkey = $00B06C
xdirty = $00B06F
xgetnump = $00B072
xyesno2 = $00B075
xdir_setup2 = $00B078
xshell_info = $00B07B
