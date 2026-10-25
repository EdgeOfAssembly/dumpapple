#!/usr/bin/env python3
"""Replace the notes column of the default scorecard table with facts read from
this run's listings (the fixtures' hand-written notes describe the baseline
build and go stale).  Usage: scorecard_notes.py SCORECARD_DIR"""
import json, os, re, sys
G = sys.argv[1]
man = {e['id']: e for e in json.load(open(os.path.join(G, 'manifest.json')))['entries']}
def facts(id_):
    e = man.get(id_)
    if not e: return ''
    lst = os.path.join(os.path.dirname(os.path.join(G, e['binary'])), 'da.s')
    if not os.path.exists(lst): return 'no listing'
    t = open(lst, errors='replace').read()
    f = []
    tabs = re.findall(r'^; jump table \((auto|hint)\): (\d+) (.*?) entr', t, re.M)
    if tabs: f.append('tables: ' + ', '.join(f'{n} {k}' for _, n, k in tabs))
    v = len(re.findall(r'returns past \d+ inline bytes? \(', t))
    if v: f.append(f'{v} var-inline sites')
    for m in re.findall(r'suggested hint: (inline \S+ z) \((\d+) call', t): f.append(f'suggests `{m[0]}` ({m[1]} sites)')
    u = t.count('; unknown: possible inline data after')
    if u: f.append(f'{u} unknown-return stops')
    s = t.count('decoding stopped')
    if s: f.append(f'{s} decode stops')
    o = t.count('overlapping entry point')
    if o: f.append(f'{o} overlapping entries')
    n = t.count('does not return')
    if n: f.append(f'{n} no-return calls')
    return '; '.join(f) or 'clean'
out = []
for line in open(os.path.join(G, 'scorecard.md')):
    c = line.rstrip('\n').split('|')
    if len(c) == 14 and c[1].strip() in man:
        c[12] = ' ' + facts(c[1].strip()) + ' '
        line = '|'.join(c) + '\n'
    out.append(line)
open(os.path.join(G, 'scorecard.md'), 'w').write(''.join(out))
