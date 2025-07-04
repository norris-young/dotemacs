;;; ...  -*- lexical-binding: t -*-

(use-package yasnippet
  :custom (yas-prompt-functions '(yas-no-prompt))
  :hook (after-init . yas-global-mode)
  :config
  (define-key yas-minor-mode-map [(tab)] nil)
  (define-key yas-minor-mode-map (kbd "TAB") nil)
  (define-key yas-minor-mode-map (kbd "C-<tab>") yas-maybe-expand))

(use-package xref
  :autoload
  xref-backend-identifier-at-point
  xref--find-xrefs)

(use-package better-jumper
  :bind (:map my-function-map
         ("f" . better-jumper-jump-forward)
         ("b" . better-jumper-jump-backward))
  :custom
  (better-jumper-add-jump-behavior 'replace)
  :hook (after-init . better-jumper-mode)
  :config
  ;; (add-hook 'post-command-hook #'my-post-command-set-jumper)

  (with-eval-after-load 'meow
    (advice-add #'meow-beginning-of-thing :before #'my-set-jump)
    (advice-add #'meow-end-of-thing :before #'my-set-jump))
  (with-eval-after-load 'consult
    (advice-add #'consult-jump-in-buffer :before #'my-set-jump)
    (advice-add #'consult-isearch :before #'my-set-jump))
  (with-eval-after-load 'lsp-bridge
    (advice-add #'my-find-def :before #'my-set-jump)
    (advice-add #'my-find-ref :before #'my-set-jump))
  (with-eval-after-load 'citre
    (advice-add #'citre-jump :before #'my-set-jump)
    (advice-add #'citre-jump-to-reference :before #'my-set-jump))

  ;; 2. jump to another buffer
  (advice-add #'set-window-buffer :before #'my-set-jump)
  )

(use-package lsp-bridge
  :bind (:map my-function-map
         ("d" . my-find-def)
         ("r" . my-find-ref)
         :map lsp-bridge-ref-mode-map
         ("d" . lsp-bridge-ref-open-file))
  :hook
  (after-init . global-lsp-bridge-mode)
  (lsp-bridge-mode . lsp-bridge-semantic-tokens-mode)
  :custom
  (acm-enable-tabnine nil)
  (acm-enable-citre nil)
  (lsp-bridge-ref-delete-other-windows nil)
  (lsp-bridge-ref-open-file-in-request-window t)
  (lsp-bridge-ref-kill-temp-buffer-p nil)
  (lsp-bridge-find-def-fallback-function #'my-after-lsp-find-def-failure)
  (lsp-bridge-find-ref-fallback-function #'my-after-lsp-find-ref-failure)
  (lsp-bridge-user-langserver-dir "~/.emacs.d/lsp.server.conf")
  (lsp-bridge-python-command "~/.emacs.d/lsp.bridge.pyenv/bin/python")
  (lsp-bridge-remote-start-automatically t)
  (lsp-bridge-remote-heartbeat-interval 600)
  (lsp-bridge-enable-inlay-hint t)
  (lsp-bridge-enable-hover-diagnostic t)
  (lsp-bridge-semantic-tokens-delay 0.1)
  :config
  (setq-default lsp-bridge-semantic-tokens-type-faces
                [("comment" . lsp-bridge-semantic-tokens-comment-face)])
  (if (eq system-type 'windows-nt)
      (setq lsp-bridge-python-lsp-server 'pyright)
    (setq lsp-bridge-python-lsp-server 'basedpyright))
  (add-to-list 'lsp-bridge-default-mode-hooks 'rust-ts-mode-hook)
  (cl-delete 'org-mode-hook lsp-bridge-default-mode-hooks)
  (advice-add #'lsp-bridge-mode :before #'lsp-dir)
  (mapc (lambda (pair)
          (if (eq (cdr pair) 'lsp-bridge-c-lsp-server)
              (setcar pair '(c-mode c++-mode c-or-c++-mode c-ts-mode c++-ts-mode c-or-c++-ts-mode objc-mode))))
        lsp-bridge-single-lang-server-mode-list)
  )

(provide 'init-lsp)
