;;; language-id.el --- Library to work with programming language identifiers -*- lexical-binding: t -*-
;;
;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/lassik/emacs-language-id
;; Package-Version: 20190207.1057
;; Version: 0.1.0
;; Package-Requires: ((emacs "24") (cl-lib "0.5"))
;; Keywords: languages util
;; License: MIT
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; language-id is a small, focused library that helps other Emacs
;; packages identify the programming languages and markup languages
;; used in Emacs buffers.  The main point is that it contains an
;; evolving table of language definitions that doesn't need to be
;; replicated in other packages.
;;
;; Right now there is only one public function, `language-id-buffer'.
;; It looks at the major mode and other variables and returns the
;; language's GitHub Linguist identifier.  We can add support for
;; other kinds of identifiers if there is demand.
;;
;; This library does not do any statistical text matching to guess the
;; language.
;;
;;; Code:

(defvar language-id-file-name-extension nil
  "Internal variable for file name extension during lookup.")

(defconst language-id-definitions
  '(

    ;; TypeScript/TSX need to come before JavaScript/JSX because in
    ;; web-mode we can tell them apart by file name extension only.
    ;; This implies that unsaved temp buffers using TypeScript/TSX in
    ;; web-mode are classified as JavaScript/JSX.
    ;;
    ;; Also, GitHub Linguist currently conflates both TypeScript and
    ;; TSX under the TypeScript language ID, whereas JavaScript and
    ;; JSX have separate language IDs.
    ("TypeScript"
     typescript-mode
     typescript-tsx-mode
     (web-mode
      (web-mode-content-type "javascript")
      (web-mode-engine "none")
      (language-id-file-name-extension ".ts"))
     (web-mode
      (web-mode-content-type "jsx")
      (web-mode-engine "none")
      (language-id-file-name-extension ".tsx")))

    ("Assembly"
     asm-mode
     nasm-mode)
    ("C"
     c-mode)
    ("C++"
     c++-mode)
    ("Clojure"
     clojure-mode
     clojurec-mode
     clojurescript-mode)
    ("Crystal"
     crystal-mode)
    ("CSS"
     css-mode
     (web-mode (web-mode-content-type "css") (web-mode-engine "none")))
    ("D"
     d-mode)
    ("Dart"
     dart-mode)
    ("Elixir"
     elixir-mode)
    ("Elm"
     elm-mode)
    ("Emacs Lisp"
     emacs-lisp-mode
     lisp-interaction-mode)
    ("Go"
     go-mode)
    ("GraphQL"
     graphql-mode)
    ("Haskell"
     haskell-mode)
    ("HTML"
     html-helper-mode
     html-mode
     mhtml-mode
     nxhtml-mode
     (web-mode (web-mode-content-type "html") (web-mode-engine "none")))
    ("Java"
     java-mode)
    ("JavaScript"
     (js-mode (flow-minor-mode nil))
     (js2-mode (flow-minor-mode nil))
     (js3-mode (flow-minor-mode nil))
     (web-mode (web-mode-content-type "javascript") (web-mode-engine "none")))
    ("JSON"
     json-mode
     (web-mode (web-mode-content-type "json") (web-mode-engine "none")))
    ("JSX"
     js2-jsx-mode
     jsx-mode
     rjsx-mode
     (web-mode (web-mode-content-type "jsx") (web-mode-engine "none")))
    ("Kotlin"
     kotlin-mode)
    ("Less"
     less-css-mode)
    ("Literate Haskell"
     literate-haskell-mode)
    ("Lua"
     lua-mode)
    ("Markdown"
     gfm-mode
     markdown-mode)
    ("Objective-C"
     objc-mode)
    ("OCaml"
     caml-mode
     tuareg-mode)
    ("Perl"
     perl-mode)
    ("PHP"
     php-mode)
    ("Protocol Buffer"
     protobuf-mode)
    ("Python"
     python-mode)
    ("Ruby"
     enh-ruby-mode
     ruby-mode)
    ("Rust"
     rust-mode)
    ("SCSS"
     scss-mode)
    ("Shell"
     sh-mode)
    ("SQL"
     sql-mode)
    ("Swift"
     swift-mode
     swift3-mode)
    ("Vue"
     vue-mode
     (web-mode (web-mode-content-type "html") (web-mode-engine "vue")))
    ("XML"
     nxml-mode
     xml-mode
     (web-mode (web-mode-content-type "xml") (web-mode-engine "none")))
    ("YAML"
     yaml-mode)
    )
  "Internal table of programming language definitions.")

(defun language-id-mode-match-p (mode)
  "Interal helper to match current buffer against MODE."
  (let ((mode (if (listp mode) mode (list mode))))
    (cl-destructuring-bind (wanted-major-mode . variables) mode
      (and (derived-mode-p wanted-major-mode)
           (cl-every (lambda (variable)
                       (cl-destructuring-bind (symbol wanted-value) variable
                         (equal wanted-value
                                (when (boundp symbol) (symbol-value symbol)))))
                     variables)))))

(defun language-id-buffer ()
  "Get GitHub Linguist language name for current buffer.

Return the name of the programming language or markup language
used in the current buffer.  The name is a string from the GitHub
Linguist language list.  The language is determined by looking at
the active `major-mode'.  Some major modes support more than one
language.  In that case minor modes and possibly other variables
are consulted to disambiguate the language.

In addition to the modes bundled with GNU Emacs, many third-party
modes are recognized.  No statistical text matching or other
heuristics are used in detecting the language.

The language definitions live inside the language-id library and
are updated in new releases of the library.

If the language is not unambiguously recognized, the function
returns nil."
  (let ((language-id-file-name-extension
         (downcase (file-name-extension (or (buffer-file-name) "") t))))
    (cl-some (lambda (definition)
               (cl-destructuring-bind (language-id . modes) definition
                 (when (cl-some #'language-id-mode-match-p modes)
                   language-id)))
             language-id-definitions)))

(provide 'language-id)

;;; language-id.el ends here
