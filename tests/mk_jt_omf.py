#!/usr/bin/env python3
# From the RetroCodeMess review of dumpapple 5ab81a2 (reviewer repro mk_jt_omf.py).
"""Synthetic OMF v2 load file: seg1 static code (JSLs into the jump table),
seg2 KIND $02 jump-table segment, seg3 dynamic code (KIND $8000) whose two
routines are reachable only through jump-table entries, seg4 ~ExpressLoad-like
($8001 data) whose bytes look like code.  Writes the file given as argv[1]."""
import struct, sys
def seg(num, kind, name, body, recs=b'', entry=0):
    data = b'\xF2' + struct.pack('<I', len(body)) + body + recs + b'\x00'
    segname = bytes([len(name)]) + name; loadname = b'TEST      '
    hdrlen = 44 + len(loadname) + len(segname)
    hdr = struct.pack('<IIIBBBBIHHIIBBHIHH', 0, 0, len(body), 0, 0, 4, 2, 0x10000, kind, 0, 0, 0, 0, 0, num, entry, 44, hdrlen)
    s = hdr + loadname + segname + data
    return struct.pack('<I', len(s)) + s[4:]
def interseg(off, n, shift, fileno, segno, val):   # INTERSEG record $E3
    return b'\xE3' + bytes([n, shift & 255]) + struct.pack('<IHHI', off, fileno, segno, val)
# seg1: jsl jt_entry0 ; jsl jt_entry1 ; rtl     (relocated to seg2)
s1 = bytes([0x22, 18, 0, 0, 0x22, 32, 0, 0, 0x6B])
r1 = interseg(1, 3, 0, 1, 3, 8 + 10) + interseg(5, 3, 0, 1, 3, 8 + 14 + 10)   # calls land on each entry's JSL-to-loader
# seg2: KIND $02 jump table: 8 zero bytes, entries {userID 2, loadseg 2, offset 4, JSL loader 4}, 4 zero terminator


s2 = bytes(8) + struct.pack("<HHHI", 0, 1, 4, 0) + bytes([0x22,0,0,0]) + struct.pack("<HHHI", 0, 1, 4, 6) + bytes([0x22,0,0,0]) + bytes(4)
# dumpapple addition (J1): argv[2] == "trunc" replaces the terminator with 6 bytes of a third entry
if len(sys.argv) > 2 and sys.argv[2] == "trunc": s2 = s2[:-4] + struct.pack("<HHH", 0, 1, 4)
# seg3 dynamic code: routine A at +0 (lda #1; rtl, m16), routine B at +6 (lda #2; nop; rtl)
s3 = bytes([0xA9, 1, 0, 0xEA, 0xEA, 0x6B, 0xA9, 2, 0, 0xEA, 0xEA, 0x6B])
# seg4 ExpressLoad-like data that decodes as code
s4 = bytes([0xA9, 0x00, 0x00, 0x8D, 0x00, 0x10, 0x60]) + bytes(9)
out = seg(1, 0x8001, b'~ExpressLoad', s4) + seg(2, 0x0000, b'MAIN', s1, r1) + seg(3, 0x0002, b'JUMPTABLE', s2) + seg(4, 0x8000, b'DYNCODE', s3)
open(sys.argv[1], 'wb').write(out)
# dumpapple addition: expected relocated image at the default base $020000, stride $10000
s1x = bytes([0x22, 0x12, 0x00, 0x04, 0x22, 0x20, 0x00, 0x04, 0x6B])
o = sys.argv[1]
open(o[:-4] + '.expected', 'wb').write(s4 + s1x + s2 + s3)
