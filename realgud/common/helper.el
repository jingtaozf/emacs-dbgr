;;; Copyright (C) 2010, 2014 Rocky Bernstein <rocky@gnu.org>
;;; Miscellaneous utility functions
(require 'load-relative)
(defun fn-p-to-fn?-alias (fn-sym)
  "FN-SYM is assumed to be a symbol which is a function.  If it
ends in a 'p' or '-p', that suffix is stripped; in either case, a
suffix with '?' is added this name is a new alias for that
function FN-SYM."
  (if (and (symbolp fn-sym) (functionp fn-sym))
      (let*
	  ((fn-str (symbol-name fn-sym))
	   (new-fn-str
	     (cond
	      ((and (> (length fn-str) 2) (equal "-p" (substring fn-str -2)))
	       (substring fn-str 0 -2))
	      ((and (> (length fn-str) 1) (equal "p" (substring fn-str -1)))
	       (substring fn-str 0 -1))
	      (t fn-str)))
	   (new-fn-sym (intern (concat new-fn-str "?"))))
	(defalias new-fn-sym fn-sym))))

;; FIXME push the special casing into the debuggers themselves.
(defun realgud:debugger-name-transform (debugger-name)
  "In some cases we need to prefix a short debugger name, like
'gdb' with 'realgud:'. This does that."
  (cond
   ((equal debugger-name "gdb") "realgud:gdb")
   ((equal debugger-name "jdb") "realgud:jdb")
   ((or (equal debugger-name "trepan.pl")
	(equal debugger-name "trepanpl"))
    "realgud:trepanpl")
   ('t debugger-name)))

(defun buffer-killed? (buffer)
  "Return t if BUFFER is killed."
  (not (buffer-name buffer)))

(defmacro with-current-buffer-safe (buffer &rest body)
  "Check that BUFFER has not been deleted before calling
`with-current-buffer'. If it has been deleted return nil."
  (declare (indent 1) (debug t))
  `(if (or (not ,buffer) (buffer-killed? ,buffer))
       nil
     (with-current-buffer ,buffer
       ,@body)))


;; FIXME: prepend realgud- onto the beginning of struct-symbol
(defmacro realgud-sget (struct-symbol struct-field)
  "Simplified access to a field of a `defstruct'
variable. STRUCT-SYMBOL is a defstruct symbol name. STRUCT-FIELD
is a field in that. Access (STRUCT-SYMBOL-STRUCT-FIELD STRUCT-SYMBOL)"
  (declare (indent 1) (debug t))
  `(let* ((realgud-symbol-str
	   (concat "realgud-" (symbol-name ,struct-symbol)))
	  (realgud-field-access
	   (intern (concat realgud-symbol-str "-" (symbol-name, struct-field)))))
    (funcall realgud-field-access (eval (intern realgud-symbol-str)))))


(defmacro realgud-struct-field-setter (variable-name field)
  "Creates an defstruct setter method for field FIELD with
of defstruct variable VARIABLE-NAME. For example:

  (realgud-struct-field-setter \"realgud-srcbuf-info\" \"short-key?\")
gives:
  (defun realgud-srcbuf-info-short-key?=(value)
    (setf (realgud-srcbuf-info-short-key? realgud-srcbuf-info) value))
"
  (declare (indent 1) (debug t))
  `(defun ,(intern (concat variable-name "-" field "=")) (value)
     ;; FIXME: figure out how to add docstring
     ;; ,(concat "Sets field" ,field " of " ,variable-name " to VALUE")
     (if ,(intern variable-name)
	 (setf (,(intern (concat variable-name "-" field))
		,(intern variable-name)) value))
    ))

;; (defun realgud-struct-field (var-sym field-sym)
;;   (setq var-str (symbol-name var-sym))
;;   (setq field-str (symbol-name field-sym))
;;   (funcall (symbol-function (intern (concat var-str "-" field-str)))
;; 	   (eval (intern var-str))))

(provide-me "realgud-")
