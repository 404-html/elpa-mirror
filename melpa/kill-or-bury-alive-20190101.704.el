;;; kill-or-bury-alive.el --- Precise control over buffer killing in Emacs -*- lexical-binding: t; -*-
;;
;; Copyright © 2015–2019 Mark Karpov <markkarpov92@gmail.com>
;;
;; Author: Mark Karpov <markkarpov92@gmail.com>
;; URL: https://github.com/mrkkrp/kill-or-bury-alive
;; Package-Version: 20190101.704
;; Version: 0.1.3
;; Package-Requires: ((emacs "24.4") (cl-lib "0.5"))
;; Keywords: buffer, killing, convenience
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Have you ever killed a buffer that you might want to leave alive?
;; Motivation for killing is usually “get out of my way for now”, and
;; killing may be not the best choice in many cases unless your RAM is
;; very-very limited.  This package allows to teach Emacs which buffers to
;; kill and which to bury alive.
;;
;; When we really want to kill a buffer, it turns out that not all buffers
;; would like to die the same way.  The package allows to specify *how* to
;; kill various kinds of buffers.  This may be especially useful when you're
;; working with some buffer that has an associated process, for example.
;;
;; Sometimes you may want to get rid of most buffers and bring Emacs to some
;; more-or-less virgin state.  You probably don't want to kill scratch
;; buffer and maybe ERC-related buffers too.  You can specify which buffers
;; to purge.

;;; Code:

(require 'cl-lib)

(defgroup kill-or-bury-alive nil
  "Precise control over buffer killing in Emacs."
  :group  'convenience
  :tag    "Kill or Bury Alive"
  :prefix "kill-or-bury-alive-"
  :link   '(url-link :tag "GitHub"
                     "https://github.com/mrkkrp/kill-or-bury-alive"))

;;;###autoload
(defcustom kill-or-bury-alive-must-die-list nil
  "List of buffer designators for buffers that always should be killed.

See description of `kill-or-bury-alive--buffer-match' for
information about the concept of buffer designators.

This variable is used by `kill-or-bury-alive' function."
  :tag "Must die list"
  :type '(repeat :tag "Buffer Designators"
                 (choice (regexp :tag "Buffer Name")
                         (symbol :tag "Major Mode"))))

;;;###autoload
(defcustom kill-or-bury-alive-killing-function-alist nil
  "AList that maps buffer designators to functions that should kill them.

See description of `kill-or-bury-alive--buffer-match' for
information about the concept of buffer designators.

This variable is used by `kill-or-bury-alive' and
`kill-or-bury-alive-purge-buffers'.

You can use `kill-or-bury-alive-kill-with' to add elements to this alist."
  :tag "Killing function alist"
  :type '(alist :key-type (choice :tag "Buffer Designator"
                                  (regexp :tag "Buffer Name")
                                  (symbol :tag "Major Mode"))
                :value-type (function :tag "Killing Function")))

;;;###autoload
(defcustom kill-or-bury-alive-long-lasting-list
  '("^\\*scratch\\*$"
    "^\\*Messages\\*$"
    "^ ?\\*git-credential-cache--daemon\\*$"
    erc-mode)
  "List of buffer designators for buffers that should not be purged.

See description of `kill-or-bury-alive--buffer-match' for
information about the concept of buffer designators.

This variable is used by `kill-or-bury-alive-purge-buffers'."
  :tag "Long lasting list"
  :type '(repeat :tag "Buffer Designators"
                 (choice (regexp :tag "Buffer Name")
                         (symbol :tag "Major Mode"))))

(defcustom kill-or-bury-alive-killing-function nil
  "The default function for buffer killing.

This is used when nothing is found in
`kill-or-bury-alive-killing-function-alist'.

The function should be able to take one argument: buffer object
to kill or its name.

If value of the variable is NIL, `kill-buffer' is used."
  :tag "Killing function"
  :type '(choice function
                 (const :tag "Use Default" nil)))

