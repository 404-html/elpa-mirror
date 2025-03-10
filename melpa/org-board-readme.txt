org-board uses `org-attach' and `wget' to provide a bookmarking and
web archival system  directly from an Org file.   Any `wget' switch
can be used  in `org-board', and presets (like user  agents) can be
set for easier  control.  Every snapshot is logged and  saved to an
automatically generated folder, and snapshots for the same link can
be compared using the `ztree' package (optional dependency; `ediff'
used if `zdiff' is not available).  Arbitrary functions can also be
run after an archive, allowing for extensive user customization.

Commands defined here:

  `org-board-archive', `org-board-archive-dry-run',
  `org-board-cancel', `org-board-delete-all', `org-board-diff',
  `org-board-diff3', `org-board-new', `org-board-open',
  `org-board-run-after-archive-function'.

Functions defined here:

  `org-board-expand-regexp-alist', `org-board-extend-default-path',
  `org-board-make-timestamp', `org-board-open-with',
  `org-board-options-handler',
  `org-board-test-after-archive-function',
  `org-board-thing-at-point', `org-board-wget-call',
  `org-board-wget-process-sentinel-function'.

Variables defined here:

  `org-board-after-archive-functions',
  `org-board-agent-header-alist', `org-board-archive-date-format',
  `org-board-default-browser', `org-board-domain-regexp-alist',
  `org-board-log-wget-invocation', `org-board-wget-program',
  `org-board-wget-show-buffer', `org-board-wget-switches'.

Keymap defined here:

  `org-board-keymap'.

Functions advised here:

  `org-thing-at-point', with `org-board-thing-at-point'.

Documentation:

* Motivation

 org-board is a bookmarking and web archival system for Emacs Org
 mode, building on ideas from Pinboard <https://pinboard.in>.  It
 archives your bookmarks so that you can access them even when
 you're not online, or when the site hosting them goes down.
 `wget' is used as a backend for archival, so any of its options
 can be used directly from org-board.  This means you can download
 whole sites for archival with a couple of keystrokes, while
 keeping track of your archives from a simple Org file.

* Summary

 In org-board, a bookmark is represented by an Org heading of any
 level, with a `URL' property containing one or more URLs.  Once
 such a heading is created, a call to `org-board-archive' creates a
 unique ID and directory for the entry via `org-attach', archives
 the contents and requisites of the page(s) listed in the `URL'
 property using `wget', and saves them inside the entry's
 directory.  A link to the (timestamped) root archive folder is
 created in the property `ARCHIVED_AT'.  Multiple archives can be
 made for each entry.  Additional options to pass to `wget' can be
 specified via the property `WGET_OPTIONS'.  The variable
 `org-board-after-archive-functions' (defaulting to nil) holds a
 list of functions to run after each archival operation.

