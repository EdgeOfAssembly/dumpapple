#!/bin/sh
# Assemble the synthetic test programs (tests/src/*.s) to raw binaries in tests/progs.
# Each .s starts with ".org ADDR"; the binary is the bytes from that address on.
set -e
cd "$(dirname "$0")"
mkdir -p progs
for s in src/*.s; do
    n=$(basename "$s" .s)
    org=$(sed -n 's/^\.org \(\$[0-9A-Fa-f]*\).*/\1/p' "$s" | head -1)
    ca65 --cpu 65816 -t none -o "progs/$n.o" "$s"
    printf 'MEMORY { M: start=%s, size=$10000, file=%%O; }\nSEGMENTS { CODE: load=M, type=rw; }\n' "$org" > "progs/$n.cfg"
    ld65 -C "progs/$n.cfg" -o "progs/$n.bin" "progs/$n.o"
    echo "$org" > "progs/$n.org"
    rm -f "progs/$n.o" "progs/$n.cfg"
done
