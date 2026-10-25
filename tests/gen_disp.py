#!/usr/bin/env python3
"""Dispatch-pattern fixtures (after the RetroCodeMess ce21145a4 review repro
disp.py / disp_omf.py): jmp (tbl,x), jsr (tbl,x) and the push-address-minus-1
+ RTS trick, as a raw image (org $2000) and as an OMF v2 load file whose table
words and operands are cRELOC'd.  v1 does not follow tables: these must
round-trip byte-identical; coverage is pinned in tests/baseline/."""
import struct, sys, os
d = sys.argv[1] if len(sys.argv) > 1 else "."
b = bytearray([0xEA] * 0x40)
b[0:4] = bytes([0x18, 0xFB, 0xC2, 0x30])          # clc; xce; rep #$30
b[4:7] = bytes([0xA2, 0, 0])                      # ldx #0
b[7:10] = bytes([0x7C, 0x20, 0x20])               # jmp ($2020,x)
b[0x0A:0x0E] = bytes([0xFC, 0x20, 0x20, 0x60])    # jsr ($2020,x); rts
b[0x0E:0x12] = bytes([0xF4, 0x27, 0x20, 0x60])    # pea $2027; rts  -> $2028
b[0x20:0x24] = bytes([0x30, 0x20, 0x38, 0x20])    # table: $2030, $2038
b[0x28:0x2C] = bytes([0xA9, 0x34, 0x12, 0x60])    # lda #$1234; rts
b[0x30:0x34] = bytes([0xA9, 0x11, 0x11, 0x60])
b[0x38:0x3C] = bytes([0xA2, 0x22, 0x22, 0x60])
open(os.path.join(d, "disp.bin"), "wb").write(b)
# OMF: segment-relative values; OMF entry is native m16x16 so drop clc/xce
c = bytearray(b); c[0:4] = b"\xEA\xEA\xC2\x30"
rel = ((0x20, 0x30), (0x22, 0x38), (0x08, 0x20), (0x0B, 0x20), (0x0F, 0x27))
for o, v in rel: c[o:o + 2] = struct.pack("<H", v)
body = bytes([0xF2]) + struct.pack("<I", len(c)) + bytes(c)
for o, v in rel: body += bytes([0xF5, 2, 0]) + struct.pack("<HH", o, v)
body += b"\x00"
names = b" " * 10 + bytes([4]) + b"CODE"
hdr = struct.pack("<IIIBBBBIHHIIBBHIHH", 0, 0, len(c), 0, 0, 4, 2, 0x10000, 0, 0, 0, 0, 0, 0, 1, 0, 0x2C, 0x2C + len(names))
assert len(hdr) == 0x2C
seg = bytearray(hdr + names + body)
seg[0:4] = struct.pack("<I", len(seg))
open(os.path.join(d, "disp.omf"), "wb").write(seg)
# expected relocated image at the default base $020000 (cRELOC size 2: low 16 bits of base+value)
e = bytearray(c)
for o, v in rel: e[o:o + 2] = struct.pack("<H", (0x020000 + v) & 0xFFFF)
open(os.path.join(d, "disp.expected"), "wb").write(e)

# disp2: all three patterns reachable in one flow (raw, org $2000, --cpu 65816)
q = bytearray([0xEA] * 0x64)
def put(o, bs): q[o:o + len(bs)] = bytes(bs)
put(0x00, [0x18, 0xFB, 0xC2, 0x30])     # clc; xce; rep #$30
put(0x04, [0xA2, 0x00, 0x00])           # ldx #0
put(0x07, [0xFC, 0x40, 0x20])           # jsr ($2040,x)   table A
put(0x0A, [0xA5, 0x00, 0xF0, 0x03])     # lda $00; beq $2011
put(0x0E, [0x7C, 0x44, 0x20])           # jmp ($2044,x)   table B
put(0x11, [0xF4, 0x1F, 0x20, 0x60])     # pea $201F; rts  -> $2020
put(0x20, [0x4B, 0xF4, 0x27, 0x20, 0x6B])  # phk; pea $2027; rtl -> $2028
put(0x28, [0xE2, 0x20, 0xA9, 0x20, 0x48, 0xA9, 0x30, 0x48, 0x60])  # sep #$20; lda #>; pha; lda #<; pha; rts -> $2031
put(0x31, [0xC2, 0x20, 0xDC, 0x48, 0x20])  # rep #$20; jml [$2048] -> $00205C
put(0x48, [0x5C, 0x20, 0x00])           # long pointer
put(0x5C, [0x60])                       # rts
put(0x40, [0x50, 0x20, 0x58, 0x20])     # table A: $2050, $2058
put(0x44, [0x60, 0x20])                 # table B: $2060
put(0x50, [0xA9, 0x11, 0x11, 0x60])
put(0x58, [0xA2, 0x22, 0x22, 0x60])
put(0x60, [0xA0, 0x33, 0x33, 0x60])
open(os.path.join(d, "disp2.bin"), "wb").write(q)

