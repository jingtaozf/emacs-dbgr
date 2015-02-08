;;; Copyright (C) 2010, 2012, 2014 Rocky Bernstein <rocky@gnu.org>
;;; cdb tracking a comint or eshell buffer.

(eval-when-compile (require 'cl))
(require 'load-relative)
(require-relative-list '(
			 "../../common/cmds"
			 "../../common/menu"
			 "../../common/track"
			 "../../common/track-mode"
			 )
		       "realgud-")
(require-relative-list '("core" "init") "realgud:cdb-")

(realgud-track-mode-vars "realgud:cdb")

(declare-function realgud-track-mode 'realgud-track-mode)
(declare-function realgud:track-mode-hook 'realgud-track-mode)
(declare-function realgud-track-mode-setup 'realgud-track-mode)
(declare-function realgud:track-set-debugger 'realgud-track-mode)

(define-key realgud:cdb-track-mode-map
  (kbd "C-c !b") 'realgud:goto-debugger-backtrace-line)

(defun realgud:cdb-track-mode-hook()
  (use-local-map realgud:cdb-track-mode-map)
  (message "realgud:cdb track-mode-hook called")
)

(define-minor-mode realgud:cdb-track-mode
  "Minor mode for tracking cdb inside a process shell via realgud.

If called interactively with no prefix argument, the mode is toggled. A prefix argument, captured as ARG, enables the mode if the argument is positive, and disables it otherwise.

Key bindings:
\\{realgud:cdb-track-mode-map}
"
  :init-value nil
  ;; :lighter " cdb"   ;; mode-line indicator from realgud-track is sufficient.
  ;; The minor mode bindings.
  :global nil
  :group 'realgud:cdb
  :keymap realgud:cdb-track-mode-map
  (if realgud:cdb-track-mode
      (progn
	(realgud:track-set-debugger "cdb")
	(setq realgud-track-mode 't)
        (realgud-track-mode-setup 't)
        (realgud:cdb-track-mode-hook))
    (progn
      (setq realgud-track-mode nil)
      ))
)

(provide-me "realgud:cdb-")
