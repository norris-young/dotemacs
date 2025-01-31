;;; ...  -*- lexical-binding: t -*-

;; Save file place by default
(use-package saveplace
  :hook (after-init . save-place-mode))

(use-package simple
  :bind ("C-M-j" . join-line)
  :hook ((before-save . delete-trailing-whitespace))
  :init
  (setq-default indent-tabs-mode nil)
  (setq column-number-mode t)
  )

(use-package smartparens
  :custom (sp-c-modes '(c-mode c++-mode c-ts-mode c++-ts-mode))
  :hook (after-init . smartparens-global-mode)
  :config
  (require 'smartparens-config)
  (with-eval-after-load 'c-ts-mode
    (require 'smartparens-c))
  (with-eval-after-load 'c++-ts-mode
    (require 'smartparens-c))
  )

(use-package autorevert
  :bind ("C-r" . revert-buffer)
  :hook (after-init . global-auto-revert-mode))

(use-package dts-mode
  :hook (dts-mode . indent-tabs-mode))

(use-package files
  :config
  (advice-add #'find-file :around #'my-find-file-in-same-window))

(use-package auto-sudoedit
  :hook (after-init . (lambda() (if (not (eq system-type 'windows-nt))
                                    (auto-sudoedit-mode)))))

(use-package markdown-mode
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "multimarkdown")
  :bind (:map
         markdown-mode-map
         ("C-c C-e" . markdown-do))
  :config
  (add-hook 'markdown-mode-hook #'conditionally-turn-on-pandoc))

(use-package tramp
  :custom
  (tramp-inline-compress-start-size 1048576)
  :config
  (add-to-list 'tramp-connection-properties
               (list nil "remote-shell" "/usr/bin/bash"))
  )

(use-package conf-mode
  :mode ("\\.\\(fio\\|bb\\|bbappend\\)\\'" . conf-mode))

(use-package gdb-mi
  :custom (gdb-default-window-configuration-file "gdb-window-config.el")
  :config


  (advice-add #'gdb-setup-windows :before
              (lambda () (advice-add #'gdb-read-memory-handler :after
                                     #'move-to-gud-after-first-memory-udpate)))
  )

(use-package project
  :bind (("M-r" . revert-project-buffer)
         :map
         project-prefix-map
         ("k" . project-kill-other-buffers)
         ("K" . project-kill-buffers)
         )
  :config
  (with-eval-after-load 'lsp-bridge
    (add-to-list 'project-ignore-buffer-conditions #'is-lsp-bridge-process-buffer)
    (advice-add 'project--buffers-to-kill :filter-return
                (lambda (bufs) (cl-remove-if #'is-lsp-bridge-process-buffer bufs)))))

(use-package keyfreq
  :hook
  (after-init . keyfreq-mode)
  (after-init . keyfreq-autosave-mode)
  :config
  (setq keyfreq-excluded-commands '(self-insert-command
                                    acm-complete
                                    meow-keypad-self-insert
                                    meow-keypad
                                    meow-prev
                                    meow-next
                                    meow-left
                                    meow-right
                                    forward-char
                                    backward-char
                                    previous-line
                                    next-line)))

(setq-default bidi-display-reordering nil)
(setq bidi-inhibit-bpa t
      long-line-threshold 2000
      large-hscroll-threshold 1000
      syntax-wholeline-max 1000)

(provide 'init-misc)