(defcustom kill-or-bury-alive-burying-function nil
  "Function used by `kill-or-bury-alive' to bury a buffer.

The function should be able to take one argument: buffer object
to bury or its name.

If value of the variable is NIL,
`kill-or-bury-alive--bury-buffer*' is used."
  :tag "Burying function"
  :type '(choice function
                 (const :tag "Use Default" nil)))

(defcustom kill-or-bury-alive-base-buffer "*scratch*"
  "Name of the buffer to switch to after `kill-or-bury-alive-purge-buffers'."
  :tag "Base buffer"
  :type 'string)

;;;###autoload
(defun kill-or-bury-alive-kill-with
    (buffer-designator killing-function &optional simple)
  "Kill buffers selected by BUFFER-DESIGNATOR with KILLING-FUNCTION.

See description of `kill-or-bury-alive--buffer-match' for
information about the concept of buffer designators.

Normally, KILLING-FUNCTION should be able to take one argument:
buffer object.  However, you can use a function that operates on
current buffer and doesn't take any arguments.  Just pass non-NIL
SIMPLE argument and KILLING-FUNCTION will be wrapped as needed
automatically."
  (push (cons buffer-designator
              (if simple
                  (lambda (buffer)
                    (with-current-buffer buffer
                      (funcall killing-function)))
                killing-function))
        kill-or-bury-alive-killing-function-alist))

(defun kill-or-bury-alive--buffer-match (buffer buffer-designator)
  "Return non-NIL value if BUFFER matches BUFFER-DESIGNATOR.

BUFFER should be a buffer object.  Buffer designator can be a
string (regexp to match name of buffer) or a symbol (major mode
of buffer)."
  (when (get-buffer buffer)
    (if (stringp buffer-designator)
        (string-match-p buffer-designator
                        (buffer-name buffer))
      (with-current-buffer buffer
        (or (eq major-mode buffer-designator)
            (derived-mode-p buffer-designator))))))

(defun kill-or-bury-alive--must-die-p (buffer)
  "Return non-NIL value when BUFFER must be killed no matter what."
  (cl-some (apply-partially #'kill-or-bury-alive--buffer-match buffer)
           kill-or-bury-alive-must-die-list))

(defun kill-or-bury-alive--long-lasting-p (buffer)
  "Return non-NIL value when BUFFER is a long lasting one."
  (cl-some (apply-partially #'kill-or-bury-alive--buffer-match buffer)
           kill-or-bury-alive-long-lasting-list))

(defun kill-or-bury-alive--kill-buffer (buffer)
  "Kill buffer BUFFER according to killing preferences.

Variable `kill-or-bury-alive-killing-function-alist' is used to find how to
kill BUFFER.  If nothing special is found,
`kill-or-bury-alive-killing-function' is used."
  (funcall
   (or (cdr
        (cl-find-if
         (apply-partially #'kill-or-bury-alive--buffer-match buffer)
         kill-or-bury-alive-killing-function-alist
         :key #'car))
       kill-or-bury-alive-killing-function
       #'kill-buffer)
   buffer))

(defun kill-or-bury-alive--bury-buffer* (buffer-or-name)
  "This is rewrite of `bury-buffer' that works for any BUFFER-OR-NAME."
  (let ((buffer (window-normalize-buffer buffer-or-name)))
    (bury-buffer-internal buffer)
    (when (eq buffer (window-buffer))
      (unless (window--delete nil t)
        (set-window-dedicated-p nil nil)
        (switch-to-prev-buffer nil 'bury)))
    nil))

(defun kill-or-bury-alive--bury-buffer (buffer)
  "Bury buffer BUFFER according to burying preferences.

`kill-or-bury-alive-burying-function' is used to bury the buffer,
see its description for more information."
  (funcall (or kill-or-bury-alive-burying-function
               #'kill-or-bury-alive--bury-buffer*)
           buffer))

;;;###autoload
(defun kill-or-bury-alive (&optional arg)
  "Kill or bury the current buffer.

This is a universal killing mechanism.  When argument ARG is
given and it's not NIL, kill current buffer.  Otherwise behavior
of this command varies.  If current buffer matches a buffer
designator listed in `kill-or-bury-alive-must-die-list', kill it
immediately, otherwise just bury it.

You can specify how to kill various kinds of buffers, see
`kill-or-bury-alive-killing-function-alist' for more information.
Buffers are killed with `kill-or-bury-alive-killing-function' by
default."
  (interactive "P")
  (let ((buffer (current-buffer)))
    (if (or arg (kill-or-bury-alive--must-die-p buffer))
        (when (or (not (kill-or-bury-alive--long-lasting-p buffer))
                  (yes-or-no-p
                   (format "Buffer ‘%s’ is a long lasting one, kill?"
                           (buffer-name buffer))))
          (kill-or-bury-alive--kill-buffer buffer))
      (kill-or-bury-alive--bury-buffer buffer))))

;;;###autoload
(defun kill-or-bury-alive-purge-buffers (&optional arg)
  "Kill all buffers except for long lasting ones.

Long lasting buffers are specified in `kill-or-bury-alive-long-lasting-list'.

If `kill-or-bury-alive-base-buffer' is not NIL, switch to buffer
with that name after purging and delete all other windows.

When ARG is given and it's not NIL, ask to confirm killing of
every buffer."
  (interactive "P")
  (dolist (buffer (buffer-list))
    (let ((buffer-name (buffer-name buffer)))
      (when (and buffer-name
                 (not (kill-or-bury-alive--long-lasting-p buffer))
                 (or (not arg)
                     (yes-or-no-p
                      (format "Kill ‘%s’?" buffer-name))))
        (kill-or-bury-alive--kill-buffer buffer))))
  (when kill-or-bury-alive-base-buffer
    (switch-to-buffer kill-or-bury-alive-base-buffer)
    (delete-other-windows)))

(provide 'kill-or-bury-alive)

;;; kill-or-bury-alive.el ends here
