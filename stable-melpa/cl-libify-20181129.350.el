;;; cl-libify.el --- Update elisp code to use cl-lib instead of cl  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; Keywords: lisp
;; Homepage: https://github.com/purcell/cl-libify
;; Package-Requires: ((emacs "25"))
;; Package-Version: 20181129.350
;; Package-X-Original-Version: 0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; `cl' is a deprecated library, and elisp authors should use `cl-lib'
;; instead.  In most cases, this is a matter of requiring "cl-lib" and
;; adding a "cl-" prefix to symbols that came from "cl".

;; This library provides an interactive command, `cl-libify', which
;; replaces usages of "cl" symbols with their "cl-lib" equivalent,
;; optionally prompting for each

;; Note that some cl functions do not have exact replacements,
;; e.g. `flet', so further code changes might still be necessary.

;;; Code:


(require 'cl-lib)
(eval-when-compile
  (with-no-warnings
    (require 'cl)))

(defconst cl-libify-function-alias-alist
  (eval-when-compile
    (cl-loop for s being the symbols
             for sf = (symbol-function s)
             for nm = (symbol-name s)
             when (and sf
                       (symbolp sf)
                       (not (string= (symbol-name sf) nm))
                       (string-prefix-p "cl-" (symbol-name sf))
                       (not (string-prefix-p "cl-" nm)))
             collect (cons s sf)))
  "Alist of symbols pairs mapping cl functions to their cl-lib equivalents.")

(defconst cl-libify-var-alias-alist
  (eval-when-compile
    (cl-loop for s being the symbols
             for sf = (indirect-variable s)
             for nm = (symbol-name s)
             when (and (not (eq sf s))
                       (not (string= (symbol-name sf) nm))
                       (string-prefix-p "cl-" (symbol-name sf))
                       (not (string-prefix-p "cl-" nm)))
             collect (cons s sf)))
  "Alist of symbols pairs mapping cl variables to their cl-lib equivalents.")

(defun cl-libify (beg end)
  "Replace cl symbol names between BEG and END with their cl-lib equivalents.

If no region is supplied, this operates on the entire
buffer.  With prefix argument PROMPT, ask the user to confirm each
replacement."
  (interactive "r")
  (unless (use-region-p)
    (setq beg (point-min)
          end (point-max)))
  (let ((prompt current-prefix-arg))
    (cl-libify--replace-in-region prompt beg end "[(']" cl-libify-function-alias-alist)
    (cl-libify--replace-in-region prompt beg end "" cl-libify-var-alias-alist)))

(defun cl-libify--replace-in-region (prompt beg end prefix alist)
  "Between BEG and END, replace keys of ALIST with their matching values.
Keys must be distinct symbols which follow the regexp PREFIX.
That regexp must not contain any capture groups.  When PROMPT is
non-nil, ask the user to confirm each replacement."
  (save-excursion
    (goto-char beg)
    (let ((end-marker (set-marker (make-marker) end))
          (pat (regexp-opt (mapcar 'symbol-name (mapcar 'car alist)) 'symbols)))
      (while (search-forward-regexp (concat prefix pat) end-marker t)
        (unless (cl-libify--in-string-or-comment)
          (let* ((orig (match-string 1))
                 (replacement (symbol-name (alist-get (intern orig) alist))))
            (when (or (null prompt)
                      (save-match-data (y-or-n-p (format "Replace `%s' with `%s'?" orig replacement))))
              (replace-match replacement t t nil 1))))))))

(defun cl-libify--in-string-or-comment ()
  "Return non-nil if point is within a string or comment."
  (let ((ppss (syntax-ppss)))
    (or (car (setq ppss (nthcdr 3 ppss)))
        (car (setq ppss (cdr ppss)))
        (nth 3 ppss))))


(provide 'cl-libify)
;;; cl-libify.el ends here
