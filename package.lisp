;; Rusty package manifest — format defined by pkg.lisp in the Rusty repo
;; (github.com/TheLakeMan/rusty). A package is any git repo with this file at
;; its root. To install (Rusty's pkg.lisp must be loaded first):
;;
;;   (load "pkg.lisp")
;;   (pkg-install "https://github.com/TheLakeMan/mingjian")   ; clone + auto-lock
;;   (pkg-load "mingjian")                                     ; the audit library
;;
;; Pure Lisp on Rusty (>= 0.45.0, for the file-hash behind mj-anchor); no package
;; deps. mingjian is a single-file library, but `main` is mingjian-pkg.lisp for
;; uniformity with the rest of the suite: it loads mingjian.lisp by absolute path
;; (Rusty's `load` is CWD-relative) and adds the mj-self-check integrity hook.
((name "mingjian")
 (version "0.1.0")
 (main "mingjian-pkg.lisp"))
