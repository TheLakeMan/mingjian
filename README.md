# ☯ mingjian

**明鑒 — "bright mirror." Replay-verified audit for deterministic plants and
gated agents: a log that doesn't ask to be trusted, because you can re-run
it.**

Built on [Rusty](https://github.com/TheLakeMan/rusty), a zero-dependency Lisp
interpreter in Rust. Pure Lisp, zero new interpreter code. The audit sibling
of [wuwei](https://github.com/TheLakeMan/wuwei) (gated agents) and
[shouzhong](https://github.com/TheLakeMan/shouzhong) (proven control loops):
wuwei decides what may run, shouzhong proves where the plant may go, mingjian
proves **what actually happened**.

## The claim, precisely

For a **deterministic** plant — a pure `world-step` plus a log of commands —
the log is *re-runnable evidence*:

- `mj-verify` / `mj-verify-run` replay the commands from the recorded initial
  state and check every state against the claim. **The log and its claimed
  outcome are consistent, or you get the first divergent tick, named.**
- Edit a stored command, truncate the log, or doctor the claimed outcome, and
  the replay walks away from the claim at a specific tick:

```
04 doctored command detected   => (diverged tick 5 claimed (19) replayed (21))
05 doctored final-state claim  => (diverged final claimed (25) replayed (19))
06 truncated log detected      => (diverged tick 1 claimed (17) replayed (15))
```

Honest scope — this is exactly as strong as your plant's determinism and no
stronger. Replay verification proves *log ⇔ claim consistency*; it does not
stop an attacker from forging a complete, internally-consistent *different*
log. Anchor the claim (the final record) somewhere they can't rewrite —
mingjian closes the rest for the anchored run. No cryptography is used or
pretended.

## The battle-test rule, mechanized

wuwei's jailbreak challenge says: *a real break must show a tool call with an
`ok` verdict it shouldn't have gotten.* `mj-breaches` is that sentence as a
function — it takes wuwei-shaped audit rows `(step tool input verdict)` and a
policy predicate, and returns exactly the rows that prove a breach (empty ==
no breach shown):

```lisp
(mj-breaches audit-rows in-box?)   ; => ()  — or the smoking gun, as data
```

Audits are also queryable: `mj-audit->kg!` loads rows into Rusty's built-in
knowledge graph, so questions like "which steps were rejected" or "what did
step 6 touch" are one `kg-query` away — across runs, exportable as N-Triples.

## Quickstart

```bash
# 1. Install Rusty (https://github.com/TheLakeMan/rusty)
cargo install --git https://github.com/TheLakeMan/rusty --bin rusty --root ~/.local

# 2. Run the proof suite — deterministic, no LLM
./run_tests.sh
```

## API

| function | what |
|---|---|
| `mj-run step ctl s0 n` | instrumented run → record `(s0 … actions … final … trajectory …)` |
| `mj-replay step s0 acts` | recompute final + trajectory from a log |
| `mj-verify step s0 acts final` | `'verified` or `(diverged final claimed … replayed …)` |
| `mj-verify-trajectory step s0 acts traj` | `'verified` or first divergent tick, named |
| `mj-verify-run step run` | whole stored record against itself |
| `mj-save` / `mj-load` | lossless round-trip via Rusty's versioned-JSON `save-model` |
| `mj-rejections` / `mj-verdict-counts` | wuwei-audit basics, as data |
| `mj-breaches rows allowed?` | the battle-test rule — `ok` verdicts your policy forbids |
| `mj-audit->kg!` / `mj-steps-with-verdict` | audits as knowledge-graph triples, queryable |

Works out of the box with shouzhong's plants (pure `world-step`s and gated
command buses are exactly what replay verification wants) and wuwei's audit
rows. The golden test vendors a small thermostat plant so this repo stands
alone.

## License

AGPL-3.0-or-later. Copyright (c) 2026 Nicholas Vermeulen.
Commercial licensing available on inquiry.

*In memory of my brother.*
