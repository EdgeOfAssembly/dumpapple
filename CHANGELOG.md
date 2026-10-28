# Changelog

## 0.10.0 (2026-10-28)

- Auto regions (`--no-auto-region`) and seed targets (`--no-seed-targets`),
  both on by default; a page copy indexed by X or Y onto its region is not a
  code store.
- Counted loops: `cpx/cpy #$FF` counting down and `cpx/cpy #n` / `bcc`
  counting up bound an indexed store; Y loops as X loops.
- `--strict-smc` keeps the entry run that executes before any store, and
  turns seed targets and auto regions off unless asked for.
- Stores from code a later pass turns back into data no longer count.

## 0.9.0 (2026-10-25)

First public release.

License: GPL-3.0-or-later (see LICENSE).

Deferred:
- P2: `PROG.SYS16` stays as a placeholder name in the README examples.
- P3: the long README auto-detect / inline-strings bullet is not yet split
  into subsections.
- P9: some README lines are still over 80 columns.
- Project icon: not added yet.
