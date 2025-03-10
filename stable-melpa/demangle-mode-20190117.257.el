;;; demangle-mode.el --- Automatically demangle C++ symbols -*- lexical-binding: t -*-

;; Copyright (C) 2014-2017 Ben Liblit

;; Author: Ben Liblit <liblit@acm.org>
;; Created: 12 Feb 2014
;; Version: 1.2.2
;; Package-Version: 20190117.257
;; Package-Requires: ((cl-lib "0.1") (emacs "24"))
;; Keywords: c tools
;; URL: https://github.com/liblit/demangle-mode

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file LICENSE.md.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.


;;; Commentary:

;; `demangle-mode' is an Emacs minor mode that automatically demangles
;; C++ symbols.  For example, in this mode:

;; - `_ZNSaIcED2Ev' displays as `std::allocator<char>::~allocator()'
;; - `_ZTISt10ostrstream' displays as `typeinfo for std::ostrstream'
;; - `_GLOBAL__I_abc' displays as `global constructors keyed to abc'

;; See <https://github.com/liblit/demangle-mode#readme> for additional
;; documentation: usage suggestions, background & motivation,
;; compatibility notes, and known issues & design limitations.

;; Visit <https://github.com/liblit/demangle-mode/issues> or use
;; command `demangle-mode-submit-bug-report' to report bugs or offer
;; suggestions for improvement.

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  prologue: dependencies and option grouping
;;

(require 'cl-lib)
(require 'easymenu)
(require 'tq)

(eval-when-compile
  (require 'rx))

(defgroup demangle nil
  "Automatically demangle C++ symbols found in buffers."
  :group 'tools)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  display styles for mangled and demangled symbols
;;

(defcustom demangle-show-as 'demangled
  "How to show mangled and demangled symbols."
  :type '(choice
	  (const
	   :tag "Demangled"
	   :format "%t\n%h"
	   :doc "Show the demangled symbol (read only) on screen.\nThe original mangled symbol is shown as a help message or tooltip."
	   demangled)
	  (const
	   :tag "Mangled"
	   :format "%t\n%h"
	   :doc "Show the original mangled symbol on screen.\nThe demangled symbol is shown as a help message or tooltip."
	   mangled)))

(defface demangled '((((supports :box (:line-width 1 :color "grey" :style nil))) (:box (:line-width 1 :color "grey")))
		     (default (:underline (:color "grey" :style wave))))
  "Display face for demangled symbols.")

(defface mangled '((((supports :box (:line-width 1 :color "grey" :style nil))) (:box (:line-width 1 :color "grey")))
		   (default (:underline (:color "grey" :style wave))))
  "Display face for mangled symbols.")

(defalias 'demangle-font-lock-refresh
  (if (fboundp 'font-lock-flush)
      #'font-lock-flush	;; Emacs 25 and later
    #'font-lock-fontify-buffer ;; Emacs 24.x and earlier
    )
  "Re-fontify the current buffer.

This is generally done when turning on command `demangle-mode' or
using command `demangle-show-as' to change the demangled display
style.")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  management of the demangler subprocess and transaction queue
;;

(defvar demangle--queue nil
  "Transaction queue for background demangling of C++ symbols.")

(defun demangle--stop ()
  "Stop the demangler subprocess and transaction queue.

This is safe to call at any time; the demangler subprocess and
transaction queue restarts automatically when needed."
  (when demangle--queue
    (tq-close demangle--queue)
    (setq demangle--queue nil)))

(defun demangle--sentinel (_process _message)
  "Stop the demangler queue if the demangler subprocess exits."
  (demangle--stop))

(defun demangle--start ()
  "Start the demangler subprocess and transaction queue."
  (unless demangle--queue
    (let ((subprocess
	   (if (fboundp 'make-process)
	       ;; Emacs 25 and later
	       (make-process :name "demangler"
			     :command '("c++filt" "--no-strip-underscore")
			     :noquery t
			     :connection-type 'pipe
			     :sentinel #'demangle--sentinel)
	     ;; Emacs 24.x and earlier
	     (let* ((process-connection-type nil)
		    (subprocess (start-process "demangler" nil "c++filt" "--no-strip-underscore")))
	       (set-process-query-on-exit-flag subprocess nil)
	       (set-process-sentinel subprocess #'demangle--sentinel)
	       subprocess))))
      (setq demangle--queue (tq-create subprocess)))))

(cl-defun demangle--answer-received ((mangled-original start end) answer)
  "Process a response received from the demangler transaction queue.

START and END are markers indicating where the MANGLED-ORIGINAL
symbol text appeared.  ANSWER is the raw response received from
the `demangle--queue'."
  (let ((demangled (substring answer 0 -1))
	(buffer (marker-buffer start)))
    (with-current-buffer buffer
      (let ((mangled-current (buffer-substring-no-properties start end)))
	(when (and (string= mangled-original mangled-current)
		   (not (string= mangled-current demangled)))
	  (with-silent-modifications
	    (font-lock-prepend-text-property start end 'face demangle-show-as)
	    (cl-ecase demangle-show-as
	      ('demangled
	       (put-text-property start end 'display demangled)
	       (put-text-property start end 'help-echo mangled-current))
	      ('mangled
	       (put-text-property start end 'help-echo demangled)))))))))

(defun demangle--demangle-matched-symbol (match-data)
  "Begin demangling a mangled symbol.

MATCH-DATA from a recent regular expression search determines the
location and text of the mangled symbol.  Demangling proceeds in
the background, though `demangle--queue'.  Once demangling is
complete, `demangle--answer-received' updates this matched
region's display style accordingly."
  (save-match-data
    (demangle--start)
    (set-match-data match-data)
    (let* ((mangled-with-prefix (match-string 1))
	   (mangled-without-prefix (match-string 2))
	   (question (concat mangled-without-prefix "\n")))
      (cl-destructuring-bind (_ _ marker-start marker-end _ _)
	  match-data
	(cl-assert (markerp marker-start))
	(cl-assert (markerp marker-end))
	(tq-enqueue demangle--queue question "\n"
		    `(,mangled-with-prefix ,marker-start ,marker-end) #'demangle--answer-received)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  minor mode
;;

(defconst demangle-mode-map (make-sparse-keymap)
  "Extra key bindings for command `demangle-mode'.

This provides a small mode-specific menu with options for
changing the display style of demangled symbols (see option
`demangle-show-as').")

(defconst demangle-font-lock-keywords
  `((,(rx (sequence (or (not (any ?_ alnum))
			line-start)
		    (group (sequence (optional ?_)
				     (group (or "_Z"
						(sequence "_GLOBAL_"
							  (any ?. ?_ ?$)
							  (any ?D ?I)
							  ?_))
					    (one-or-more (any ?_ alnum)))))))
     1
     (ignore (demangle--demangle-matched-symbol (match-data)))))
  "Font-lock patterns matching mangled C++ symbols.

The standard patterns recognize two common families of mangled
symbols.  The first consists of identifiers starting with \"_Z\":
these have been mangled using the popular Itanium ABI mangling
scheme.  The second family consists of identifiers starting with
\"_GLOBAL_[._$][DI]_\": these are global constructors or
destructors (respectively), mangled using a Linux/GCC scheme that
extends beyond the Itanium ABI.")

(defmacro demangle--setq-local (var val)
  "Set variable VAR to value VAL in current buffer."
  (if (fboundp 'setq-local)
      `(setq-local ,var ,val)
    ;; Emacs 24.2.x and earlier
    `(set (make-local-variable ',var) ,val)))

;;;###autoload
(define-minor-mode demangle-mode
  "Toggle demangle mode.

Interactively with no argument, this command toggles the mode.  A
positive prefix argument enables the mode; any other prefix
argument disables it.  From Lisp, argument omitted or nil enables
the mode, while `toggle' toggles the state.

When Demangle mode is enabled, mangled C++ symbols appearing
within the buffer are demangled, making their decoded C++ forms
visible.

Visit `https://github.com/liblit/demangle-mode/issues' or use
\\[demangle-mode-submit-bug-report] to report bugs in
`demangle-mode'."
  :lighter " Demangle"
  :keymap demangle-mode-map
  (if demangle-mode
      (progn
	(demangle--setq-local font-lock-extra-managed-props
			      `(display help-echo . ,font-lock-extra-managed-props))
	(font-lock-add-keywords nil demangle-font-lock-keywords)
	(demangle-font-lock-refresh))
    (font-lock-remove-keywords nil demangle-font-lock-keywords)
    (font-lock-unfontify-buffer)
    (dolist (property '(display help-echo))
      (demangle--setq-local font-lock-extra-managed-props
			    (cl-delete property font-lock-extra-managed-props :count 1)))
    (font-lock-mode (or font-lock-mode -1))))

(defun demangle-show-as (style)
  "Show demangled symbols in the given STYLE: either 'demangled or 'mangled."
  (interactive
   `(,(intern (let ((completion-ignore-case t))
		(completing-read "Show demangled symbols as demangled or mangled: "
				 '("demangled" "mangled") nil t nil nil
				 (cl-ecase demangle-show-as
				   ('demangled "mangled")
				   ('mangled "demangled")))))))
  (set-variable 'demangle-show-as style)
  (save-current-buffer
    (dolist (buffer (buffer-list))
      (set-buffer buffer)
      (when demangle-mode
	(demangle-font-lock-refresh)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  bug reporting
;;

(defconst demangle-mode-version "1.2.2"
  "Package version number for use in bug reports.")

(defconst demangle-mode-maintainer-address "Ben Liblit <liblit@acm.org>"
  "Package maintainer name and e-mail address for use in bug reports.")

(defun demangle-mode-submit-bug-report (use-github)
  "Report a `demangle-mode' bug.

If USE-GITHUB is non-nil, directs web browser to GitHub issue
tracker.  This is the preferred reporting channel.  Otherwise,
initiates (but does not send) e-mail to the package maintainer.
Interactively, prompts for the method to use."
  (interactive
   `(,(y-or-n-p "Can you use a GitHub account for issue reporting? ")))
  (if use-github
      (browse-url "https://github.com/liblit/demangle-mode/issues")
    (eval-when-compile (require 'reporter))
    (let ((reporter-prompt-for-summary-p t))
      (reporter-submit-bug-report
       demangle-mode-maintainer-address
       (concat "demangle-mode.el " demangle-mode-version)
       '(demangle-mode
	 demangle-show-as
	 demangle--queue
	 font-lock-mode
	 font-lock-keywords)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; mode-specific menu
;;

(easy-menu-define nil demangle-mode-map nil
  '("Demangle"
    ["Show Demangled Symbols"
     (demangle-show-as 'demangled)
     :style radio
     :selected (eq demangle-show-as 'demangled)]
    ["Show Mangled Symbols"
     (demangle-show-as 'mangled)
     :style radio
     :selected (eq demangle-show-as 'mangled)]
    "-"
    ["Report bug in minor mode" demangle-mode-submit-bug-report]
    ;; standard menu items copied from `minor-mode-menu-from-indicator'
    ["Turn Off minor mode" (demangle-mode 0)]
    ["Help for minor mode" (describe-function 'demangle-mode)]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  epilogue
;;

(provide 'demangle-mode)
;;; demangle-mode.el ends here
