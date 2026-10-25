#!/usr/bin/env python3
"""Second scorecard pass: re-run the gold-set entries that have a platform hint
library, with `--hints-lib NAME` added explicitly, and print a table comparing
default options with 'with platform hints'.  Run from a scorecard copy made by
`make scorecard` (needs manifest.json, out/, tools/score.py there).
Which library applies to which entry is fixed here by hand (no detection)."""
import json, os, subprocess, sys
G = sys.argv[1]; DA = sys.argv[2]
LIB = {  # entry id -> (hints library, var-inline target for the scorer)
    'davex_xtn_du': ('davex', 'B006'), 'davex_xtn_what': ('davex', 'B006'), 'davex_xtn_alias': ('davex', 'B006'),
}
man = json.load(open(os.path.join(G, 'manifest.json')))['entries']
rows = ['', '## With platform hints', '',
        'Default = the table above; hints = the same options plus `--hints-lib NAME` (shipped `hints/NAME.hints`), enabled explicitly per entry.', '',
        '| entry | hints lib | rebuild ok | coverage % default -> hints | false code B | bogus insns | fixed inline | var-len inline |',
        '|---|---|---|---|---|---|---|---|']
for e in man:
    r = e['result']
    lib = LIB.get(e['id'])
    if not lib:
        rows.append('| %s | - | %s | %.2f | %d | %d | %d/%d | %d/%d |' % (e['id'], 'yes' if r['verify_ok'] and r['independent_rebuild_ok'] else 'NO',
                    r['coverage'], r['false_code'], r['insn_starts_bogus'], r['inline_found'], r['inline_expected'], r['var_inline_found'], r['var_inline_expected']))
        continue
    cmd = e['dumpapple_cmd'].split()
    args = cmd[1:cmd.index('--verify')]
    d = os.path.dirname(os.path.join(G, e['binary'])); b = os.path.join(G, e['binary'])
    lst = os.path.join(d, 'da_hints.s')
    p = subprocess.run([DA] + args + ['--hints-lib', lib[0], '--verify', '-o', lst, b], capture_output=True, text=True)
    ok = p.returncode == 0 and 'byte-identical' in p.stderr
    sc = json.loads(subprocess.check_output(['python3', os.path.join(G, 'tools/score.py'), os.path.join(d, 'gt.json'), lst,
                                             e['org'].lstrip('$'), '--image', b, '--var-inline', lib[1]], text=True))
    rows.append('| %s | %s | %s | %.2f -> %.2f | %d -> %d | %d -> %d | %d/%d -> %d/%d | %d/%d -> %d/%d |' % (
        e['id'], lib[0], 'yes' if ok else 'NO', r['coverage'], sc['coverage'], r['false_code'], sc['false_code'],
        r['insn_starts_bogus'], sc['insn_starts_bogus'], r['inline_found'], r['inline_expected'], sc['inline_found'], sc['inline_expected'],
        r['var_inline_found'], r['var_inline_expected'], sc['var_inline_found'], sc['var_inline_expected']))
print('\n'.join(rows))
