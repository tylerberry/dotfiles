;;; .emacs --- Tyler Berry's Emacs configuration file        -*- Emacs-Lisp -*-

;; Copyright (C) 2003, 2004, 2005, 2006, 2007 Tyler Berry
;; Author: Tyler Berry <tyler@thoughtlocker.net>
;; Keywords: local
;; Time-stamp: <2009-08-29 14:24:42 tyler>

;; This file is free software; you can redistribute it and/or modify it under
;; the terms of version 2 of the GNU General Public License as published by the
;; Free Software Foundation.
;;
;; This file is distributed in the hope that it will be useful, but WITHOUT ANY
;; WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the version 2 of the GNU General Public
;; License along with Emacs; type C-h C-c inside GNU Emacs, or C-h C-l inside
;; XEmacs, to view the license.  The license is also available at
;; <http://www.gnu.org/copyleft/gpl.html>, and by writing to the Free Software
;; Foundation at this address:
;;
;;   Free Software Foundation, Inc.
;;   59 Temple Place - Suite 330
;;   Boston, MA  02111-1307
;;   United States of America

;;; Commentary:

;; This is my .emacs file, based heavily on Ted O'Connor's, with additions from
;; the Emacs Wiki and other sources.  Feel free to do with it as you like and
;; the GPL permits, and please let me know of any problems or bugs you find.

;;; Debugging:

;; These are useful when I'm working on this file.

;(setq debug-on-error t
;      debug-on-quit  t)
;
;(defmacro nop (&rest args) nil)

;;; Replacement functions:

;; Recent versions of Emacs have added functions and macros not available in
;; earlier versions or flavors.  These replacement versions ensure that I can
;; use these convenient functions.

