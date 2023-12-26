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
  :bind (("M--" . sp-unwrap-sexp)
         ("M-[" . sp-backward-slurp-sexp)
         ("M-]" . sp-forward-slurp-sexp)
         ("M-{" . sp-backward-barf-sexp)
         ("M-}" . sp-forward-barf-sexp))
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
               (cl-return)))))))

(use-package autorevert
  :hook (after-init . global-auto-revert-mode))

(use-package dts-mode
  :hook (dts-mode . indent-tabs-mode))

(use-package files
  :custom
  (require-final-newline nil)
  (mode-require-final-newline nil))

(use-package markdown-mode
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "multimarkdown")
  :bind (:map markdown-mode-map
         ("C-c C-e" . markdown-do)))

(provide 'init-misc)
