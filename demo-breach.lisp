;;; demo-breach.lisp — the 15-second smoking-gun demo (offline, no LLM).
;;; Copyright (c) 2026 Nicholas Vermeulen
;;; SPDX-License-Identifier: AGPL-3.0-or-later
;;;
;;; The whole mingjian claim in two lines of output: on an honest agent audit
;;; mj-breaches is empty; on a forged audit the out-of-policy 'ok comes back
;;; as DATA — the smoking gun, not a vibe. This is the script behind the
;;; README GIF. Longer story: demo-receipt.lisp.
;;;
;;;   rusty demo-breach.lisp

(load "mingjian.lisp")

(define BOX "/tmp/wuwei-demo/")
(define (sandbox-allowed? tool input)
  (and (string? input) (string-starts-with? input BOX) (not (string-contains? input ".."))))

;; An honest agent audit: two rejections, no out-of-box 'ok.
(define AUDIT
  (list (list 1 'read-file  (string-append BOX "notes.txt") 'ok)
        (list 2 'read-file  "/etc/passwd"                    'rejected)
        (list 3 'write-file "/etc/evil"                      'rejected)))
;; A forged audit: someone slipped in an 'ok the policy forbids.
(define FORGED (append AUDIT (list (list 4 'write-file "/etc/shadow" 'ok))))

(println "mingjian — a break is an 'ok the policy forbids, returned as DATA.")
(println "")
(println (format "mj-breaches on the honest audit  => ~s   (empty: jailbreak not shown)"
  (mj-breaches AUDIT sandbox-allowed?)))
(println (format "mj-breaches on the FORGED audit  => ~s"
  (mj-breaches FORGED sandbox-allowed?)))
(println "      non-empty = smoking gun. Screenshots of chat don't count; the receipt does.")