(if (not (fboundp 'when))
    (defmacro when (test &rest body)
      "If TEST is non-nil, evaluate the forms in BODY in an implicit progn.
If TEST is nil, return nil."
      `(if ,test
           (progn ,@body))))

(when (not (fboundp 'unless))
  (defmacro unless (test &rest body)
    "If TEST is nil, evaluate the forms in BODY in an implicit progn.
If TEST is non-nil, return nil."
    `(when (not ,test)
       ,@body)))

;; Ted O'Connor: `mapc' is a built-in function in recent GNU Emacsen.  In older
;;   emacsen, there is an implementation of `mapc' in the CL-compatibility
;;   library, but I'd rather not have to `(require `cl)' here.  Besides, it's
;;   easy enough to implement.  Yes, my .emacs file obeys Greenspun's 10th Law.

(unless (fboundp 'mapc)
  (defun mapc (function sequence)
    "Apply FUNCTION across SEQUENCE.

`mapc' doesn't accumulate the results (unlike `mapcar'). Returns
SEQUENCE, which can be anything you can pass to `elt' as its first
argument."
    (let ((length (length sequence))
          (i 0))
      (while (< i length)
        (funcall function (elt sequence i))
        (setq i (+ i 1))))
    sequence))

(unless (fboundp 'kbd)
  (defmacro kbd (key-sequence)
    "Convert KEY-SEQUENCE to the internal Emacs key representation.  KEYS
should be a string in the format used for saving keyboard macros.  (See
`edmacro-mode'.)"
    (read-kbd-macro key-sequence)))

(unless (fboundp 'toggle-debug-on-signal)
  (defun toggle-defun-on-signal ()
    "Toggle whether to enter the Lisp debugger when the signal is raised."
    (interactive)
    (setq debug-on-signal (not debug-on-signal))))

;; Always redefine turn-off-auto-fill, since it is often provided as
;; non-interactive, and it's nice to be able to use it with M-x instead of M-:.

(defun turn-off-auto-fill ()
  "Unconditionally turn off auto-fill-mode."
  (interactive)
  (auto-fill-mode -1))

(unless (fboundp 'save-selected-frame)
  (defmacro save-selected-frame (&rest body)
    "Save the selected frame; execute the forms in BODY; restore the selected
frame.  Executes the forms in BODY just like `progn'."
    (let ((framevar (gensym)))
      `(let ((,framevar (make-symbol "frame")))
         ,@body
         (select-frame ,framevar)))))

(unless (fboundp 'with-selected-frame)
  (defmacro with-selected-frame (frame &rest body)
    "Execute the forms in BODY with FRAME as the selected frame.  Return the
value of the last form in BODY.

Similar in spirit to `with-current-buffer'."
    `(save-selected-frame (select-frame ,frame) ,@body)))

;;; Utilities:

(defmacro ted-ignore-errors (&rest forms)
  "Try to evaluate FORMS, ignoring any errors that may occur."
  `(condition-case nil
       (progn ,@forms)
     (error nil)))

(defun ted-require (package &optional filename)
  "If feature FEATURE is not loaded, load it from FILENAME.

If FILENAME is omitted, the print name of FEATURE is used as the file name, and
`load' will try to load this name appended with the suffix `.elc' or `.el', in
that order.  The name without appended suffix will not be used.

Returns FEATURE if a file providing FEATURE was successfully loaded, or nil if
no such file was found."
  (ted-ignore-errors (require package filename)))

(defmacro ted-use-mode (mode library regexp &rest forms)
  "Autoload MODE from LIBRARY and associate files which match REGEXP with it.
Also, evaluate FORMS if LIBRARY is successfully located."
  (let ((library (or library (symbol-name mode))))
    `(when (locate-library ,library)
       (autoload ',mode ,library nil t)
       ,(when regexp
          `(add-to-list 'auto-mode-alist ',(cons regexp mode)))
       ,@forms)))
(put 'ted-use-mode 'lisp-indent-function 3)

(defmacro ted-make-key-bindings (library prefix &rest bindings)
  "Maybe make key bindings for LIBRARY under PREFIX as described in BINDINGS.

Each element in BINDINGS should be of the form `(function key)'. If LIBRARY
can be found in `load-path', each such function will be autoloaded from
LIBRARY, and bound to its specified key (relative to PREFIX)."
  (let ((library library)
        (map (intern (concat "tyler-" library "-map"))))
    `(when (locate-library ,library)
       (defvar ,map (make-sparse-keymap)
         ,(concat "A keymap for functions in the \"" library "\" library."))
       (global-set-key ,prefix ,map)
       (mapc #'(lambda (cell)
                 (autoload (car cell) ,library nil t)
                 (define-key ,map (cadr cell) (car cell)))
             ',bindings))))
(put 'ted-make-key-bindings 'lisp-indent-function 2)

;; `ted-alist' is useful for making arguments for `completing-read'.

(defun ted-alist (list)
  "Given a list LIST formatted like (A B ... Z), return a new alist formatted
like ((A . A) (B . B) ... (Z . Z)).  If LIST is nil, return nil."
  (mapcar #'(lambda (item) (cons item item)) list))

(defun ted-find-if (predicate list &optional default)
  "Return the first item of LIST satisfying PREDICATE.
Returns DEFAULT if no item satisfies PREDICATE."
  (catch 'found
    (mapc #'(lambda (item)
              (when (funcall predicate item)
                (throw 'found item)))
          list)
    default))

(defun ted-variable-obsolete-p (variable)
  "Return nil unless VARIABLE is marked as obsolete."
  (get variable 'byte-obsolete-variable))

(defmacro ted-add-cmd-line-arg (switch &rest body)
  "When Emacs is given SWITCH as an argument, evaluate the forms in BODY."
  (let ((switch switch))
    `(when (member ,switch command-line-args)
       ,@body
       (setq command-line-args (delete ,switch command-line-args)))))
(put 'ted-add-cmd-line-arg 'lisp-indent-function 1)

(defun ted-add-to-list* (list-var predicate &rest directories)
  "Add to LIST-VAR each item in DIRECTORIES which does not return nil when
PREDICATE is applied to it.

Effectively, this is a multi-argument version of `add-to-list', but is mostly
intended for variables like `load-path' and `Info-default-directory-list'."
  (mapc #'(lambda (directory)
            (when (funcall predicate directory)
              (add-to-list list-var directory)))
        directories))
(put 'ted-add-to-list* 'lisp-indent-function 1)

;;; Version and feature detection stuff:

(defconst tyler-xemacs-flag (featurep 'xemacs)
  "Is this XEmacs?")

(defconst tyler-gnu-emacs-flag (not tyler-xemacs-flag)
  "Is this GNU Emacs?")

(defconst tyler-gnu-emacs-20+-flag
  (and tyler-gnu-emacs-flag (>= emacs-major-version 20)))
(defconst tyler-gnu-emacs-21+-flag
  (and tyler-gnu-emacs-flag (>= emacs-major-version 21)))
(defconst tyler-gnu-emacs-20-flag
  (and tyler-gnu-emacs-flag (= emacs-major-version 20)))
(defconst tyler-gnu-emacs-19-flag
  (and tyler-gnu-emacs-flag (= emacs-major-version 19)))

(defvar tyler-oort+-gnus-flag nil
  "If non-nil, this Emacs is equipped with Oort Gnus or newer.")

(defconst tyler-display-graphic-flag (if (fboundp 'display-graphic-p)
                                         (display-graphic-p)
                                       (if window-system
                                           t
                                         nil))
  "Should we display graphics?")

(defconst tyler-tty-flag (if (fboundp 'console-type) ; XEmacs
                             (eq (console-type) 'tty)
                           (not tyler-display-graphic-flag))
  "Are we using a TTY?")

(defconst tyler-xterm-flag (and tyler-tty-flag
                                (let ((term (getenv "TERM")))
                                  (if term
                                      (if (string-match "xterm" term)
                                          t
                                        nil)
                                    nil)))
  "Are we using an xterm or a derivative thereof?")

(defconst tyler-use-colors-flag
  (cond ((fboundp 'display-color-p)
         (display-color-p))
        (tyler-xemacs-flag t)
        (t tyler-display-graphic-flag))
  "Should we use colors?")

(defvar tyler-use-gnuserv-flag nil
  "Should we use Gnuserv?")

(defconst tyler-w32-window-system-flag (memq window-system '(w32 win32))
  "Are we running graphically under Microsoft Windows?")

(defconst tyler-mac-window-system-flag (eq window-system 'mac)
  "Are we running graphically under the Mac OS?")

(defconst tyler-x-window-system-flag (eq window-system 'x)
  "Are we running graphically under the X Window System?")

(defconst tyler-menu-bar-lines (if tyler-mac-window-system-flag 1 0)
  "Should we display the menu bar?")

(defconst tyler-w32-flag (or tyler-w32-window-system-flag
                             (eq system-type 'windows-nt))
  "Are we running under Microsoft Windows?")

(defconst tyler-mac-flag (or tyler-mac-window-system-flag
                             (eq system-type 'darwin))
  "Are we running on a Macintosh?")

(defconst tyler-most-positive-fixnum (lsh -1 -1))

(defconst tyler-emacs-name
  (let ((version-int (number-to-string emacs-major-version)))
    (cond (tyler-xemacs-flag    (concat "xemacs-" version-int))
          (tyler-gnu-emacs-flag (concat "emacs-" version-int))
          (t                    "unknown-emacs")))
  "The name of this Emacs.")

(defconst tyler-pretty-emacs-name
  (let ((version-int (concat
                      (number-to-string emacs-major-version)
                      "."
                      (number-to-string emacs-minor-version))))
    (cond (tyler-xemacs-flag    (concat "XEmacs " version-int))
          (tyler-gnu-emacs-flag (concat "GNU Emacs " version-int))
          (t                    "Emacs")))
  "The name of this Emacs, formatted prettily.")

;;; File locations and early configuration:

;; Set the default root for my personal files.

(defvar tyler-home-dir "~"
  "Where my home directory is located.")

(defvar tyler-elisp-dir "~/elisp/"
  "Where my Emacs Lisp directory lives.")

(defvar tyler-workspace-dir "~/workspace/"
  "Where my local CVS, SVN, etc. checkouts live.")

(load "~/.emacs-local-pre" t)

(when (file-directory-p (expand-file-name tyler-elisp-dir))

  ;; Frob `load-path' to include my elisp directory.
  (add-to-list 'load-path (expand-file-name tyler-elisp-dir))

  ;; ~/elisp/subdirs.el should load any subdirectories.
  (load (expand-file-name "subdirs" tyler-elisp-dir) t))

;; Bring in CVS versions of various emacs libraries.

(when (file-directory-p (expand-file-name tyler-workspace-dir))
  (ted-add-to-list* 'load-path #'file-directory-p
    (expand-file-name "bbdb/lisp" tyler-workspace-dir)
    (expand-file-name "emacs-w3m" tyler-workspace-dir)
    (expand-file-name "erc" tyler-workspace-dir)
    (expand-file-name "elisp" tyler-workspace-dir)
    (expand-file-name "gnus/lisp" tyler-workspace-dir)
    (expand-file-name "gnus/contrib" tyler-workspace-dir)
    (expand-file-name "ljupdate" tyler-workspace-dir)
    (expand-file-name "slime" tyler-workspace-dir)
    (expand-file-name "url/lisp" tyler-workspace-dir))

  (ted-add-to-list* 'Info-default-directory-list #'file-directory-p
    (expand-file-name "bbdb/texinfo" tyler-workspace-dir)
    (expand-file-name "emacs-w3m/doc" tyler-workspace-dir)
    (expand-file-name "gnus/texi" tyler-workspace-dir)
    (expand-file-name "url/texi" tyler-workspace-dir)))

;; Where do I keep my .emacs?

(defconst tyler-dotemacs-file (expand-file-name ".emacs" tyler-home-dir))

;;; Basic functionality:

;; Who am I?

(let ((user (or user-login-name (getenv "LOGNAME") (getenv "USER")))
      (host (or (getenv "HOST") system-name "unknown")))
  (setq user-mail-address (concat user "@" host)
        user-full-name    "Tyler Berry"))

;; Load Gnus early to make sure it's present for other customizations.

(ted-require 'gnus-load)

;; Don't display the annoying startup screen.

(setq inhibit-startup-message t)

;; Don't fuck up my processes in Mac OS X, please.

(setq process-connection-type t)

;; Fix a couple things which behave gratuitously differently in XEmacs.

(when tyler-xemacs-flag
  (setq apropos-do-all                t
        display-warning-minimum-level 'error
        log-warning-minimum-level     'info
        paren-mode                    'paren
        zmacs-regions                 nil
        highlight-nonselected-windows nil
        mark-even-if-inactive         t)
  (transient-mark-mode 1))

;; Allow the *Messages* buffer to grow indefinitely.  (Or close.)

(setq message-log-max tyler-most-positive-fixnum)

;; Switch from an audible to a visible bell.

(setq ring-bell-function nil
      visible-bell       t)

;; Always add final newlines to buffers without them.

(setq require-final-newline t)

;; Auto-fill by default.

(setq-default auto-fill-function 'do-auto-fill)

;; ...except in these major modes.

(mapc #'(lambda (mode-hook)
          (add-hook mode-hook 'turn-off-auto-fill))
      '(sh-mode-hook comint-mode-hook shell-mode-hook erc-mode-hook
        emacs-lisp-mode-hook lisp-mode-hook))

;; Set the default fill column.

(setq-default fill-column 79)
(setq emacs-lisp-docstring-fill-column 79)

;; Make sure that yanks are inserted at point, not at the location of the
;; mouse.

(setq mouse-yank-at-point t)

;; Arrange for a sane, non-cluttered backup system.

(when tyler-gnu-emacs-21+-flag
  (setq backup-by-copying      t
        backup-directory-alist `(,(cons "." (expand-file-name ".backups"
                                                          tyler-home-dir)))
        kept-new-versions      6
        kept-old-versions      2
        delete-old-versions    t
        version-control        t))

;; Follow symlinks to version-controlled files without asking.

(setq vc-follow-symlinks t)

;; Avoid scrolling by large amounts.

(setq-default scroll-step              1
              scroll-conservatively    tyler-most-positive-fixnum
              scroll-up-aggressively   .01
              scroll-down-aggressively .01)

;; Turn on line and column numbers in the mode line.

(line-number-mode 1)
(when (fboundp 'column-number-mode)
  (column-number-mode 1))

;; Turn on abbrevs.

(setq default-abbrev-mode t)
(when (file-exists-p abbrev-file-name)
  (quietly-read-abbrev-file))
(add-hook 'mail-setup-hook #'mail-abbrevs-setup)

;; Turn on paren matching.

(cond ((fboundp 'show-paren-mode) ; GNU Emacs
       (show-paren-mode 1)
       (make-variable-buffer-local 'show-paren-mode))
      (tyler-xemacs-flag          ; XEmacs
       (setq paren-mode 'paren)
       (make-variable-buffer-local 'paren-mode)))

;; Only show defaults in the minibuffer if the default would be triggered by
;; <RET>.

(when (fboundp 'minibuffer-electric-default-mode)
  (minibuffer-electric-default-mode 1))

;; Keep temporary buffers down to a reasonable size.

(when (fboundp 'temp-buffer-resize-mode)
  (temp-buffer-resize-mode 1))

;; Resize the minibuffer appropriately in different Emacsen.

(cond (tyler-xemacs-flag
       (autoload 'resize-minibuffer-mode "rsz-minibuf" nil t)
       (setq resize-minibuffer-window-exactly t))
      ((not tyler-gnu-emacs-21+-flag)
       (resize-minibuffer-mode 1))
      (t
       (setq max-mini-window-height 0.30)
       (setq resize-mini-window t)))

;; Make Emacs always use spaces.  Never ever use tabs.

(setq-default indent-tabs-mode nil)

;; Indent to mod 2 when the <TAB> key is hit.

(setq-default c-basic-indent 2)

;; Display four spaces when encountering a \t character in a file.

(setq-default tab-width 4)

;; Don't ask for confirmation on yes-or-no questions.

(defalias 'yes-or-no-p 'y-or-n-p)

;; When using isearch, highlight the current match.

(set (if tyler-xemacs-flag 'isearch-highlight 'search-highlight) t)

;; Uniquely identify buffers that happen to have the same name

(when (ted-require 'uniquify)
  (setq-default uniquify-buffer-name-style 'forward))

;; Use `iswitchb' to switch between buffers.  What a massive improvement!

(cond ((fboundp 'iswitchb-mode)                ; GNU Emacs 21
       (iswitchb-mode 1))
      ((fboundp 'iswitchb-default-keybindings) ; Old-style
       (iswitchb-default-keybindings)))

;; Use `partial-completion-mode'.  Very cool.

(when (fboundp 'partial-completion-mode)
  (partial-completion-mode 1))

;; Time stamp files on write.

(add-hook 'write-file-hooks 'time-stamp)

;; Set up e-mail miscellany.

(add-hook 'mail-setup-hook 'mail-abbrevs-setup)

(setq mail-signature    t
      mail-yank-prefix  "> "
      mail-from-style   'angles)

(or (assoc "mutt-" auto-mode-alist)
    (add-to-list 'auto-mode-alist
                 '("mutt-" . mail-mode)))

(add-hook 'mail-mode-hook
          #'(lambda ()
              ;; Kill quoted signatures.
              (flush-lines "^\\(> \n\\)*> -- \n\\(\n?> .*\\)*")
              (setq make-backup-files nil)  ; None necessary.
              (setq fill-column 72)
              (not-modified)))

;; Turn on `truncate-lines' - continuation lines are ugly.

(setq truncate-partial-width-windows nil)
(setq-default truncate-lines t)

(let ((untruncate-lines #'(lambda () (setq truncate-lines nil))))
  (add-hook 'term-mode-hook untruncate-lines)
  (add-hook 'eshell-mode-hook untruncate-lines))

;; My home page; currently temporary.

(defconst tyler-home-page "http://www.google.com/")

;; My current physical location characteristics.

(setq calendar-latitude 40.416667
      calendar-longitude -104.683333
      calendar-location-name "Greeley, CO")

;; Don't echo passwords when in comint.

(add-hook 'comint-output-filter-functions
          #'comint-watch-for-password-prompt)

;; Customize the display of various modes in the modeline.

(setcar (cdr (assq 'abbrev-mode minor-mode-alist)) " A")
(setcar (cdr (assq 'auto-fill-function minor-mode-alist)) "F")
(when (consp (assq 'server-buffer-clients minor-mode-alist))
  (setcar (cdr (assq 'server-buffer-clients minor-mode-alist)) " *S*"))
(add-hook 'sh-mode-hook #'(lambda () (setq mode-name "Shell")))

;; Activate links in text.

(when (fboundp 'goto-address)
  (setq goto-address-fontify-maximum-size tyler-most-positive-fixnum)
  (add-hook 'find-file-hooks 'goto-address))

;; Default browser for TTYs; for a windowing system, the default is usually
;; sensible.  This gets overriden later if emacs-w3m is present.

(when tyler-tty-flag
  (setq browse-url-browser-function 'browse-url-lynx-emacs))

;; Set up a default terminal coding.

(when (and tyler-tty-flag (fboundp 'set-terminal-coding-system))
  (if tyler-xemacs-flag ; Because XEmacs doesn't have UTF-8.
      (set-terminal-coding-system 'iso-8859-1)
    (set-terminal-coding-system 'utf-8)))

;; Group the C-<down-mouse-1> buffer menu by major mode.

(setq mouse-buffer-menu-mode-mult 1)

;; I do not want to assign my copyrights to the FSF, thank you.

(setenv "ORGANIZATION" "Tyler Berry")

;; Disable overwrite-mode entirely.

(put 'overwrite-mode 'disabled t)
(setq overwrite-mode-textual
      (concat " " (propertize "Ovwrt" 'face 'font-lock-warning-face)))

;; Blinking cursors are evil.

(when (fboundp 'blink-cursor-mode)
  (blink-cursor-mode -1))

;; Enable useful disabled commands.

(mapc #'(lambda (sym)
          (put sym 'disabled nil))
      '(downcase-region erase-buffer eval-expression narrow-to-page
        narrow-to-region upcase-region set-goal-column))

;; Use one space at the end of sentences, not two.
;;
;; Commented out because I'm changing my habits.  Texinfo mandates
;; double-spaces, and it's awkward to maintain a double standard.

; (setq sentence-end-double-space nil
;       sentence-end "[.?!][]\"')]*\\($\\|\t\\| \\)[ \t\n]*") ; $

;; ...except in Texinfo, where two spaces is mandatory for formatting purposes.

; (let ((foo '(lambda ()
;               (setq sentence-end-double-space t)
;               (setq sentence-end
;                     "[.?!][]\"`)}]*\\($\\| $\\| \\|  \\)[   \n]*"))))
;   (add-hook 'texinfo-mode-hook foo))

;; If the terminal Emacs is running on sends C-h when the backspace key is
;; pressed, this function can be used to remap C-h to DEL.

(when tyler-tty-flag
  (defun ted-fix-stupid-backspace-key-issue ()
    "Fix this stupid terminal; remap C-h to DEL."
    (interactive)
    (keyboard-translate ?\C-h ?\C-?)
    (message "Backspace has been fixed."))
  (defalias 'fix-stupid-backspace-key-issue 'ted-fix-stupid-backspace-key-issue))

;; Highlight trailing whitespace in various ways for different Emacsen.

;; GNU Emacs 20:

(when (and tyler-use-colors-flag tyler-gnu-emacs-20-flag)
  (defmacro highlight-trailing-whitespace (mode)
    "Highlight trailing whitespace in MODE."
    `(font-lock-add-keywords ,mode '(("[ \t]+$" .
                                      show-paren-match-face))))

  ;; To get various Emacs 20s to DTRT.

  (setq show-paren-match-face default)

  (mapc #'(lambda (mode)
            (highlight-trailing-whitespace mode))
        '(c-mode c++-mode java-mode lisp-mode emacs-lisp-mode
          latex-mode cperl-mode python-mode ruby-mode)))

;; GNU Emacs 21:

(if tyler-gnu-emacs-21+-flag
    (progn
      (setq-default show-trailing-whitespace t)

      (defun ted-hide-trailing-whitespace ()
        "Turn off trailing whitespace highlighting in this buffer."
        (interactive)
        (setq show-trailing-whitespace nil))

      (mapc #'(lambda (mode-hook)
                (add-hook mode-hook 'ted-hide-trailing-whitespace))
            '(Buffer-menu-mode-hook custom-mode-hook term-mode-hook Info-mode-hook
              comint-mode-hook buffer-menu-mode-hook apropos-mode-hook
              tooltip-show-hook gnus-article-mode-hook mail-mode-hook
              gnus-summary-mode-hook message-mode-hook gnus-group-mode-hook
              eshell-mode-hook w3-mode-hook help-mode))

      (mapc #'(lambda (mode-hook)
                (add-hook mode-hook
                          #'(lambda () (setq show-trailing-whitespace t))))
            '(latex-mode-hook LaTeX-mode-hook html-mode-hook)))
  (defun ted-hide-trailing-whitespace ()
    "Placeholder for Emacsen which don't use the show-trailing-whitespace variable."
    (interactive)
    nil))

;; "Clear the screen" losslessly using `recenter'.

(defun ted-clear (&optional prefix)
  "Move the line containing point to the top of the window.

If PREFIX is supplied, move the line containing point to line PREFIX of the
window."
  (interactive "P")
  (recenter (or prefix 0)))

;; A quick function to open a library.

(defun ted-find-library (library)
  "Open LIBRARY."
  (interactive "sLibrary: ")
  (let ((filename (locate-library (concat library ".el"))))
    (if (stringp filename)
        (find-file filename)
      (message "Library %s not found." library))))

;; Ted fixes Emacs to handle O'Connor correctly here.

;; A function to untabify the current buffer.  This comes from jwz.

(defun jwz-untabify-buffer ()
  "Untabify the current buffer."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "[\t ]+$" nil t)
      (delete-region (match-beginning 0) (match-end 0)))
    (goto-char (point-min))
    (when (search-forward "\t" nil t)
      (untabify (1- (point)) (point-max))))
  nil)
(defalias 'untabify-buffer 'jwz-untabify-buffer)

;; A function to indent the current buffer.

(defun tyler-indent-buffer ()
  "Indent the curent buffer."
  (interactive)
  (save-excursion
    (indent-region (point-min) (point-max) nil)))
(defalias 'indent-buffer 'tyler-indent-buffer)

;; Automatically execute this on certain types of source code.

(mapc #'(lambda (mode-hook)
          (add-hook mode-hook 'jwz-untabify-buffer))
      '(c-mode-hook cperl-mode-hook emacs-lisp-mode-hook))

;; These functions convert files between DOS/UNIX/Mac formats.

(defun dos-line-endings ()
  "Sets the buffer-file-coding-system to undecided-dos; changes the buffer
by invisibly adding carriage returns."
  (interactive)
  (set-buffer-file-coding-system 'undecided-dos nil))

(defun unix-line-endings ()
  "Sets the buffer-file-coding-system to undecided-unix; changes the buffer
by invisibly removing carriage returns."
  (interactive)
  (set-buffer-file-coding-system 'undecided-unix nil))

(defun mac-line-endings ()
  "Sets the buffer-file-coding-system to undecided-mac; may change the buffer
by invisibly adding carriage returns."
  (interactive)
  (set-buffer-file-coding-system 'undecided-mac nil))

;;; Keybindings:

;; Use skeleton-pair for parens and friends.

;(setq skeleton-pair t)
;(global-set-key "(" 'skeleton-pair-insert-maybe)
;(global-set-key "[" 'skeleton-pair-insert-maybe)
;(global-set-key "\"" 'skeleton-pair-insert-maybe)

;; This was orignally from the EmacsWiki, but I wanted to be able to use it
;; globally; I basically want the ' key to DTRT whenever I type it so I don't
;; have to think about it.  Since programming modes like Emacs Lisp attach
;; syntactic meaning to apostrophes, I don't want to worry about inserting the
;; wrong character in a programming context.

(defun tyler-maybe-open-apostrophe ()
  "Insert a ` or ' as indicated by context:

1. If using a mode where ` has special meaning, insert a '.
2. If point is at the beginning of the file, insert a `.
3. When the previous character is a `, replace it with a '.
4. When called after a space or a \", or at the beginning of a line, insert a `.
5. Insert a '."
  (interactive)
  (cond ((not (or

               ;; This is a cheap hack to determine if I'm in a string or a
               ;; comment without actually having to do any work.

               (eq (get-text-property (point) 'face) 'font-lock-string-face)
               (eq (get-text-property (point) 'face) 'font-lock-comment-face)
               (memq major-mode '(text-mode fundamental-mode change-log-mode
                                  plain-tex-mode tex-mode texinfo-mode))))
         (insert "'"))
        ((= (point) (point-min))
         (insert "`"))
        ((= (char-before) ?`)
         (delete-char -1)
         (insert "'"))
        ((or (= (char-before) ? )
             (= (char-before) ?\")
             (= (point) (line-beginning-position)))
         (insert "`"))
        (t (insert "'"))))

(global-set-key (kbd "'") 'tyler-maybe-open-apostrophe)

;; Keybindings for `ted-fix-stupid-backspace-key-issue'.

(when tyler-tty-flag
  (global-set-key (kbd "C-c B") 'ted-fix-stupid-backspace-key-issue)

  ;; Since that will nuke C-h, bind help to a different chord.
  (global-set-key (kbd "C-c H") 'help-command))

;; Support functions for `tyler-rotate-buffers'.  From the EmacsWiki.

(defvar tyler-hated-buffers '("KILL" "*Apropos*" "*Completions*" "*grep*"
                              "*Compile-Log*" "*Help*" "*Messages*"))

(setq iswitchb-buffer-ignore (append '("^ " "*Buffer") tyler-hated-buffers))

(defun tyler-delete-from-list (delete-these from-list)
  "Delete DELETE-THESE from FROM-LIST."
  (cond
   ((car delete-these)
    (if (member (car delete-these) from-list)
        (tyler-delete-from-list (cdr delete-these)
                                (delete (car delete-these) from-list))
      (tyler-delete-from-list (cdr delete-these) from-list)))
   (t from-list)))

(defun tyler-hated-buffers ()
  "List of buffers I never want to see."
  (delete nil
          (append
           (mapcar #'get-buffer tyler-hated-buffers)
           (mapcar #'(lambda (this-buffer)
                       (if (string-match "^ " (buffer-name this-buffer))
                           this-buffer))
                   (buffer-list)))))

;; `tyler-rotate-buffers': Like `bury-buffer' but with the capability to
;; exclude certain specified buffers.

(defun tyler-rotate-buffers (&optional n)
  "Switch to the Nth next buffer.  Negative arguments move backwards."
  (interactive)
  (unless n
    (setq n 1))
  (let ((my-buffer-list
         (tyler-delete-from-list (tyler-hated-buffers)
                                 (buffer-list (selected-frame)))))
    (switch-to-buffer
     (if (< n 0)
         (nth (+ (length my-buffer-list) n)
              my-buffer-list)
       (bury-buffer)
       (nth n my-buffer-list)))))

;; Windows-style C-TAB and C-M-TAB to switch buffers.

(global-set-key (kbd "C-<tab>") 'tyler-rotate-buffers)
(global-set-key (kbd "C-M-<tab>") #'(lambda ()
                                      (interactive)
                                      (tyler-rotate-buffers -1)))

;; M-<left> and M-<right> to switch buffers also.  This has the advantage of
;; working in Terminal.app on Mac OS X, and is a neater keystroke too.

(global-set-key (kbd "ESC <left>") #'(lambda ()
                                       (interactive)
                                       (tyler-rotate-buffers -1)))
(global-set-key (kbd "ESC <right>") `tyler-rotate-buffers)

;; This is C-TAB and C-M-TAB for the Linux console.  This requires special
;; setup; namely, you need to load a keymap file with /usr/bin/loadkeys
;; containing the following lines:
;;
;; control keycode 15 = Macro
;; control alt keycode 15 = Pause
;;
;; If you actually -have- a key that generates the Macro or Pause keysyms, you
;; have a better keyboard than I.  For me, this makes Emacs DWIW.  Credit for
;; this hack goes to Alex Schroeder.

(global-set-key (kbd "ESC [ M") 'tyler-rotate-buffers)
(global-set-key (kbd "ESC [ P") #'(lambda ()
                                    (interactive)
                                    (tyler-rotate-buffers -1)))

;; Additional bindings for backward-word and forward-word to work on sketchy
;; terminals (like Terminal.app on Mac OS X).

(global-set-key (kbd "ESC [ 5 D") 'backward-word)
(global-set-key (kbd "ESC [ 5 C") 'forward-word)

;; Damien Elmes wrote this fantastic piece of code to overlay C-x k and bring
;; up a diff when a user tries to close a buffer with unsaved changes.

(setq ediff-custom-diff-options "-u")

(defun diff-buffer-with-associated-file ()
  "View the differences between BUFFER and its associated file.
This requires the external program \"diff\" to be in your `exec-path'."
  (interactive)
  (let ((buf-filename buffer-file-name)
        (buffer (current-buffer)))
    (unless buf-filename
      (error "Buffer %s has no associated file" buffer))
    (let ((diff-buf (get-buffer-create
                     (concat "*Assoc file diff: "
                             (buffer-name)
                             "*"))))
      (with-current-buffer diff-buf
        (setq buffer-read-only nil)
        (erase-buffer))
      (let ((tempfile (make-temp-file "buffer-to-file-diff-")))
        (unwind-protect
            (progn
              (with-current-buffer buffer
                (write-region (point-min) (point-max) tempfile nil 'nomessage))
              (if (zerop
                   (apply #'call-process "diff" nil diff-buf nil
                          (append
                           (when (and (boundp 'ediff-custom-diff-options)
                                      (stringp ediff-custom-diff-options))
                             (list ediff-custom-diff-options))
                           (list buf-filename tempfile))))
                  (message "No differences found")
                (progn
                  (with-current-buffer diff-buf
                    (goto-char (point-min))
                    (if (fboundp 'diff-mode)
                        (diff-mode)
                      (fundamental-mode)))
                  (display-buffer diff-buf))))
          (when (file-exists-p tempfile)
            (delete-file tempfile)))))
    nil))

;; tidy up diffs when closing the file
(defun kill-associated-diff-buf ()
  (let ((buf (get-buffer (concat "*Assoc file diff: "
                                 (buffer-name)
                                 "*"))))
    (when (bufferp buf)
      (kill-buffer buf))))

(add-hook 'kill-buffer-hook 'kill-associated-diff-buf)

(global-set-key (kbd "C-c d") 'diff-buffer-with-associated-file)

(defun de-context-kill (arg)
  "Kill buffer, taking gnuclient into account."
  (interactive "p")
  (when (and (buffer-modified-p)
             buffer-file-name
             (not (string-match "\\*.*\\*" (buffer-name)))
             ;; ERC buffers will be automatically saved.
             (not (eq major-mode 'erc-mode))
             (= 1 arg))
    (when (file-exists-p buffer-file-name)
      (diff-buffer-with-associated-file))
    (error "Buffer has unsaved changes"))
  (if (and (boundp 'gnuserv-minor-mode)
           gnuserv-minor-mode)
      (gnuserv-edit)
    (set-buffer-modified-p nil)
    (kill-buffer (current-buffer))))

(global-set-key (kbd "C-x k") 'de-context-kill)

;; Various function bindings.

(global-set-key (kbd "M-RET") 'eval-last-sexp)
(global-set-key [kp-enter] 'eval-last-sexp)
(global-set-key (kbd "C-c l") 'goto-line)
(global-set-key (kbd "C-c c") 'ted-clear)
(global-set-key (kbd "C-c p") 'list-text-properties-at)
(global-set-key (kbd "C-c t") 'text-mode)
(global-set-key (kbd "C-c C-r") 'redraw-display)
(global-set-key (kbd "C-h A") 'apropos-variable)
(global-set-key (kbd "C-h F") 'find-function)
(global-set-key (kbd "C-c L") 'ted-find-library)
(global-set-key (kbd "C-h V") 'find-variable)
(when (fboundp 'find-file-at-point)
  (global-set-key (kbd "C-c f") 'find-file-at-point))

;; This chord is almost certainly an accident.

(global-set-key (kbd "C-x f") 'find-file)

;; I prefer `buffer-menu' to `list-buffers'.

(global-set-key (kbd "C-x C-b") 'buffer-menu)

;; In addition to C-c chords, F5-F9 are reserved for the user.  Kai Groﬂjohann
;; had the idea to chain the F-keys together, expanding the usefulness of these
;; keys.  This implementation of that concept is Ted O'Connor's, although it's
;; currently sparsely populated.

(defvar tyler-f2-prefix-map (make-sparse-keymap))

(defvar tyler-f5-prefix-map (make-sparse-keymap))
(defvar tyler-f6-prefix-map (make-sparse-keymap))
(defvar tyler-f7-prefix-map (make-sparse-keymap))
(defvar tyler-f8-prefix-map (make-sparse-keymap))
(defvar tyler-f9-prefix-map (make-sparse-keymap))

(global-set-key [f2] tyler-f2-prefix-map)

(global-set-key [f5] tyler-f5-prefix-map)
(global-set-key [f6] tyler-f6-prefix-map)
(global-set-key [f7] tyler-f7-prefix-map)
(global-set-key [f8] tyler-f8-prefix-map)
(global-set-key [f9] tyler-f9-prefix-map)

;; F2 is designated for handling multiple windows.  Technically this is a faux
;; pas, since F2 is bound in GNU Emacs by default.  However, what it binds is a
;; set of ridiculously unuseful commands for two-column editing.  I much prefer
;; having a versatile palette for handling multi-window editing in general.

(define-key tyler-f2-prefix-map [f1] 'split-window-vertically)
(define-key tyler-f2-prefix-map [f2] 'other-window)
(define-key tyler-f2-prefix-map [f3] 'delete-other-windows)
(define-key tyler-f2-prefix-map [f4] #'(lambda ()
                                         (interactive)
                                         (scroll-other-window -10)))
(define-key tyler-f2-prefix-map [f5] #'(lambda ()
                                         (interactive)
                                         (scroll-other-window 10)))
(define-key tyler-f2-prefix-map [f6] 'split-window-horizontally)
(define-key tyler-f2-prefix-map [f7] 'delete-window)

;; Nevertheless, I've duplicated all the old keybindings except F2 F2, which
;; was just a duplicate of F2 2 anyway.

(define-key tyler-f2-prefix-map (kbd "2") '2C-two-columns)
(define-key tyler-f2-prefix-map (kbd "s") '2C-split)
(define-key tyler-f2-prefix-map (kbd "b") '2C-associate-buffer)

;; Martin Cracauer wrote some code which emulates the SELECT key from a
;; Symbolics Lisp machine.  This is Ted's adaptation.
;;
;; FIXME: Tweak.

(defvar tyler-select-prefix-map tyler-f8-prefix-map)
(global-set-key [menu] tyler-select-prefix-map)
(global-set-key [apps] tyler-select-prefix-map)

(defun tyler-display-select-bindings ()
  (interactive)
  (describe-bindings [f8]))

(define-key tyler-select-prefix-map "?" 'tyler-display-select-bindings)

(defmacro ted-define-select-key (fname-base key &optional buf-form else-form)
  "Define a select-key function FNAME-BASE bound on KEY.

If provided, BUF-FORM should be a form which will attempt to return
a buffer to switch to.  If it returns nil, ELSE-FORM is evaluated."
  (let ((fname (intern (concat "tyler-select-" (symbol-name fname-base)))))
    `(progn
       (defun ,fname (arg)
         (interactive "P")
         (let ((buf ,buf-form))
           (if buf
               (switch-to-buffer buf)
             ,else-form)))
       (define-key tyler-select-prefix-map ,key ',fname))))

(put 'ted-define-select-key 'lisp-indent-function 2)

(defmacro ted-define-select-key-class (fname-base key extension &optional default-dir)
  `(ted-define-select-key ,(intern (concat (symbol-name fname-base) "-file")) ,key
     (let ((buffers (buffer-list))
           (buffer t))
       (while (and buffers
                   (listp buffers))
         (setq buffer (car buffers))
         (setq buffers (cdr buffers))
         (if (string-match ,extension (buffer-name buffer))
             (setq buffers nil)
           (setq buffer nil)))
       buffer)
     (find-file
      (read-file-name ,(concat "Find " (symbol-name fname-base) " file: ")
                      ,default-dir))))

;; These are the file types I use at least semi-regularly.

(ted-define-select-key-class C          "c" "\\.c$")
(ted-define-select-key-class Emacs-Lisp "e" "\\.el$"
                               (concat tyler-home-dir "/elisp/"))
(ted-define-select-key-class HTML       "h" "\\.s?html$" "~/www/")
(ted-define-select-key-class Lisp       "l" "\\.\\(lisp\\|lsp\\)$")
(ted-define-select-key-class LaTeX      "t" "\\.tex$")
(ted-define-select-key-class Makefile   "M" "\\(GNU\\)?[Mm]akefile")
(ted-define-select-key-class m4         "4" "\\.m4$")

;; For easy access to a oouple commonly accessed files/buffers.

(ted-define-select-key dotemacs-file "."
  (find-buffer-visiting tyler-dotemacs-file)
  (find-file tyler-dotemacs-file))

(ted-define-select-key home-directory "~"
  (find-buffer-visiting "~")
  (dired "~"))
;; That ~ key is impossible to type...
(define-key tyler-select-prefix-map "`" 'tyler-select-home-directory)

(ted-define-select-key info "i"
  (find-buffer-visiting "*info*")
  (info))

(ted-define-select-key shell "!"
  (find-buffer-visiting "*shell*")
  (shell))

;; Also from Ted: F9 F9 records or executes a previously recorded keyboard
;; macro; F9 F10 clears a previously recorded macro; F9 F11 gives a macro a
;; permanent name.

(defun ted-macro-dwim (arg)
  "DWIM keyboard macro recording and executing."
  (interactive "P")
  (if defining-kbd-macro
      (if arg
          (end-kbd-macro arg)
        (end-kbd-macro))
    (if last-kbd-macro
        (call-last-kbd-macro arg)
      (start-kbd-macro arg))))

(defun ted-macro-clear ()
  "Clear last keyboard macro."
  (interactive)
  (setq last-kbd-macro nil)
  (message "Last keyboard macro cleared."))

(define-key tyler-f9-prefix-map [(f9)] 'ted-macro-dwim)
(define-key tyler-f9-prefix-map [(f10)] 'ted-macro-clear)
(define-key tyler-f9-prefix-map [(f11)] 'name-last-kbd-macro)

;;; Application configuration:

;;; autoconf-mode.el - major mode for configure.in.

(ted-use-mode autoconf-mode "autoconf-mode" "\\.ac\\'\\|configure\\.in\\'")

;;; BBDB - the Insidious Big Brother Database.

(when (ted-require 'bbdb)
  (when (and (boundp 'coding-system-p)
             (coding-system-p 'utf-8))
    (setq bbdb-file-coding-system 'utf-8))

  ;; Ted noticed that certain versions of the BBDB don't autoload this.

  (require 'bbdb-sc)
  (bbdb-initialize 'sendmail 'gnus 'message 'sc)

  (when (locate-library "eshell")
    (defun eshell/bbdb (&optional (regex ".*"))
      (bbdb regex nil)))

  (ted-define-select-key bbdb "b"
    (get-buffer "*BBDB*")
    (bbdb ".*" nil))

  (add-hook 'message-setup-hook 'bbdb-define-all-aliases))

(defconst tyler-bbdb-flag (featurep 'bbdb))

;;; bison-mode.el - editing yacc files in Emacs.

(ted-use-mode bison-mode "bison-mode" "\\.y\\'")

;;; boxquote.el - Dave Pearson's implementation of Kai Groﬂjohann's
;;; "inclusion-style" quoting.

(ted-make-key-bindings "boxquote" (kbd "C-c q")
  (boxquote-region            "r")
  (boxquote-buffer            "b")
  (boxquote-insert-file       "i")
  (boxquote-yank              "y")
  (boxquote-defun             "F")
  (boxquote-paragraph         "p")
  (boxquote-describe-function "f")
  (boxquote-describe-variable "v")
  (boxquote-describe-key      "k")
  (boxquote-kill              "K")
  (boxquote-unbox             "u"))

;;; Calendar customizations.

(add-hook 'initial-calendar-window-hook 'redraw-calendar)
(add-hook 'initial-calendar-window-hook 'ted-hide-trailing-whitespace)

;;; cc-mode customizations.

(setq c-block-comment-prefix " * ")
;       c-comment-prefix-regexp "\\( *+ +\\|//+ +\\)")

;;; cperl-mode.el - a superior Perl major mode.

(ted-use-mode cperl-mode nil "\\.\\([pP][Llm]x?\\|al\\)$"
  (fset 'perl-mode 'cperl-mode)
  (add-hook 'cperl-mode-hook 'turn-off-auto-fill)
  (setq cperl-hairy t))

;;; crontab-mode.el - editing crontabs.

(ted-use-mode crontab-mode "crontab-mode" "/\\(crontab\\|cron\\.\\)")

;;; css-mode.el - editing cascading style sheets.

(ted-use-mode css-mode nil "\\.css\\'"
  (autoload 'cssm-c-style-indenter "css-mode" nil nil)
  (setq cssm-indent-function 'cssm-c-style-indenter))

;;; Diary - the Emacs diary.

(setq diary-file "~/.diary")
(add-hook 'diary-display-hook 'fancy-diary-display)
(add-hook 'list-diary-entries-hook 'sort-diary-entries t)

;;; Dired - a full-featured file manager for Emacs.

;; Copy things correctly between two directories.

(setq dired-dwim-target t)

;; Confirm recursive deletes, but only on the top level.))

(setq dired-recursive-deletes 'top)

;; Advice around `find-file' for Dired - use the current directory instead of the
;; default directory when executing `find-file'.

(defadvice find-file (around dired-x-default-directory activate)
  "Happy advice around `find-file'.\n
In Dired, use dired-x.el's `default-directory' function instead of the
`default-directory' variable.
From Kevin Rodgers <kevin@ihs.com>"
  (interactive
   (let ((default-directory
           (if (and (eq major-mode 'dired-mode)
                    (fboundp 'default-directory))
               (default-directory)
             default-directory)))
     (list (read-file-name "Find file: " nil nil nil nil))))
  ad-do-it)

;;; eldoc - I found this just recently in Ted's .emacs.  This is the coolest
;;; thing ever!  It shows the syntax of the current Emacs Lisp command in the
;;; echo area.

(when (locate-library "eldoc")
  (mapc #'(lambda (mode-hook)
            (add-hook mode-hook 'turn-on-eldoc-mode))
        '(emacs-lisp-mode-hook lisp-interaction-mode-hook ielm-mode-hook))

  (when (fboundp 'propertize)
    (defun ted-frob-eldoc-argument-list (string)
      "Upcase and fontify STRING for use with `eldoc-mode'."
      (let ((upcased (upcase string)))
        (if font-lock-mode
            (propertize upcased
                        'face 'font-lock-variable-name-face)
          upcased)))
    (setq eldoc-argument-case 'ted-frob-eldoc-argument-list)))

;;; ell.el - interface to the Emacs Lisp List

(when (locate-library "ell")
  (setq ell-locate t)
  (setq ell-goto-addr t)
  (autoload 'ell-packages "ell" nil t))

;;; Emacs-w3m - a match made in lisp heaven.

(when (locate-library "w3m")
  (setq w3m-use-toolbar            nil
        w3m-use-tab                nil
        w3m-key-binding            'info
        w3m-search-default-engine  "google"
        w3m-default-save-directory "~"
        w3m-home-page              tyler-home-page
        w3m-mailto-url-function    (symbol-function 'compose-mail))
  (autoload 'w3m "w3m" nil t)
  (autoload 'w3m-region "w3m")
  (add-hook 'w3m-mode-hook 'ted-hide-trailing-whitespace)
  (add-hook 'w3m-mode-hook #'(lambda ()
                               (local-set-key (kbd "C-x f") 'w3m-find-file)))
  (defalias 'eshell/w3m 'w3m)
  (ted-define-select-key w3m "w" (get-buffer "*w3m*") (w3m))

  ;; Ted has misgivings about this, but it suits me just fine.

  (setq browse-url-browser-function 'w3m)

  ;; Gnus should use w3m to render its HTML text.

  (setq mm-text-html-renderer 'w3m))

;; This command allows us to follow links in regions rendered by w3-region or
;; w3m-region, such as in Gnus articles.

(defun tyler-follow-link-at-point (point)
  "Try to follow HTML link at point.
This works for links created by w3-region or w3m-region."
  (interactive "d")
  (let* ((props (text-properties-at-point))
         (w3-h-i (plist-get props 'w3-hyperlink-info))
         (w3m-h-a (plist-get props 'w3m-href-anchor)))
    (cond (w3-h-i
           (browse-url (plist-get w3-h-i :href)))
          (w3m-h-a
           (browse-url w3m-h-a))
          (t
           (error "Couldn't determine link at point.")))))

(add-hook 'gnus-article-mode-hook
          #'(lambda ()
            ;; `a' as in `<a href...'.
            (local-set-key (kbd "C-c a") 'tyler-follow-link-at-point)))

;;; ERC - IRC client for Emacs.

(when (locate-library "erc")
  (autoload 'erc-select "erc" nil t)

  ;; ERC doesn't load .ercrc.el until it logs in to a server, so we need to
  ;; have configuration information here.

  (setq erc-server           "irc.freenode.net"
        erc-port             6667
        erc-nick             '("Gwydion")
        erc-user-full-name   "Tyler Berry"
        erc-email-userid     "tyler"
        etc-pals             '()

        erc-anonymous-login       t
        erc-auto-query            t
        erc-max-buffer-size       30000
        erc-prompt-for-password   nil
        erc-button-wrap-long-urls t
        erc-join-buffer           'buffer)

  (ted-add-cmd-line-arg "--erc"
    (erc-select))

  ;; Enable the ERC command history.

  (eval-after-load 'erc '(require 'erc-ring))
  (eval-after-load 'erc '(require 'erc-stamp))

  (when (featurep 'eshell)
    (defun eshell/irc (&optional server port nick)
      (erc-select (or server erc-server) (or port erc-port) (or nick erc-nick))
      0)
    (defalias 'eshell/erc 'eshell/irc))

  (ted-define-select-key irc "i"
    (get-buffer "#citylights")
    (erc-select)))

;;; Eshell - who needs binaries other than Emacs?

;; Make sure `eshell' is autoloaded.

(when (locate-library "eshell")
  (when (not (fboundp 'eshell))
    (autoload 'eshell "eshell" nil t))

  ;; Always save command history.

  (setq eshell-ask-to-save-history 'always)

  ;; Fix C-a and <home> to be prompt-aware.

  (defun zwax-eshell-maybe-bol ()
    (interactive)
    (let ((p (point)))
      (eshell-bol)
      (if (= p (point))
          (beginning-of-line))))

  (add-hook 'eshell-mode-hook
            #'(lambda () (local-set-key (kbd "C-a") 'zwax-eshell-maybe-bol)))
  (add-hook 'eshell-mode-hook
            #'(lambda () (local-set-key [home] 'zwax-eshell-maybe-bol)))

  ;; Add to the select-key list.

  (ted-define-select-key eshell "s"
    (get-buffer "*eshell*")
    (eshell))

  ;; Set up the same prompt that I use in bash.

  (setq eshell-prompt-function
        #'(lambda ()
            (concat "[" (user-login-name)
                    "@" (car (split-string (system-name) "[.]"))
                    ":" (eshell/pwd) "]"
                    (if (= (user-uid) 0) "# " "$ "))))
  (setq eshell-prompt-regexp "^[^#$\n]*[#$] ")

  ;; Move to the correct place after printing the prompt.

  (add-hook 'eshell-after-prompt-hook 'eshell-bol)

  ;; Provide a sane clear command.

  (defalias 'eshell/clear 'ted-clear)

  ;; Keep info from eating the screen when called.

  (defun eshell/info (&optional subject)
    "Read the Info manual on SUBJECT, or failing that, open the Info directory."
    (let ((buf (current-buffer)))
      (Info-directory)
      (if (not (null subject))
          (let ((node-exists (ted-ignore-errors (Info-menu subject))))
            (if (not node-exists)
                (message "No menu item `%s' in node `(dir)Top'." subject))))))

  ;; Kai Groﬂjohann's version of eshell/less.

  (defun tyler-eshell-view-file (file)
    "A version of `view-file' which properly respects the eshell prompt."
    (interactive "fView file: ")
    (unless (file-exists-p file) (error "%s does not exist" file))
    (let ((had-a-buf (get-file-buffer file))
          (buffer (find-file-noselect file)))
      (if (eq (with-current-buffer buffer (get major-mode 'mode-class))
              'special)
          (progn
            (switch-to-buffer buffer)
            (message "Not using View mode because the major mode is special"))
        (let ((undo-window (list (window-buffer) (window-start)
                                 (+ (window-point)
                                    (length (funcall eshell-prompt-function))))))
          (switch-to-buffer buffer)
          (view-mode-enter (cons (selected-window) (cons nil undo-window))
                           'kill-buffer)))))

  (defun eshell/less (&rest args)
    "Invoke `view-file' on a file.

\"less +42 foo\" will go to line 42 in the buffer for foo."
    (while args
      (if (string-match "\\`\\+\\([0-9]+\\)\\'" (car args))
          (let* ((line (string-to-number (match-string 1 (pop args))))
                 (file (pop args)))
            (tyler-eshell-view-file file)
            (goto-line line))
        (tyler-eshell-view-file (pop args)))))

  (defalias 'eshell/more 'eshell/less)

  ;; Ted's version of eshell/emacs.

  (defun eshell/emacs (&rest args)
    "Open a file in Emacs.  Some habits die hard."
    (if (null args)
        ;; Pretend to do what I asked.
        (switch-to-buffer "*scratch*")

      ;; The flattening is necessary if we try to open a bunch of files in many
      ;; different places in the filesystem.
      (mapc #'find-file (mapcar #'expand-file-name
                                (eshell-flatten-list args)))))
  (defalias 'eshell/emacsclient 'eshell/emacs)
  (defalias 'eshell/gnuclient 'eshell/emacs)

  ;; eshell/vi, based on both Ted's and Kai Groﬂjohann's.

  (defun eshell/vi (&rest args)
    "Open a file in Viper mode."
    (while args
      (if (string-match "\\`\\+\\([0-9]+\\)\\'" (car args))
          (let* ((line (string-to-number (match-string 1 (pop args))))
                 (file (pop args)))
            (with-current-buffer (find-file file)
              (goto-line line)))
        (find-file (pop args)))
      (setq viper-mode t)
      (viper-mode)))
  (defalias 'eshell/vim 'eshell/vi)

  ;; Make Eshell prettier in general.

  (require 'ansi-color)
  (add-hook 'eshell-preoutput-filter-functions
            'ansi-color-filter-apply)

  ;; Make the shell illusion even better by hiding the modeline.

  (let ((tyler-no-mode-line #'(lambda ()
                                (setq mode-line-format nil))))
    (add-hook 'eshell-mode-hook tyler-no-mode-line)
    (add-hook 'sql-interactive-mode-hook tyler-no-mode-line)
    (add-hook 'term-mode-hook tyler-no-mode-line))

  ;; Make sure that mutt and other curses apps stick to ansi-term.

  (add-hook 'eshell-mode-hook
            #'(lambda ()
                (add-to-list 'eshell-visual-commands "mutt")
                (add-to-list 'eshell-visual-commands "links")
                (add-to-list 'eshell-visual-commands "notes"))))

;;; flex-mode.el - editing lex files in Emacs.

(when (locate-library "flex-mode")
  (autoload 'flex-mode "flex-mode" nil t)
  (add-to-list 'auto-mode-alist '("\\.l$" . flex-mode)))

;;; gentoo-ebuild.el - editing Gentoo ebuilds and eclasses.

(when (locate-library "gentoo-ebuild")
  (require 'gentoo-ebuild))

;;; gnuserv and emacsserver - emacs client management

;; gnuserv is cooler than emacsserver, but seems to be broken.

(cond ((and (not (featurep 'multi-tty))
            (locate-library "gnuserv")
            tyler-use-gnuserv-flag)
       (unless (fboundp 'gnuserv-start)
         (if tyler-gnu-emacs-flag
            (require 'gnuserv-compat)
            (require 'gnuserv)))

       (setenv "GNU_SECURE" (expand-file-name ".trusted" tyler-home-dir))

       (gnuserv-start)
       (add-hook 'after-init-hook
                 (lambda () (setq gnuserv-frame (selected-frame)))))
      (t
        (setq server-temp-file-regexp "^/tmp/\\(Re\\|draft\\|mutt\\).*$")
        (setq display-buffer-reuse-frames t)
        (when (or (fboundp 'make-network-process)
                  (file-executable-p (expand-file-name "emacsserver" exec-directory)))
          (server-start))))

(when tyler-gnu-emacs-flag
  (setq file-name-handler-alist '(("\\`/:" . file-name-non-special))))

(when (featurep 'multi-tty)
  (defun ted-delete-frame-or-kill-emacs ()
    (interactive)
    (if (> (length (frame-list)) 1)
        (delete-frame)
      (save-buffers-kill-emacs)))
  (global-set-key (kbd "C-x C-c") 'ted-delete-frame-or-kill-emacs))

;;; google.el - Ted O'Connor's Emacs interface to Google.

(when (ted-require 'google)

  ;; My Google license key.  You should get your own.

  (setq google-license-key "TbqhpPFQFHLz5rdq9vDnjmdgiMFm7sL2")

  (defun tyler-google-word-at-point ()
    "Google the word at point."
    (interactive)
    (google-search (word-at-point)))

  (defun tyler-google-sentence-at-point ()
    "Google the text of the sentence at point."
    (interactive)
    (google-search (sentence-at-point)))

  ;; Requires `lj--get-music' from ljupdate.
  ;(defun tyler-google-current-song ()
  ;  "Google the currently playing track."
  ;  (interactive)
  ;  (google-search (lj--get-music)))

  (defvar tyler-google-prefix-map (make-sparse-keymap)
    "Keymap for my tyler-google* commands.")

  (global-set-key (kbd "C-c g") tyler-google-prefix-map)
  (define-key tyler-google-prefix-map "g" 'google-search)
  (define-key tyler-google-prefix-map (kbd "RET") 'google-search)
  ;(define-key tyler-google-prefix-map "m" 'tyler-google-current-song)
  (define-key tyler-google-prefix-map "r" 'google-search-region)
  (define-key tyler-google-prefix-map "s" 'tyler-google-sentence-at-point)
  (define-key tyler-google-prefix-map "w" 'tyler-google-word-at-point))

;;; HTML character entity insertion

;; This code lets you type those weird HTML character entities easily in
;; html-mode or php-mode; type the character twice, as in &&, to get the
;; corresponding entity (once)

(defun tyler-maybe-insert-char-entity (char entity)
  (if (equal (preceding-char) char)
      (progn
        (backward-delete-char 1)
        (insert entity))
    (insert char)))

(mapc
 #'(lambda (mode-hook)
     (add-hook mode-hook
               #'(lambda ()
                   (local-set-key (kbd "<")
                                  #'(lambda () (interactive)
                                      (tyler-maybe-insert-char-entity ?< "&lt;")))
                   (local-set-key (kbd ">")
                                  #'(lambda () (interactive)
                                      (tyler-maybe-insert-char-entity ?> "&gt;")))
                   (local-set-key (kbd "&")
                                  #'(lambda () (interactive)
                                      (tyler-maybe-insert-char-entity ?& "&amp;")))
                   (local-set-key (kbd "\"")
                                  #'(lambda () (interactive)
                                      (tyler-maybe-insert-char-entity ?\" "&quot;")))
                   (local-set-key (kbd "'")
                                  #'(lambda () (interactive)
                                      (tyler-maybe-insert-char-entity ?\' "&apos;")))
                   (local-set-key (kbd "-")
                                  #'(lambda () (interactive)
                                      (tyler-maybe-insert-char-entity ?\- "&#151;"))))))
 '(html-mode-hook php-mode-hook))

;;; Miscellaneous Lisp customizations.

(add-to-list 'auto-mode-alist '("\\.asd\\'" . lisp-mode))

(add-hook 'lisp-mode-hook #'(lambda ()
                              (set (make-local-variable lisp-indent-function)
                                   'common-lisp-indent-function)))

(setq inferior-lisp-program (concat "sbcl --userinit "
                                    (expand-file-name ".sbcl-profile" tyler-home-dir)))

;; Transform the word `lambda' in Lisp source code into the greek lambda using
;; font-lock.

(mapc #'(lambda (mode-hook)
          (add-hook mode-hook
                    #'(lambda ()
                        (font-lock-add-keywords
                            nil `(("(\\(lambda\\>\\)"
                                   (0 (progn (compose-region (match-beginning 1) (match-end 1)
                                                             ,(make-char 'greek-iso8859-7 107))
                                             nil))))))))
      '(emacs-lisp-mode-hook lisp-mode-hook scheme-mode-hook))

;;; Malyon - z-code interpreter for Emacs.

(when (locate-library "malyon")
  (autoload 'malyon "malyon" nil t)
  (add-hook 'malyon-mode-hook 'ted-hide-trailing-whitespace))

;;; mushcode-mode - editing Mushcode. (Ick.)

(when (locate-library "mushcode")
  (autoload 'mushcode-mode "mushcode" nil t)
  (add-to-list 'auto-mode-alist '("\\.mush$" . mushcode-mode)))

;;; Paren shading for lisp modes.

(when (not tyler-tty-flag)
  (if (ted-require 'cparen)
      (cparen-activate)
    (ted-require 'parenface)))

;;; php-mode.el - editing PHP code in Emacs.

(ted-use-mode php-mode "php-mode" "\\.php[345]?\\'")

;;; po-mode - Editing translation files.

(ted-use-mode po-mode "po-mode" "\\.po\\'\\|\\.po\\.")

;;; python-mode.el - editing Python code in Emacs.

(ted-use-mode python-mode "python-mode" "\\.py\\'"
  (add-to-list 'interpreter-mode-alist '("python" . python-mode)))

;;; quack.el - Superior Scheme mode.

(when (locate-library "quack")
  (require 'quack))

;;; rfcview.el - make RFCs look pretty.

(when (locate-library "rfcview")
  (autoload 'rfcview-mode "rfcview" nil t)
  (add-to-list 'auto-mode-alist
               '("/rfc[0-9]+\\.txt$" . rfcview-mode)))

;;; SLIME - the Superior Lisp Interaction Mode for Emacs.

(when (ted-require 'slime)
  (if (fboundp 'slime-setup)
      (slime-setup))
  (add-hook 'lisp-mode-hook #'(lambda ()
                                (slime-mode 1)))
  (add-hook 'inferior-lisp-mode-hook #'(lambda () (inferior-slime-mode 1)))
  (add-hook 'slime-mode-hook #'(lambda () (slime-autodoc-mode 1))))

;;; Text mode customizations.

(define-key text-mode-map [(tab)] 'tab-to-tab-stop)

;;; Tramp customizations.

(when (locate-library "tramp")
  (require 'tramp)
  (setq tramp-default-method "ssh"))

;;; Viper - "emulating the editor of the beast".

;; Don't start in viper-mode.

(setq viper-mode nil)

;; Keybindings for viper - C-c v toggles, C-c V unconditionally deactivates.

(global-set-key (kbd "C-c v")
                (if (fboundp 'toggle-viper-mode)
                    'toggle-viper-mode
                  'viper-mode))
(global-set-key (kbd "C-c V") 'viper-go-away)

(ted-add-cmd-line-arg "--vi" (let ((viper-mode t)) (require 'viper)))

;;; Wikipedia - the free encyclopedia.

;; The Wikipedia bindings are based around a general Web fetching function,
;; `ted-web-get'.  Also bound in this section is `tyler-web-home'.  All the
;; actual Wikipedia functions are just variants on this call.

(autoload 'sentence-at-point "thingatpt" nil nil)

(when (and (fboundp 'lj--url-escape)
           (fboundp 'browse-url))

  (defun ted-web-get (prefix &optional (something "") (suffix ""))
    (interactive "sURL: \ni\ni")
    (browse-url (concat prefix
                        (lj--url-escape something)
                        suffix)))

  (global-set-key (kbd "C-c u") 'ted-web-get)

  (defun tyler-web-home ()
    "Load my home page."
    (interactive)
    (ted-web-get tyler-home-page))

  (global-set-key (kbd "C-c h") 'tyler-web-home)

    (defun ted-wikipedia-search (something)
    "Search for SOMETHING up at Wikipedia."
    (interactive "sWikipedia search: ")
    (ted-web-get "http://www.wikipedia.com/wiki.phtml?search="
                 something))

  (defun ted-wikipedia-article (article-name)
    "Fetch the Wikipedia article ARTICLE-NAME."
    (interactive "sWikipedia article: ")
    (ted-web-get "http://www.wikipedia.com/wiki.phtml?title="
                 article-name))

  (autoload 'word-at-point "thingatpt" nil nil)

  (defun ted-wikipedia-word-at-point ()
    "Fetch the Wikipedia article named by the word at point."
    (interactive)
    (tyler-wikipedia-article (word-at-point)))

  (defun ted-wikipedia-region (start end)
    "Search Wikipedia for the text from START to END."
    (interactive "r")
    (ted-wikipedia-search (buffer-substring-no-properties start
                                                          end)))

  (defun ted-wikipedia-sentence-at-point ()
    "Search Wikipedia for the text of the sentence at point."
    (interactive)
    (ted-wikipedia-search (sentence-at-point)))

  (defvar tyler-wikipedia-prefix-map (make-sparse-keymap)
    "Keymap for my tyler-wikipedia* commands.")

  (global-set-key (kbd "C-c w") tyler-wikipedia-prefix-map)

  (define-key tyler-wikipedia-prefix-map "a" 'ted-wikipedia-article)
  (define-key tyler-wikipedia-prefix-map "s"
    'ted-wikipedia-sentence-at-point)
  (define-key tyler-wikipedia-prefix-map (kbd "RET")
    'ted-wikipedia-search)
  (define-key tyler-wikipedia-prefix-map "r" 'ted-wikipedia-region)
  (define-key tyler-wikipedia-prefix-map "w"
    'ted-wikipedia-word-at-point))

;;; GUI Emacs setup:

;; Support for the Macintosh.

(when tyler-mac-window-system-flag
  ;(when (fboundp 'new-fontset)
  ;  (create-fontset-from-fontset-spec
  ;   "-*-fixed-medium-r-normal-*-16-*-*-*-*-*-fontset-mac,
  ;    thai-tis620:-ETL-Fixed-*-*-*-*-16-*-*-*-*-*-tis620.2529-1,
  ;    lao:-Misc-Fixed-*-*-*-*-16-*-*-*-*-*-MuleLao-1,
  ;    vietnamese-viscii-lower:-ETL-Fixed-*-*-*-*-16-*-*-*-*-*-viscii1.1-1,
  ;   vietnamese-viscii-upper:-ETL-Fixed-*-*-*-*-16-*-*-*-*-*-viscii1.1-1,
  ;   chinese-big5-1:-*-Nice Taipei Mono-*-*-*-*-12-*-*-*-*-*-big5,
  ;   chinese-big5-2:-*-Nice Taipei Mono-*-*-*-*-12-*-*-*-*-*-big5,
  ;   chinese-gb2312:-*-Beijing-*-*-*-*-16-*-*-*-*-*-gb2312,
  ;   japanese-jisx0208:-*-\x8d\xd7\x96\xbe\x92\xa9\x91\xcc-*-*-*-*-16-*-*-*-*-*-jisx0208-sjis,
  ;   katakana-jisx0201:-*-*-*-*-*-*-16-*-*-*-*-*-JISX0201.1976-0,
  ;   korean-ksc5601:-*-Seoul-*-*-*-*-16-*-*-*-*-*-ksc5601"))
  ;(setq mac-command-key-is-meta t)
  (when (fboundp 'browse-url-default-macosx-browser)
    (setq browse-url-browser-function #'browse-url-default-macosx-browser)))

;; Set up default frame configuration.

(setq default-frame-alist
      '((background-mode . dark) (top . 24) (left . 0)))

;; Select a font to use.

(when tyler-display-graphic-flag
  (defconst tyler-emacs-font
    (cond
     ((and tyler-gnu-emacs-19-flag tyler-w32-flag)
      "-*-Lucida Console-normal-r-*-*-19-142-*-*-c-*-*-ansi-")
     (tyler-w32-flag
      "-*-Lucida Console-normal-r-*-U-18-*-*-*-c-*-iso8559-1")
     (tyler-mac-flag "fontset-mac")
     ((and (fboundp `display-pixel-width)
           (< (display-pixel-width) 1024))
      "-adobe-courier-medium-r-*-*-10-*-*-*-*-*-*-*")
     (t "-adobe-courier-medium-r-*-*-12-*-*-*-*-*-*-*"))
    "The font that Emacs should use."))

(when tyler-display-graphic-flag
  (add-to-list 'default-frame-alist
               (cons 'font tyler-emacs-font)))

;; Set default frame size.

(when (and tyler-display-graphic-flag

           ;; Feature from 21.3

           (not (member "--fullscreen" command-line-args)))
  (add-to-list 'default-frame-alist '(width . 128))
  (add-to-list 'default-frame-alist
               (cons 'height
                     (cond
                      ((and tyler-gnu-emacs-19-flag tyler-w32-flag) 35)
                      (tyler-w32-flag 49)
                      (t 51)))))

;; Set default colors.

(when tyler-use-colors-flag
  (mapc #'(lambda (pair)
            (when pair
              (add-to-list 'default-frame-alist pair)))
        (list
         '(border-color . "black")
         '(mouse-color . "cornflower blue")
         '(cursor-color . "light slate blue")
         '(background-color . "black")
         '(foreground-color . "light blue"))))

;; Set up menu size and finish initial setup.

(when (not tyler-xemacs-flag)
  (add-to-list 'default-frame-alist
               '(wait-for-wm . nil))
  (add-to-list 'default-frame-alist
               (cons 'menu-bar-lines tyler-menu-bar-lines)))

(setq initial-frame-alist default-frame-alist)

;; Set up appearances for the frame.

(when tyler-display-graphic-flag
  (setq frame-title-format
        (concat "%b - " tyler-pretty-emacs-name))

  ;; Cursor type.

  (setq-default cursor-type 'block)

  ;; Turn off scrollbars.

  (cond (tyler-xemacs-flag
         (setq scrollbars-visible-p nil)
         (set-specifier horizontal-scrollbar-visible-p nil)
         (set-specifier vertical-scrollbar-visible-p nil))
        (t (when (fboundp 'scroll-bar-mode)
             (scroll-bar-mode -1))))

  ;; Fix scrollbars in new frames in NTEmacs.

  (when (and tyler-w32-window-system-flag
             tyler-gnu-emacs-21+-flag)
    (add-hook 'after-make-frame-functions
              #'(lambda (frame)
                  (scroll-bar-mode -1)))))

;; Turn off toolbars in XEmacs and GNU Emacs 21.

(when tyler-display-graphic-flag
  (cond (tyler-xemacs-flag
         (setq toolbar-visible-p nil)
         (set-specifier default-toolbar-visible-p nil))
        ((and tyler-gnu-emacs-flag tyler-gnu-emacs-21+-flag)
         (tool-bar-mode -1)
         (add-to-list 'default-frame-alist
                      '(tool-bar-lines . 0)))))

;; Remove the default gutter in XEmacs.

(when tyler-xemacs-flag
  (when (boundp 'default-gutter-visible-p)
    (set-specifier default-gutter-visible-p nil))

  ;; And make the progress bar go away.

  (setq progress-feedback-use-echo-area t))

;; Customizations for Emacs 19.

(when (and tyler-display-graphic-flag tyler-gnu-emacs-19-flag)
  (set-background-color "black")
  (set-foreground-color "#c0c0c0")
  (set-cursor-color "blue")
  (setq font-lock-support-mode '((t . lazy-lock-mode)))
  (setq font-lock-maximum-decoration t))

;; Something like vi's ~ characters...

(setq default-indicate-empty-lines t)

;; ...but not in every mode.

(let ((hook #'(lambda ()
                (setq indicate-empty-lines nil)))
      (mode-hooks (list 'shell-mode-hook
                        'term-mode-hook
                        'gnus-article-mode-hook
                        'gnus-summary-mode-hook
                        'gnus-group-mode-hook
                        'erc-mode-hook
                        'eshell-mode-hook)))
  (mapc #'(lambda (mode-hook)
            (add-hook mode-hook hook))
        mode-hooks))

;; Handle ANSI color sequences correctly.

(autoload 'ansi-color-for-comint-mode-on "ansi-color" nil t)
(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)

;; Be able to open images.

(when (and (fboundp 'display-images-p)
           (display-images-p)
           (fboundp 'auto-image-file-mode))
  (auto-image-file-mode 1))

;; Configure Tooltips in Emacs 21.

(when (featurep 'tooltip)
  (setq tooltip-gud-tips-p t))

;; Font-locking
;;
;; Wisdom from Eli Zaretskii (via Ted O'Connor's .emacs via Jean-Phillipe
;; Theberge's .emacs):
;;
;; "I think it is generally a bad idea to load font-lock directly from .emacs,
;; especially if you do that before setting `default-frame-alist'.  It is
;; better to do it from a major-mode-specific hook.  If you want to turn on
;; `global-font-lock-mode', do it from a function that is on the
;; `after-init-hook' list.  Emacs calls `after-init-hook' after it reads
;; .emacs, so when font-lock is loaded, `default-frame-alist' is already set."

(when tyler-use-colors-flag
  (cond
   (tyler-gnu-emacs-19-flag
    (setq hilit-mode-enable-list  '(not text-mode)
          hilit-background-mode   'dark
          hilit-inhibit-hooks     nil
          hilit-inhibit-rebinding nil)
    (add-hook 'after-init-hook
              #'(lambda () (require 'hilit19))))
   (tyler-gnu-emacs-flag
    (cond ((fboundp 'jit-lock-mode)
            (add-hook 'after-init-hook
                      #'(lambda () (jit-lock-mode 1))))
          ((fboundp 'toggle-global-lazy-font-lock-mode)
            (add-hook 'after-init-hook
                      #'(lambda () (toggle-global-lazy-font-lock-mode))))
          ((fboundp 'global-font-lock-mode)
            (add-hook 'after-init-hook
                      #'(lambda () (global-font-lock-mode 1))))))

   ;; Make XEmacs highlight lisp interaction mode.

   (tyler-xemacs-flag
    (add-hook 'after-init-hook #'(lambda () (turn-on-font-lock)))))

  ;; Font lock additions.

  (put 'font-lock-add-keywords 'lisp-indent-function 1)

  (when (fboundp 'font-lock-add-keywords)

    ;; C mode font lock additions/

    (font-lock-add-keywords 'c-mode
      '(("\\<\\(FIXME\\):" 1 font-lock-warning-face t)
        ("\\<\\(and\\|or\\|not\\)\\>" . font-lock-keyword-face)))))

;; colortheme.el from Alex Schroeder, for Emacs beautification.

(when (ted-require 'color-theme)
  (add-hook 'after-init-hook
            (ted-find-if #'fboundp '(color-theme-hober)
                         #'ignore)))

;; Ted provides mouse wheel support here.

;; Ted has Win32-specific config here.

;; X-specific configuration.

(when tyler-x-window-system-flag
  (setq focus-follows-mouse t))

;;; Provide for using multiple Emacsen and boxen:

;; Prepare the customization system for this Emacs

(when (featurep 'custom)
  (setq custom-file
        (concat tyler-elisp-dir tyler-emacs-name "-custom.el"))

  ;; Load it, if it's there.

  (load custom-file t))

;; Load late site-specific customizations.

(load "~/.emacs-local-post" t)

;;; .emacs ends here
