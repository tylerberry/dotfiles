;;; .viper --- Tyler Berry's Viper configuration file        -*- Emacs-Lisp -*-

;; Copyright (C) 2005 Tyler Berry
;; Author: Tyler Berry <loki@arete.cc>
;; Keywords: local
;; Time-stamp: <2005-11-19 14:58:24 loki>

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

;;; Code:

(put 'viper-add-local-keys 'lisp-indent-function 1)

(setq viper-inhibit-startup-message   t
      viper-expert-level              5
      viper-electric-mode             t
      viper-always                    t
      viper-with-ctl-h-help           t
      viper-want-emacs-keys-in-insert t
      viper-want-emacs-keys-in-vi     t
      viper-vi-style-in-minibuffer    nil
      viper-no-multiple-ESC           nil
      viper-keep-point-on-repeat      nil
      viper-keep-point-on-undo        t
      viper-case-fold-search          t)

(setq-default viper-ex-style-editing nil
              viper-ex-style-motion  nil
              viper-auto-indent      t)

(when (fboundp 'viper-buffer-search-enable)
  (viper-buffer-search-enable))

(when (featurep 'iswitchb)
  (setq viper-read-buffer-function 'iswitchb-read-buffer))

(let ((open-entry (assoc "open" ex-token-alist)))
  (when (consp open-entry)
    (setcdr open-entry
            '((find-file (read-file-name "Find file: "))))))

(when (boundp 'viper-insert-state-mode-list)
  (setq viper-insert-state-mode-list
        (delete 'sql-interactive-mode
                (delete 'eshell-mode
                        (delete 'inferior-lisp-mode
                                viper-insert-state-mode-list)))))

(when (boundp 'viper-emacs-state-mode-list)
  (mapc #'(lambda (mode)
            (add-to-list 'viper-emacs-state-mode-list mode))
        '(cfengine-mode sql-interactive-mode eshell-mode
          inferior-lisp-mode inferior-python-mode)))

(when (boundp 'viper-insert-global-user-map)
  (define-key viper-insert-global-user-map (kbd "C-d") 'delete-char)
  (define-key viper-insert-global-user-map (kbd "C-v") 'scroll-up)
  (define-key viper-insert-global-user-map (kbd "C-\\") 'toggle-input-method)
  (define-key viper-insert-global-user-map (kbd "C-t") 'transpose-chars)
  (define-key viper-insert-global-user-map (kbd "C-w") 'kill-region))

(when (boundp 'viper-vi-global-user-map)
  (define-key viper-vi-global-user-map (kbd "C-u") 'universal-argument)

  ;; This is shockingly cool.
  (define-key viper-vi-global-user-map (kbd "q") 'fill-paragraph)

  (define-key viper-vi-global-user-map (kbd "C-v") 'scroll-up)

  (define-key viper-vi-global-user-map (kbd "C-b") 'backward-char)
  (define-key viper-vi-global-user-map (kbd "C-f") 'forward-char)
  (define-key viper-vi-global-user-map (kbd "C-p") 'previous-line)
  (define-key viper-vi-global-user-map (kbd "C-n") 'next-line)

  ;; Being able to pull up help is a good thing.
  (define-key viper-vi-global-user-map (kbd "C-h") 'help-command)

  ;; I don't know what C-e or C-t do in vi by default and I don't care.
  (define-key viper-vi-global-user-map (kbd "C-e") 'viper-goto-eol)
  (define-key viper-vi-global-user-map (kbd "C-t") 'transpose-chars)

  ;; I don't need an alternate Meta key, thank you very much.
  (define-key viper-vi-global-user-map (kbd "C-\\") 'toggle-input-method)

  (define-key viper-vi-global-user-map (kbd "C-y") 'yank))

;; These keybindings make viper more like vim and less like vi.
(when (boundp 'viper-vi-global-user-map)
  (define-key viper-vi-global-user-map (kbd "gg")
    #'(lambda ()
        (interactive)
        (goto-char (point-min))
        (recenter 0))))

(defun ted-viper-install-z-bindings ()
  (let ((zz-binding (key-binding (kbd "C-c C-c")))
        (zs-binding (key-binding (kbd "C-c C-s"))))
    ;; Ensure we have a local map to frob if need be
    (when (or zz-binding zs-binding)
      (unless (current-local-map)
        (use-local-map (make-sparse-keymap "Local map"))))
    (when zz-binding
      (viper-add-local-keys 'vi-state
        (list (cons "zz" zz-binding))))
    (when zs-binding
      (viper-add-local-keys 'vi-state
        (list (cons "zs" zs-binding))))))

(add-hook 'after-change-major-mode-hook 'ted-viper-install-z-bindings)

(defun ted-disable-viper-auto-indent ()
  (when viper-mode
    (setq viper-auto-indent nil)))

(mapc #'(lambda (hook)
          (add-hook hook 'ted-disable-viper-auto-indent))
      '(eshell-mode-hook nslookup-mode-hook wikipedia-mode-hook
        css-mode-hook))

;;; .viper ends here

