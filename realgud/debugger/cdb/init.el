;;; Copyright (C) 2010-2011, 2014 Rocky Bernstein <rocky@gnu.org>
;;; cdb debugger

(eval-when-compile (require 'cl))

(require 'load-relative)
(require-relative-list '("../../common/regexp" "../../common/loc") "realgud-")

(defvar realgud-pat-hash)
(declare-function make-realgud-loc-pat (realgud-loc))

(defvar realgud:cdb-pat-hash (make-hash-table :test 'equal)
  "hash key is the what kind of pattern we want to match:
backtrace, prompt, etc.  the values of a hash entry is a
realgud-loc-pat struct")

(declare-function make-realgud-loc "realgud-loc" (a b c d e f))

(defconst realgud:cdb-frame-file-regexp
  "^\\(.*?\\)(\\([0-9]+?\\))\\+?0?x?[0-9]*?$")

;; regular expression that describes a cdb location generally shown
;; before a command prompt. NOTE: we assume annotate 1!
(setf (gethash "loc" realgud:cdb-pat-hash)
      (make-realgud-loc-pat
       :regexp realgud:cdb-frame-file-regexp
       :file-group 1
       :line-group 2
       :char-offset-group 3))

(setf (gethash "prompt" realgud:cdb-pat-hash)
      (make-realgud-loc-pat
       :regexp   "^[0-9a-f]:[0-9a-f][0-9a-f][0-9a-f]> "
       ))

;;  regular expression that describes a "breakpoint set" line
(setf (gethash "brkpt-set" realgud:cdb-pat-hash)
      (make-realgud-loc-pat
       :regexp "^[0-9]+?du\s+[0-9]+?([0-9]+?)\s*(\\(.*?\\):\\([0-9]+?\\))$"
       :num 1
       :file-group 1
       :line-group 2))

(defconst realgud:cdb-frame-start-regexp
  "\\(?:^\\|\n\\)")

(defconst realgud:cdb-frame-num-regexp
  "#\\([0-9]+\\) ")

;; Regular expression that describes a cdb "backtrace" command line.
;; For example:
;; #0  main (argc=2, argv=0xbffff564, envp=0xbffff570) at main.c:935
;; #1  0xb7e9f4a5 in *__GI___strdup (s=0xbffff760 "/tmp/remake/remake") at strdup.c:42
;; #2  0x080593ac in main (argc=2, argv=0xbffff5a4, envp=0xbffff5b0)
;;    at main.c:952
;; #46 0xb7f51b87 in vm_call_cfunc (th=0x804d188, reg_cfp=0xb7ba9e88, num=0,
;;    recv=157798080, blockptr=0x0, me=0x80d12a0) at vm_insnhelper.c:410

(setf (gethash "debugger-backtrace" realgud:cdb-pat-hash)
      (make-realgud-loc-pat
       :regexp "^\\([0-9]+\\) [0-9a-f`]+ [0-9a-f`]+ \\([[0-9a-z_A-Z!+`:]*\\).*$"
       ;; (concat realgud:cdb-frame-start-regexp
       ;;  		realgud:cdb-frame-num-regexp
       ;;  		"\\(?:.\\|\\(?:[\n] \\)\\)+[ ]+at "
       ;;  		realgud:cdb-frame-file-regexp
       ;;  		)
       :num 1
       :file-group 2
       :line-group 1)
      )

(setf (gethash "font-lock-keywords" realgud:cdb-pat-hash)
      '(
	;; #2  0x080593ac in main (argc=2, argv=0xbffff5a4, envp=0xbffff5b0)
	;;    at main.c:952
	("[ \n]+at \\(.*\\):\\([0-9]+\\)"
	 (1 realgud-file-name-face)
	 (2 realgud-line-number-face))

	;; The frame number and first type name, if present.
	;; E.g. =>#0  Makefile.in at /tmp/Makefile:216
	;;      ---^
	( "#\\(?:^\\|\n\\)\\([0-9]+\\)  "
	 (1 realgud-backtrace-number-face))
	))

(setf (gethash "cdb" realgud-pat-hash) realgud:cdb-pat-hash)

(defvar realgud:cdb-command-hash (make-hash-table :test 'equal)
  "Hash key is command name like 'continue' and the value is
  the cdb command to use, like 'continue'")

(setf (gethash "break"    realgud:cdb-command-hash) "break %l")
(setf (gethash "clear"    realgud:cdb-command-hash) "clear %l")
(setf (gethash "continue" realgud:cdb-command-hash) "continue")
(setf (gethash "quit"     realgud:cdb-command-hash) "quit")
(setf (gethash "run"      realgud:cdb-command-hash) "run")
(setf (gethash "step"     realgud:cdb-command-hash) "step %p")
(setf (gethash "cdb" realgud-command-hash) realgud:cdb-command-hash)

(setf (gethash "cdb" realgud-pat-hash) realgud:cdb-pat-hash)

(provide-me "realgud:cdb-")
