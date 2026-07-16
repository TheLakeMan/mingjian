;;; Copyright (c) 2026 Nicholas Vermeulen
;;; SPDX-License-Identifier: AGPL-3.0-or-later

;; ─────────────────────────────────────────────────────────────────────────────
;; mingjian-pkg.lisp — the package entry point (the manifest's `main`).
;;
;; mingjian is a single file, so it *could* be the manifest `main` directly (it
;; loads no siblings). This shim exists for two reasons: uniformity with the rest
;; of the suite (every app has an <app>-pkg.lisp entry), and to host the
;; mj-self-check integrity hook without putting a packaging concern in the core
;; library. It loads mingjian.lisp by ABSOLUTE path because Rusty's `load` is
;; CWD-relative and a package is loaded from an arbitrary working directory.
;; ─────────────────────────────────────────────────────────────────────────────

(define mingjian-pkg-dir
  (string-append (shell "printf $HOME") "/.rusty/packages/mingjian"))

(load (string-append mingjian-pkg-dir "/mingjian.lisp"))   ; replay + audit + anchor

;; ── Self-integrity: has mingjian's OWN installed code drifted since install? ──
;; Delegates to pkg-drift (live tree vs the install-day lock, stored OUTSIDE this
;; tree). Guarded: if Rusty's pkg.lisp isn't loaded, pkg-drift is undefined and
;; the reference raises — caught and reported, not a crash.
;;
;; HONEST SCOPE — the very distinction mingjian is built on: this detects whether
;; the AUDITOR's code changed since install, which is NOT the same as auditing a
;; log. A forged log still replays clean (see mj-anchor); likewise, matching code
;; proves sameness, never trustworthiness. Not a sandbox, not proof against a
;; determined local attacker (who rewrites the lock too) or a hostile publisher.
;; For provenance use (pkg-verify "mingjian" fp) with a fingerprint that reached
;; you OUT OF BAND.
(define (mj-self-check)
  (try-catch (pkg-drift "mingjian")
    (e) (list 'pkg-not-loaded
              "load Rusty's pkg.lisp first to self-check installed integrity")))
