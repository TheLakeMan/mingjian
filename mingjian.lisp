;;; mingjian.lisp — replay-verified audit for deterministic plants & agents.
;;; Copyright (c) 2026 Nicholas Vermeulen
;;; SPDX-License-Identifier: AGPL-3.0-or-later
;;;
;;; 明鑒 — "bright mirror" (Zhuangzi: the utmost person's mind is like a
;;; mirror — it reflects what happened, adds nothing, hides nothing). A
;;; mingjian log doesn't ask to be trusted: for a DETERMINISTIC plant
;;; (pure world-step + logged commands), the log is re-runnable evidence.
;;; Replay it; every state must match the claim. Any edit to a stored
;;; command diverges the replay at a specific tick, named in the verdict.
;;;
;;; THE CLAIM, precisely (and no wider):
;;;   mj-verify proves the log and the claim are CONSISTENT — these
;;;   commands, from this initial state, under this world model, produce
;;;   exactly this trajectory/outcome. That makes any post-hoc edit of a
;;;   stored log detectable AGAINST ITS CLAIM. It does not stop an
;;;   attacker from forging a complete, internally-consistent different
;;;   log — anchor the claim (final record) somewhere they can't rewrite
;;;   and replay verification closes that gap for the anchored run.
;;;
;;; Pure Lisp on Rusty — zero new interpreter code. Pairs with:
;;;   wuwei      — its (step tool input verdict) audit rows: query them,
;;;                count them, and mechanize the battle-test rule ("a real
;;;                break must show an ok verdict it shouldn't have gotten")
;;;   shouzhong  — its pure world-steps + gated command buses are exactly
;;;                the deterministic plants replay verification wants.

;; ── Recording ───────────────────────────────────────────────────────────
;; Instrumented run: drive a pure controller through a pure world and give
;; back everything a verifier needs. A run record is plain data:
;;   (s0 <state> actions (a0 a1 ...) final <state> trajectory (s0 s1 ...))
(define (mj-run world-step controller s0 ticks)
  (let loop ((s s0) (n 0) (acts '()) (traj (list s0)))
    (if (>= n ticks)
        (list 's0 s0 'actions (reverse acts) 'final s
              'trajectory (reverse traj))
        (let* ((a (controller s))
               (s2 (world-step s a)))
          (loop s2 (+ n 1) (cons a acts) (cons s2 traj))))))

(define (mj-s0 run)         (nth run 1))
(define (mj-actions run)    (nth run 3))
(define (mj-final run)      (nth run 5))
(define (mj-trajectory run) (nth run 7))

;; ── Replay ──────────────────────────────────────────────────────────────
(define (mj-replay world-step s0 actions)
  (let loop ((s s0) (as actions) (traj (list s0)))
    (if (null? as)
        (list 'final s 'trajectory (reverse traj))
        (let ((s2 (world-step s (car as))))
          (loop s2 (cdr as) (cons s2 traj))))))

;; ── Verification ────────────────────────────────────────────────────────
;; Outcome check: do these commands really end where the log claims?
(define (mj-verify world-step s0 actions claimed-final)
  (let ((r (mj-replay world-step s0 actions)))
    (if (equal? (cadr r) claimed-final)
        'verified
        (list 'diverged 'final 'claimed claimed-final 'replayed (cadr r)))))

;; Trajectory check: pinpoints the FIRST tick where the claim and the
;; replay disagree — i.e. where the log was edited (or the world model
;; differs). Tick k is the state after k commands; tick 0 is s0.
(define (mj-verify-trajectory world-step s0 actions claimed-traj)
  (let ((r (mj-replay world-step s0 actions)))
    (let loop ((got (nth r 3)) (want claimed-traj) (k 0))
      (cond ((and (null? got) (null? want)) 'verified)
            ((null? got)  (list 'diverged 'tick k 'claimed (car want) 'replayed 'nothing))
            ((null? want) (list 'diverged 'tick k 'claimed 'nothing 'replayed (car got)))
            ((equal? (car got) (car want)) (loop (cdr got) (cdr want) (+ k 1)))
            (else (list 'diverged 'tick k 'claimed (car want) 'replayed (car got)))))))

;; Whole-record check: a stored mj-run record verifies against itself.
(define (mj-verify-run world-step run)
  (let ((t (mj-verify-trajectory world-step (mj-s0 run) (mj-actions run)
                                 (mj-trajectory run))))
    (if (equal? t 'verified)
        (mj-verify world-step (mj-s0 run) (mj-actions run) (mj-final run))
        t)))

;; ── Persistence (versioned JSON via save-model — lossless round-trip) ──
(define (mj-save file run) (save-model file run))
(define (mj-load file)     (load-model file))

;; ── Agent audits (wuwei-shaped rows: (step tool input verdict)) ─────────
(define (mj-row-step r)    (nth r 0))
(define (mj-row-tool r)    (nth r 1))
(define (mj-row-input r)   (nth r 2))
(define (mj-row-verdict r) (nth r 3))

(define (mj-rejections rows)
  (filter (lambda (r) (not (equal? (mj-row-verdict r) 'ok))) rows))

(define (mj-verdict-counts rows)
  (list (list 'ok (length (filter (lambda (r) (equal? (mj-row-verdict r) 'ok)) rows)))
        (list 'rejected (length (mj-rejections rows)))))

;; The battle-test rule, mechanized: a REAL breach is a row that got an
;; 'ok verdict on a call your policy says should never pass. allowed? is
;; a pure predicate (tool input) -> bool. Empty result = no breach shown.
(define (mj-breaches rows allowed?)
  (filter (lambda (r) (and (equal? (mj-row-verdict r) 'ok)
                           (not (allowed? (mj-row-tool r) (mj-row-input r)))))
          rows))

;; ── Audit queries via the knowledge graph ───────────────────────────────
;; Loads rows as triples so kg-query can answer questions across runs:
;;   (step-N tool <sym>) (step-N input <str>) (step-N verdict <sym>)
(define (mj-audit->kg! rows)
  (let loop ((rs rows) (n 0))
    (if (null? rs) n
        (let* ((r (car rs))
               (s (string->symbol (format "step-~a" (mj-row-step r)))))
          (kg-add! s 'tool    (mj-row-tool r))
          (kg-add! s 'input   (mj-row-input r))
          (kg-add! s 'verdict (mj-row-verdict r))
          (loop (cdr rs) (+ n 3))))))

;; Every step where some tool got verdict v (e.g. 'rejected) — pure kg-query.
(define (mj-steps-with-verdict v)
  (kg-query (list (list '?s 'verdict v))))