* User commands

 `org-board-archive' archives the current entry, creating a unique
   ID and directory via `org-attach' if necessary.

 `org-board-archive-dry-run' shows the `wget' invocation that will
   run for this entry in the echo area.

 `org-board-new' prompts for a URL to add to the current entry's
   properties, then archives the entry immediately.

 `org-board-delete-all' deletes all the archives for this entry by
   deleting the `org-attach' directory.

 `org-board-open' opens the bookmark at point in a browser.
   Default to the built-in browser, `eww', and with prefix, the
   native operating system browser.

 `org-board-diff' uses `zdiff' (if available) or `ediff' to
   recursively diff two archives of the same entry.

 `org-board-diff3' uses `ediff' to recursively diff three archives
   of the same entry.

 `org-board-cancel' cancels the current org-board archival process.

 `org-board-run-after-archive-function' prompts for a function and
   an archive in the current entry, and applies the function to the
   archive.

 These are all bound in the `org-board-keymap' variable (not bound
 to any key by default).

* Customizable options

 `org-board-wget-program' is the path to the wget program.

 `org-board-wget-switches' are the command line options to use with
 `wget'.  By default these are included as:

   "-e robots=off"      ignores robots.txt files.
   "--page-requisites"  downloads all page requisites (CSS, images).
   "--adjust-extension" add a ".html" extension where needed.
   "--convert-links"    convert external links to internal.

 `org-board-agent-header-alist' is an alist mapping agent names to
 their respective header/user-agent arguments.  Set a
 `WGET_OPTIONS' property to a key of this alist (say,
 `Mac-OS-10.8') and org-board will replace the key with its
 corresponding value before calling wget.  This is useful for some
 sites that refuse to serve pages to `wget'.

 `org-board-wget-show-buffer' controls whether the archival process
 buffer is shown in a window (defaults to true).

 `org-board-log-wget-invocation' controls whether to log the
 archival process command in the root of the archival directory
 (defaults to true).

 `org-board-domain-regexp-alist' applies certain options when a
 domain matches a regular expression.  See the docstring for
 details.  As an example, this is used to make sure that `wget'
 does not send a User Agent string when archiving from Google
 Cache, which will not normally serve pages to it.

 `org-board-after-archive-functions' (default nil) holds a list of
 functions to run after an archival takes place.  This is intended
 for user extensions to `org-board'.  The functions receive three
 arguments: a list of URLs downloaded, the folder name where they
 were downloaded and the process filter event string (see the Elisp
 manual for details on the possible values of this string).  For an
 example use of `org-board-after-archive-functions', see the
 "Example usage" section below.

* Known limitations

 Options like "--header: 'Agent X" cannot be specified as
 properties, because the property API splits on spaces, and such an
 option has to be passed to `wget' as one argument.  To work around
 this, add these types of options to `org-board-agent-header-alist'
 instead, where the property API is not involved.

 At the moment, only one archive can be done at a time.

* Example usage

** Archiving

 I recently found a list of articles on linkers that I wanted to
 bookmark and keep locally for offline reading.  In a dedicated org
 file for bookmarks I created this entry:

 ** TODO Linkers (20-part series)
 :PROPERTIES:
 :URL:          http://a3f.at/lists/linkers
 :WGET_OPTIONS: --recursive -l 1 --span-hosts
 :END:

 Where the `URL' property is a page that already lists the URLs
 that I wanted to download.  I specified the recursive property for
 `wget' along with a depth of 1 ("-l 1") so that each linked page
 would be downloaded.  With point inside the entry, I run "M-x
 org-board-archive".  An `org-attach' directory is created and
 `wget' starts downloading the pages to it.  Afterwards, the end
 the entry looks like this:

 ** TODO Linkers (20-part series)
 :PROPERTIES:
 :URL:          http://a3f.at/lists/linkers
 :WGET_OPTIONS: --recursive -l 1 --span-hosts
 :ID:           D3BCE79F-C465-45D5-847E-7733684B9812
 :ARCHIVED_AT:  [2016-08-30-Tue-15-03-56]
 :END:

 The value in the `ARCHIVED_AT' property is a link that points to
 the root of the timestamped archival directory.  The ID property
 was automatically generated by `org-attach'.

** Diffing

 You can diff between two archives done for the same entry using
 `org-board-diff', so you can see how a page has changed over time.
 The diff recurses through the directory structure of an archive
 and will highlight any changes that have been made.  `ediff' is
 used if `zdiff' is not available (both are capable of recursing
 through a directory structure, but `zdiff' is possibly more
 intuitive to use).  `org-board-diff3' also offers diffing between
 three different archive directories.

