---
name: mingjian
description: Work on mingjian (this repo) — replay-verified audit for deterministic plants and gated agents, on Rusty. Covers the replay/verify architecture, the battle-test rule, test discipline, and gotchas. Use for any change to mingjian.lisp or its tests.
---

# Working on mingjian

明鑒 "bright mirror" — replay-verified audit on Rusty. Pure Lisp, zero new
interpreter code. Third app in the line: wuwei gates agents, shouzhong proves
plants, mingjian proves what actually happened. Public at
github.com/TheLakeMan/mingjian (name approved by owner 2026-07-11); pushing
still requires the usual ask-first rule.

## Architecture

- `mingjian.lisp` — everything: `mj-run` (instrumented recorder → plain-data
  record `(s0 … actions … final … trajectory …)`), `mj-replay`,
  `mj-verify`/`mj-verify-trajectory`/`mj-verify-run` (consistency of log vs
  claim; divergences name the first bad tick), `mj-save`/`mj-load`
  (save-model round-trip), wuwei-audit helpers (`mj-rejections`,
  `mj-verdict-counts`, `mj-breaches` — the mechanized battle-test rule), and
  kg loading/queries (`mj-audit->kg!`, `mj-steps-with-verdict`).
- **The claim discipline**: consistency of log⇔claim for DETERMINISTIC
  plants, nothing wider. No crypto, no "tamper-proof" language — the README
  states the forged-consistent-log limitation and the external-anchor
  answer. Keep every new claim inside that line.
- `mingjian-test.lisp` / `expected_mingjian.txt` — golden test via
  `./run_tests.sh`. Vendors the integer thermostat plant (keep worlds
  integer — determinism is the whole product). After changes:
  `rusty mingjian-test.lisp > expected_mingjian.txt`, rerun, diff.

## Gotchas

- Audit rows are wuwei-shaped `(step tool input verdict)`; verdicts are
  SYMBOLS ('ok / 'rejected) — compare with `equal?`, never `=`.
- `mj-verify-trajectory` tick numbering: tick k = state after k commands;
  tick 0 = s0. The golden test depends on it.
- kg state is global: `kg-clear!` before loading a fixture.
- save-model rejects code values and NaN/Inf — records are plain data by
  construction; keep them that way.

## Conventions

AGPL headers everywhere; ☯ never a crab; dedication exactly "In memory of my
brother."; never reference Taoscii. Nondeterminism goes in demo files only.
