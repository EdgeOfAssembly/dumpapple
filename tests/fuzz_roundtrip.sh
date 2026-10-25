#!/bin/sh
# Random raw images (bias toward 65816 width-changing opcodes) must always
# rebuild byte-identical through dumpapple --verify.
N=${1:-300}
cd "$(dirname "$0")/.."
# T2: test the binary we are given (arg 2 or $DA), not a hard-coded one
DA=${2:-${DA:-./dumpapple}}
[ -x "$DA" ] || command -v "$DA" >/dev/null || { echo "fuzz-roundtrip: no binary $DA"; exit 2; }
FAILDIR=tests/out/fuzz-roundtrip; mkdir -p "$FAILDIR"
T=$(mktemp -d)
fail=0
i=0
while [ $i -lt "$N" ]; do
    python3 - "$T/r.bin" $i <<'P'
import random, sys
r = random.Random(int(sys.argv[2]))
hot = [0xC2,0xE2,0x18,0x38,0xFB,0x08,0x28,0xA9,0xA2,0xA0,0x09,0xE0,0x80,0xD0,0x82,0x20,0x22,0x4C,0x5C,0x62,0x54,0x44,0xF4]
n = r.randint(1, 700)
b = bytes(r.choice(hot) if r.random() < 0.4 else r.randrange(256) for _ in range(n))
open(sys.argv[1], "wb").write(b)
P
    org=$(python3 -c "import random;r=random.Random($i);print('%06X'%r.choice([0x2000,0x0,0xFF00,0x021000,0x7FFF80,0xFFFD00]))")
    st=$(python3 -c "import random;r=random.Random($i);print(r.choice(['e','m8x8','m16x16','m8x16','m16x8']))")
    cpu=$(python3 -c "import random;r=random.Random($i*7);print(r.choice(['65816','65816','65c02','6502']))")
    [ "$cpu" != 65816 ] && org=$(python3 -c "import random;r=random.Random($i);print('%04X'%r.choice([0x2000,0x0,0xF000,0x0800]))")
    # H2: rebuild the listing ourselves and compare bytes; --verify's exit code is not trusted
    why=""
    if ! "$DA" -q --cpu $cpu --org "$org" --state "$st" -o "$T/r.s" "$T/r.bin" 2>"$T/err"; then why="dumpapple exit $?"
    elif [ ! -s "$T/r.s" ] || [ ! -s "$T/r.cfg" ]; then why="no listing/cfg written"
    elif ! ca65 --cpu 65816 -t none -o "$T/r.o" "$T/r.s" 2>>"$T/err"; then why="ca65 failed"
    elif ! ld65 -C "$T/r.cfg" -o "$T/rb.bin" "$T/r.o" 2>>"$T/err"; then why="ld65 failed"
    elif ! cmp -s "$T/r.bin" "$T/rb.bin"; then why="rebuild differs"
    fi
    if [ -n "$why" ]; then
        # I1: keep failures under tests/out/, not /tmp
        echo "FAIL iter $i cpu $cpu org $org state $st: $why"; head -3 "$T/err"
        cp "$T/r.bin" "$FAILDIR/rtfail-$i.bin"; [ -f "$T/r.s" ] && cp "$T/r.s" "$FAILDIR/rtfail-$i.s"
        fail=$((fail+1))
    fi
    rm -f "$T/r.s" "$T/r.cfg" "$T/r.o" "$T/rb.bin"
    i=$((i+1))
done
rm -rf "$T"
echo "fuzz-roundtrip: $N iterations, $fail failures ($DA)"
[ $fail -eq 0 ]
