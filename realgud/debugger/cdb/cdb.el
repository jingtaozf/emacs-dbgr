;;; Copyright (C) 2010-2011, 2014 Rocky Bernstein <rocky@gnu.org>
;;  `realgud:cdb' Main interface to cdb via Emacs
(require 'cl)
(require 'list-utils)
(require 'load-relative)
(require-relative-list '("../../common/helper") "realgud-")
(require-relative-list '("core" "track-mode") "realgud:cdb-")

;; This is needed, or at least the docstring part of it is needed to
;; get the customization menu to work in Emacs 24.
(defgroup realgud:cdb nil
  "The realgud interface to cdb"
  :group 'realgud
  :version "24.1")

;; -------------------------------------------------------------------
;; User definable variables
;;

(defcustom realgud:cdb-command-name
  "cdb"
  "File name for executing the Ruby debugger and command options.
This should be an executable on your path, or an absolute file name."
  :type 'string
  :group 'realgud:cdb)

(declare-function realgud:cdb-track-mode     'realgud:cdb-track-mode)
(declare-function realgud-command            'realgud:cdb-core)
(declare-function realgud:cdb-parse-cmd-args 'realgud:cdb-core)
(declare-function realgud:cdb-query-cmdline  'realgud:cdb-core)
(declare-function realgud:run-process        'realgud-core)

;; -------------------------------------------------------------------
;; The end.
;;

;;;###autoload
(defun realgud:cdb (&optional opt-cmd-line no-reset)
  "Invoke the cdb debugger and start the Emacs user interface.

OPT-CMD-LINE is treated like a shell string; arguments are
tokenized by `split-string-and-unquote'.

Normally, command buffers are reused when the same debugger is
reinvoked inside a command buffer with a similar command. If we
discover that the buffer has prior command-buffer information and
NO-RESET is nil, then that information which may point into other
buffers and source buffers which may contain marks and fringe or
marginal icons is reset. See `loc-changes-clear-buffer' to clear
fringe and marginal icons.
"

  (interactive)
  (let* ((cmd-str (or opt-cmd-line (realgud:cdb-query-cmdline "cdb")))
	 (cmd-args (split-string-and-unquote cmd-str))
	 (parsed-args (realgud:cdb-parse-cmd-args cmd-args))
	 (script-args (caddr parsed-args))
	 (script-name (car script-args))
	 (parsed-cmd-args
	  (cl-remove-if 'nil (list-utils-flatten parsed-args)))
	 (cmd-buf (realgud:run-process realgud:cdb-command-name
				       script-name parsed-cmd-args
				       'realgud:cdb-track-mode-hook
				       'realgud:cdb-minibuffer-history
				       nil))
	 )
    (if cmd-buf
	(with-current-buffer cmd-buf
	  (realgud-command "set annotate 1" nil nil nil)
	  )
      )
    )
  )

(provide-me "realgud-")

;; Local Variables:
;; byte-compile-warnings: (not cl-functions)
;; End:
