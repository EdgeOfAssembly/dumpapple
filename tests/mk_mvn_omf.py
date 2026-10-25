#!/usr/bin/env python3
# From the RetroCodeMess review of dumpapple b5925fb (reviewer repro mk_mvn_omf.py).
"""Synthetic OMF v2 (one code segment): ldx/ldy/lda then MVN whose two bank
bytes carry 1-byte (shift -16) RELOC records at +1 and +2, as the IIgs linker
emits for `mvn ^dst,^src`.  Then more code.  Writes mvn_reloc.omf."""
import struct, sys
OP = 0x44 if (len(sys.argv) > 2 and sys.argv[2] == "mvp") else 0x54
code = bytes([0xA2,0x20,0x00,  0xA0,0x30,0x00,  0xA9,0x03,0x00,   # ldx #src  ldy #dst  lda #3
              OP,0x00,0x00,                                   # mvn dstbank,srcbank (relocated)
              0xEA, 0x60]) + bytes(0x40 - 14)                   # nop rts, then buffers
mvn = 9
recs = b'\xF2' + struct.pack('<I', len(code)) + code
for off, val in ((mvn + 1, 0x30), (mvn + 2, 0x20)):            # dest bank, src bank
    recs += b'\xE2' + bytes([1, 0xF0]) + struct.pack('<II', off, val)
# a normal 2-byte reloc on ldx operand too (aligned, must be accepted)
recs += b'\xE2' + bytes([2, 0]) + struct.pack('<II', 1, 0x20)
recs += b'\x00'
segname = b'\x04CODE'; loadname = b'TEST      '
hdrlen = 44 + len(loadname) + len(segname)
hdr = struct.pack('<IIIBBBBIHHIIBBHIHH', 0, 0, len(code), 0, 0, 4, 2, 0x10000, 0x0000, 0, 0, 0, 0, 0, 1, 0, 44, hdrlen)
seg = hdr + loadname + segname + recs
seg = struct.pack('<I', len(seg)) + seg[4:]
open(sys.argv[1] if len(sys.argv) > 1 else 'mvn_reloc.omf', 'wb').write(seg)
# dumpapple addition: expected relocated image at the default base $020000
out = sys.argv[1] if len(sys.argv) > 1 else 'mvn_reloc.omf'
exp = bytearray(code); exp[mvn + 1] = exp[mvn + 2] = 0x02; exp[1:3] = struct.pack('<H', 0x0020)
open(out[:-4] + '.expected' if out.endswith('.omf') else out + '.expected', 'wb').write(exp)
