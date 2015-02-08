;;; Copyright (C) 2010, 2013-2014 Rocky Bernstein <rocky@gnu.org>
(eval-when-compile (require 'cl))

(require 'load-relative)
(require-relative-list '("../../common/track"
			 "../../common/core"
			 "../../common/lang")
		       "realgud-")

(declare-function realgud:expand-file-name-if-exists 'realgud-core)
(declare-function realgud-lang-mode? 'realgud-lang)
(declare-function realgud-parse-command-arg 'realgud-core)
(declare-function realgud-query-cmdline 'realgud-core)

;; FIXME: I think the following could be generalized and moved to
;; realgud-... probably via a macro.
(defvar realgud:cdb-minibuffer-history nil
  "minibuffer history list for the command `cdb'.")

(easy-mmode-defmap realgud:cdb-minibuffer-local-map
  '(("\C-i" . comint-dynamic-complete-filename))
  "Keymap for minibuffer prompting of gud startup command."
  :inherit minibuffer-local-map)

;; FIXME: I think this code and the keymaps and history
;; variable chould be generalized, perhaps via a macro.
(defun realgud:cdb-query-cmdline (&optional opt-debugger)
  (realgud-query-cmdline
   'realgud:cdb-suggest-invocation
   realgud:cdb-minibuffer-local-map
   'realgud:cdb-minibuffer-history
   opt-debugger))

(defun realgud:cdb-parse-cmd-args (orig-args)
  "Parse command line ARGS for the annotate level and name of script to debug.

ORIG_ARGS should contain a tokenized list of the command line to run.

We return the a list containing
* the name of the debugger given (e.g. cdb) and its arguments - a list of strings
* nil (a placehoder in other routines of this ilk for a debugger
* the script name and its arguments - list of strings
* whether the annotate or emacs option was given ('-A', '--annotate' or '--emacs) - a boolean

For example for the following input
  (map 'list 'symbol-name
   '(cdb --tty /dev/pts/1 -cd ~ --emacs ./gcd.py a b))

we might return:
   ((\"cdb\" \"--tty\" \"/dev/pts/1\" \"-cd\" \"home/rocky\' \"--emacs\") nil \"(/tmp/gcd.py a b\") 't\")

Note that path elements have been expanded via `expand-file-name'.
"

  ;; Parse the following kind of pattern:
  ;;  cdb cdb-options script-name script-options
  (let (
	(args orig-args)
	(pair)          ;; temp return from

	;; One dash is added automatically to the below, so
	;; h is really -h and -host is really --host.
	(cdb-two-args '("x" "-command" "b" "-exec"
			"cd" "-pid"  "-core" "-directory"
			"-annotate"
			"se" "-symbols" "-tty"))
	;; cdb doesn't optionsl 2-arg options.
	(cdb-opt-two-args '())

	;; Things returned
	(script-name nil)
	(debugger-name nil)
	(debugger-args '())
	(script-args '())
	(annotate-p nil))

    (if (not (and args))
	;; Got nothing: return '(nil nil nil nil)
	(list debugger-args nil script-args annotate-p)
      ;; else
      (progn

	;; Remove "cdb" from "cdb --cdb-options script
	;; --script-options"
	(setq debugger-name (file-name-sans-extension
			     (file-name-nondirectory (car args))))
	(unless (string-match "^cdb.*" debugger-name)
	  (message
	   "Expecting debugger name `%s' to be `cdb'"
	   debugger-name))
	(setq debugger-args (list (pop args)))

	;; Skip to the first non-option argument.
	(while (and args (not script-name))
	  (let ((arg (car args)))
	    (cond
	     ;; Annotation or emacs option with level number.
	     ((or (member arg '("--annotate" "-A"))
		  (equal arg "--emacs"))
	      (setq annotate-p t)
	      (nconc debugger-args (list (pop args) (pop args))))
	     ;; Combined annotation and level option.
	     ((string-match "^--annotate=[0-9]" arg)
	      (nconc debugger-args (list (pop args) (pop args)) )
	      (setq annotate-p t))
	     ;; path-argument ooptions
	     ((member arg '("-cd" ))
	      (setq arg (pop args))
	      (nconc debugger-args
		     (list arg (realgud:expand-file-name-if-exists
				(pop args)))))
	     ;; Options with arguments.
	     ((string-match "^-" arg)
	      (setq pair (realgud-parse-command-arg
			  args cdb-two-args cdb-opt-two-args))
	      (nconc debugger-args (car pair))
	      (setq args (cadr pair)))
	     ;; Anything else must be the script to debug.
	     (t (setq script-name arg)
		(setq script-args args))
	     )))
	(list debugger-args nil script-args annotate-p)))))

(defvar realgud:cdb-command-name)

(defun realgud:cdb-suggest-invocation (&optional debugger-name)
  "Suggest a cdb command invocation. If the current buffer is a C
source file and there is an executable with the extension
stripped, then use the executable name.  Next try to find an
executable in the default-directory that doesn't have an
extension Next, try to use the first value of MINIBUFFER-HISTORY
if that exists. When all else fails return the empty string."
  (let* ((lang-ext-regexp "\\.\\([ch]\\)\\(pp\\)?")
	 (file-list (directory-files default-directory))
	 (priority 2)
	 (try-filename (file-name-base (or (buffer-file-name) "cdb"))))
    (if (member try-filename (directory-files default-directory))
    	(concat "cdb " try-filename)
      ;; else
      (progn
	;; FIXME: I think a better test would be to look for
	;; c-mode in the buffer that have a corresponding executable
	(while (and (setq try-filename (car-safe file-list)) (< priority 8))
	  (setq file-list (cdr file-list))
	  (if (and (file-executable-p try-filename)
		   (not (file-directory-p try-filename)))
	      (if (equal try-filename (file-name-sans-extension try-filename))
		  (setq priority 8)
		(setq priority 7))))
	)
      (if (< priority 6)
	  (cond
	   (realgud:cdb-minibuffer-history
	    (car realgud:cdb-minibuffer-history))
	   (t "cdb "))
	(concat "cdb " try-filename)
	)
    )))


(defun realgud:cdb-reset ()
  "Cdb cleanup - remove debugger's internal buffers (frame,
breakpoints, etc.)."
  (interactive)
  ;; (cdb-breakpoint-remove-all-icons)
  (dolist (buffer (buffer-list))
    (when (string-match "\\*cdb-[a-z]+\\*" (buffer-name buffer))
      (let ((w (get-buffer-window buffer)))
        (when w
          (delete-window w)))
      (kill-buffer buffer))))

;; (defun cdb-reset-keymaps()
;;   "This unbinds the special debugger keys of the source buffers."
;;   (interactive)
;;   (setcdr (assq 'cdb-debugger-support-minor-mode minor-mode-map-alist)
;; 	  cdb-debugger-support-minor-mode-map-when-deactive))


(defun realgud:cdb-customize ()
  "Use `customize' to edit the settings of the `realgud:cdb' debugger."
  (interactive)
  (customize-group 'realgud:cdb))

(provide-me "realgud:cdb-")
