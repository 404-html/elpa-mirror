## Install:

Install LanguageTool version 3.0 or later (and java)
https://languagetool.org/

Put this file into load-path'ed directory, and byte compile it if
desired. And put the following expression into your ~/.emacs.

    (setq langtool-language-tool-jar "/path/to/languagetool-commandline.jar")
    (require 'langtool)

Alternatively, you can set the classpath where LanguageTool's jars reside:

    (setq langtool-java-classpath
          "/usr/share/languagetool:/usr/share/java/languagetool/*")
    (require 'langtool)

You can use HTTP server implementation which is now testing.  This
is very fast, but has security risk if there is multiple user on a
same host. You can set both of
`langtool-language-tool-jar' and `langtool-language-tool-server-jar'
the later is prior than the former.
[Recommended] You should set `langtool-language-tool-jar' correctly
   full of completion support like available languages.

    (setq langtool-language-tool-server-jar "/path/to/languagetool-server.jar")

You can change HTTP server port number like following.

    (setq langtool-server-user-arguments '("-p" "8082"))

These settings are optional:

* Key binding if you desired.

    (global-set-key "\C-x4w" 'langtool-check)
    (global-set-key "\C-x4W" 'langtool-check-done)
    (global-set-key "\C-x4l" 'langtool-switch-default-language)
    (global-set-key "\C-x44" 'langtool-show-message-at-point)
    (global-set-key "\C-x4c" 'langtool-correct-buffer)

* Default language is detected by LanguageTool automatically.
  Please set `langtool-default-language` if you need specific language.

    (setq langtool-default-language "en-US")

  Otherwise, invoke `M-x langtool-check` with `C-u` (universal-argument)

* Currently GNU java version is not working.
  Please change the variable to your favorite java executable.

    (setq langtool-java-bin "/path/to/java")

* Maybe your LanguageTool have launcher. (e.g. Gentoo)
  You need to set `langtool-bin'.
  See https://github.com/mhayashi1120/Emacs-langtool/issues/24

    (setq langtool-bin "/usr/bin/languagetool")

* Maybe you want to specify your mother tongue.

    (setq langtool-mother-tongue "en")

* To customize LanguageTool commandline arguments.

    (setq langtool-java-user-arguments '("-Dfile.encoding=UTF-8"))

  You can also make the variable to buffer local like following:

    (add-hook '**SOME**-mode-hook
              (lambda () (set (make-local-variable 'langtool-java-user-arguments)
                             '("-Dfile.encoding=UTF-8"))))

  NOTE: Although there is no good example, `langtool-user-arguments' is
  a similar custom variable.

## Usage:

* To check current buffer and show warnings.

    M-x langtool-check

  Check with different language. You can complete supported language
  with C-i/TAB

    C-u M-x langtool-check

* To correct marker follow LanguageTool suggestions.

    M-x langtool-correct-buffer

* Go to warning point you can see a report from LanguageTool.
  Otherwise:

    M-x langtool-show-message-at-point

* Show LanguageTool report automatically by `popup'
  This idea come from:
  http://d.hatena.ne.jp/LaclefYoshi/20150912/langtool_popup

    (defun langtool-autoshow-detail-popup (overlays)
      (when (require 'popup nil t)
        ;; Do not interrupt current popup
        (unless (or popup-instances
                    ;; suppress popup after type `C-g' .
                    (memq last-command '(keyboard-quit)))
          (let ((msg (langtool-details-error-message overlays)))
            (popup-tip msg)))))

    (setq langtool-autoshow-message-function
          'langtool-autoshow-detail-popup)

* To finish checking. All langtool marker is removed.

    M-x langtool-check-done