** `org-board-after-archive-functions'

 `org-board-after-archive-functions' is a list of functions run
 after an archive is finished.  You can use it to do anything you
 like with newly archived pages.  For example, you could add a
 function that copies the new archive to an external hard disk, or
 opens the archived page in your browser as soon as it is done
 downloading.  You could also, for instance, copy all of the media
 files that were downloaded to your own media folder, and pop up a
 Dired buffer inside that folder to give you the chance to
 organize them.

 Here is an example function that copies the archived page to an
 external service called `IPFS' <http://ipfs.io/>, a decentralized
 versioning and storage system geared towards web content (thanks
 to Alan Schmitt):

 (defun org-board-add-to-ipfs (urls output-folder event &rest _rest)
   "Add the downloaded site to IPFS."
   (unless (string-match "exited abnormally" event)
     (let* ((parsed-url (url-generic-parse-url (car urls)))
            (domain (url-host parsed-url))
            (path (url-filename parsed-url))
            (output (shell-command-to-string
                  (concat "ipfs add -r "
                          (concat output-folder domain))))
            (ipref
          (nth 1 (split-string
                  (car (last (split-string output "\n" t))) " "))))
       (with-current-buffer (get-buffer-create "*org-board-post-archive*")
         (princ (format "your file is at %s\n"
                     (concat "http://localhost:8080/ipfs/" ipref path))
             (current-buffer))))))

 (eval-after-load "org-board"
   '(add-hook 'org-board-after-archive-functions 'org-board-add-to-ipfs))

 Note that for forward compatibility, it's best to add to a final
 `&rest' argument to every function listed in
 `org-board-after-archive-functions', since a future update may
 provide each function with additional arguments (like a marker
 pointing to a buffer position where the archive was initiated, for
 example).

 For more information on `org-board-after-archive-functions', see
 its docstring and the docstring of
 `org-board-test-after-archive-function'.

 You can also interactively run an after-archive function with the
 command `org-board-run-after-archive-function'.  See its docstring
 for details.


* Getting started

** Installation

 There are two ways to install the package.  One way is to clone
 this repository and add the directory to your load-path manually.

 (add-to-list 'load-path "/path/to/org-board")
 (require 'org-board)

 Alternatively, you can download the package directly from Emacs
 using MELPA <https://github.com/melpa/melpa>.  M-x
 package-install RET org-board RET will take care of it.

** Keybindings

 The following keymap is defined in `org-board-keymap':

 | Key | Command                              |
 | a   | org-board-archive                    |
 | r   | org-board-archive-dry-run            |
 | n   | org-board-new                        |
 | k   | org-board-delete-all                 |
 | o   | org-board-open                       |
 | d   | org-board-diff                       |
 | 3   | org-board-diff3                      |
 | c   | org-board-cancel                     |
 | x   | org-board-run-after-archive-function |
 | O   | org-attach-reveal-in-emacs           |
 | ?   | Show help for this keymap.           |

 To install the keymap give it a prefix key, e.g.:

 (global-set-key (kbd "C-c o") org-board-keymap)

 Then typing `C-c o a' would run `org-board-archive', for example.

* Miscellaneous

 The location of `wget' should be picked up automatically from the
 `PATH' environment variable.  If it is not, then the variable
 `org-board-wget-program' can be customized.

 Other options are already set so that archiving bookmarks is done
 pretty much automatically.  With no `WGET_OPTIONS' specified, by
 default `org-board-archive' will just download the page and its
 requisites (images and CSS), and nothing else.

** Support for org-capture from Firefox (thanks to Alan Schmitt):

 On the Firefox side, install org-capture from here:

   http://chadok.info/firefox-org-capture/

 Alternatively, you can do it manually by following the
 instructions here:

   http://weblog.zamazal.org/org-mode-firefox/
     (in the “The advanced way” section)

 When org-capture is installed, add `(require 'org-protocol)' to
 your init file (`~/.emacs').

 Then create a capture template like this:

   (setq org-board-capture-file "my-org-board.org")

   (setq org-capture-templates
         `(...
           ("c" "capture through org protocol" entry
             (file+headline ,org-board-capture-file "Unsorted")
             "* %?%:description\n:PROPERTIES:\n:URL: %:link\n:END:\n\n Added %U")
           ...))

 And add a hook to `org-capture-before-finalize-hook':

   (defun do-org-board-dl-hook ()
     (when (equal (buffer-name)
             (concat "CAPTURE-" org-board-capture-file))
       (org-board-archive)))

   (add-hook 'org-capture-before-finalize-hook 'do-org-board-dl-hook)

* Acknowledgements

 Thanks to Alan Schmitt for the code to combine `org-board' and
 `org-capture', and for the example function used in the
 documentation of `org-board-after-archive-functions' above.
