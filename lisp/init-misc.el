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
  (eval-after-load 'c-ts-mode '(require 'smartparens-c))
  (eval-after-load 'c++-ts-mode '(require 'smartparens-c))

  (defun my-wrap-with-pair (c)
    (interactive "c")
    (let ((active-pair (char-to-string c)))
      (cl-dolist (pair sp-pair-list)
        (if (or (equal (car pair) active-pair)
                (equal (cdr pair) active-pair))
            (progn
              (sp-wrap-with-pair (car pair))
              (cl-return))))))
  )

(use-package autorevert
  :hook (after-init . global-auto-revert-mode))

(use-package dts-mode
  :hook (dts-mode . indent-tabs-mode))

(use-package files
  :custom
  (require-final-newline nil))

(use-package auto-sudoedit
  :hook (after-init . auto-sudoedit-mode))

(use-package markdown-mode
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "multimarkdown")
  :bind (:map
         markdown-mode-map
         ("C-c C-e" . markdown-do))
  :config
  (add-hook 'markdown-mode-hook #'conditionally-turn-on-pandoc))

(use-package tramp
  :load-path "packages/tramp/lisp"
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
  (defun move-to-gud-after-first-memory-udpate ()
    (winum-select-window-7)
    (advice-remove #'gdb-read-memory-handler
                   #'move-to-gud-after-first-memory-udpate))

  (advice-add #'gdb-setup-windows :before
              (lambda () (advice-add #'gdb-read-memory-handler :after
                                     #'move-to-gud-after-first-memory-udpate)))
  )

(use-package project
  :config
  (eval-when-compile (require 'lsp-bridge))
  (with-eval-after-load 'lsp-bridge
    (add-to-list 'project-ignore-buffer-conditions #'is-lsp-bridge-process-buffer)
    (advice-add 'project--buffers-to-kill :filter-return
                (lambda (bufs) (cl-remove-if #'is-lsp-bridge-process-buffer bufs)))))

(setq-default bidi-display-reordering nil)
(setq bidi-inhibit-bpa t
      long-line-threshold 2000
      large-hscroll-threshold 1000
      syntax-wholeline-max 1000)

(provide 'init-misc)
