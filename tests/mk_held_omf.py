#!/usr/bin/env python3
"""Synthetic OMF v2 code segment: four jsr $3000 calls each followed by text+$00
(held back as unknown-return bytes) and a relocated .word pointing into the
third site's bytes.  Variant 'jsl' also reaches those bytes through a relocated
jsl (code use: must be decoded); variant 'data' has only the data pointer
(must stay data, with a note).  Usage: mk_held_omf.py OUT.omf jsl|data"""
import struct, sys
out, var = sys.argv[1], sys.argv[2]
code = bytearray(0x34)
code[0x00:0x09] = bytes([0x20,0x10,0x00, 0x20,0x18,0x00, 0x20,0x28,0x00])   # jsr s1 / s2 / s4
code[0x09:0x0D] = bytes([0x22,0x23,0x00,0x00]) if var == 'jsl' else bytes([0x20,0x20,0x00,0x60])  # jsl s3+3 | jsr s3; rts
code[0x0D] = 0x60
for o, t in ((0x10, b'AB'), (0x18, b'CD'), (0x20, b'EF'), (0x28, b'GH')):
    code[o:o + 7] = bytes([0x20,0x00,0x30]) + t + b'\0' + b'\x60'
code[0x30:0x32] = struct.pack('<H', 0x23)                                     # .word s3+3 (relocated)
relocs = [(1, 2, 0x10), (4, 2, 0x18), (7, 2, 0x28), (0x30, 2, 0x23)]
relocs.append((0x0A, 3, 0x23) if var == 'jsl' else (0x0A, 2, 0x20))
recs = b'\xF2' + struct.pack('<I', len(code)) + bytes(code)
for off, n, val in relocs: recs += b'\xE2' + bytes([n, 0]) + struct.pack('<II', off, val)
recs += b'\x00'
segname = b'\x04CODE'; loadname = b'TEST      '
hdrlen = 44 + len(loadname) + len(segname)
hdr = struct.pack('<IIIBBBBIHHIIBBHIHH', 0, 0, len(code), 0, 0, 4, 2, 0x10000, 0x0000, 0, 0, 0, 0, 0, 1, 0, 44, hdrlen)
seg = hdr + loadname + segname + recs
open(out, 'wb').write(struct.pack('<I', len(seg)) + seg[4:])
# expected relocated image at the default base $020000
exp = bytearray(code)
for off, n, val in relocs: exp[off:off + n] = (0x020000 + val).to_bytes(4, 'little')[:n]
open(out[:-4] + '.expected', 'wb').write(exp)