# gsos.omf: GS/OS inline parameters whose block pointer is relocated.  With
# --platform none the inline bytes decode as code and the relocation lands
# mid-instruction (misdecode check); with the default gsos they are data.
g = bytearray([0xC2, 0x30, 0x22, 0xA8, 0x00, 0xE1, 0x10, 0x20, 0x14, 0x00, 0x00, 0x00,
               0xA9, 0x00, 0x00, 0x6B, 0, 0, 0, 0, 0x02, 0x00, 0x00, 0x00])
gb = bytes([0xF2]) + struct.pack("<I", len(g)) + bytes(g)
gb += bytes([0xF5, 3, 0]) + struct.pack("<HH", 0x08, 0x14) + b"\x00"
gn = b" " * 10 + bytes([4]) + b"MAIN"
gh = struct.pack("<IIIBBBBIHHIIBBHIHH", 0, 0, len(g), 0, 0, 4, 2, 0x10000, 0, 0, 0, 0, 0, 0, 1, 0, 0x2C, 0x2C + len(gn))
gs = bytearray(gh + gn + gb)
gs[0:4] = struct.pack("<I", len(gs))
open(os.path.join(d, "gsos.omf"), "wb").write(gs)
ge = bytearray(g); ge[8:11] = struct.pack("<I", 0x020000 + 0x14)[:3]
open(os.path.join(d, "gsos.expected"), "wb").write(ge)

def omf_seg(num, kind, name, code, relocs, entry=0):
    """One OMF v2 load segment: LCONST + RELOC records (size, shift, off, value) + END."""
    body = bytes([0xF2]) + struct.pack("<I", len(code)) + bytes(code)
    for size, shift, off, val in relocs:
        body += bytes([0xE2, size, shift & 0xFF]) + struct.pack("<II", off, val)
    body += b"\x00"
    nm = b" " * 10 + bytes([len(name)]) + name
    hd = struct.pack("<IIIBBBBIHHIIBBHIHH", 0, 0, len(code), 0, 0, 4, 2, 0x10000, kind, 0, 0, 0, 0, 0, num, entry, 0x2C, 0x2C + len(nm))
    sg = bytearray(hd + nm + body)
    sg[0:4] = struct.pack("<I", len(sg))
    return bytes(sg)

# mvn.omf: MVN/MVP whose bank operands carry 1-byte relocations (shift -16).
mv = bytearray([0xC2, 0x30,                 # 0000 rep #$30
                0xA9, 0x03, 0x00,           # 0002 lda #3
                0xA2, 0x20, 0x00,           # 0005 ldx #src
                0xA0, 0x24, 0x00,           # 0008 ldy #dst
                0x54, 0x00, 0x00,           # 000B mvn #^src,#^dst  (bytes: dst, src)
                0x44, 0x00, 0x00,           # 000E mvp
                0x6B])                      # 0011 rtl
mv += bytes([0xEA] * (0x20 - len(mv))) + b"ABCD" + bytes(4)
mvr = [(1, -16, 0x0C, 0x20), (1, -16, 0x0D, 0x24), (1, -16, 0x0F, 0x20), (1, -16, 0x10, 0x24)]
open(os.path.join(d, "mvn.omf"), "wb").write(omf_seg(1, 0, b"MAIN", mv, mvr))
mve = bytearray(mv)
for size, shift, off, val in mvr: mve[off] = ((0x020000 + val) >> 16) & 0xFF
open(os.path.join(d, "mvn.expected"), "wb").write(mve)

# dataseg.omf: a code segment, a second static code segment and a data
# segment (kind $0001) whose ENTRY bytes look like code.  Only the first
# static code segment's ENTRY seeds flow by default.
c1 = bytes([0xC2, 0x30, 0xA9, 0x01, 0x00, 0x6B])            # rep; lda #1; rtl
c2 = bytes([0xA9, 0x02, 0x00, 0x6B])                        # unreferenced code segment
dt = bytes([0xA9, 0x55, 0x00, 0x60, 0x12, 0x34])            # looks like lda/rts
ds = omf_seg(1, 0x0000, b"MAIN", c1, []) + omf_seg(2, 0x0000, b"OTHER", c2, []) + omf_seg(3, 0x0001, b"SHAPES", dt, [])
open(os.path.join(d, "dataseg.omf"), "wb").write(ds)
open(os.path.join(d, "dataseg.expected"), "wb").write(c1 + bytes(0) + c2 + dt)
# rsplit.omf: a 3-byte relocated field at offset $0F of a data run must not be
# split across the 16-byte .byte line boundary.
rs = bytes(range(1, 33))
rsr = [(3, 0, 0x0F, 0x10)]
open(os.path.join(d, "rsplit.omf"), "wb").write(omf_seg(1, 0x0001, b"DATA", rs, rsr))
rse = bytearray(rs); rse[0x0F:0x12] = struct.pack("<I", 0x020010)[:3]
open(os.path.join(d, "rsplit.expected"), "wb").write(rse)
