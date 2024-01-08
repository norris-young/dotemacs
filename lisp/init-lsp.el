(use-package yasnippet
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
  :bind (:map
         my-function-map
         ("f" . better-jumper-jump-forward)
         ("b" . better-jumper-jump-backward))
  :custom
  (better-jumper-add-jump-behavior 'replace)
  :hook (after-init . better-jumper-mode)
  :config
  (advice-add #'switch-to-buffer :before
              (lambda (&rest r)
                (better-jumper-set-jump)))
  (advice-add #'counsel-jump-in-buffer :before #'better-jumper-set-jump)
  )

(use-package lsp-bridge
  :bind (:map
         my-function-map
         ("d" . my-find-def)
         ("r" . my-find-ref)
         :map
         lsp-bridge-ref-mode-map
         ("d" . lsp-bridge-ref-open-file))
  :hook (after-init . global-lsp-bridge-mode)
  :custom
  (acm-enable-tabnine nil)
  (acm-enable-citre nil)
  (lsp-bridge-ref-delete-other-windows nil)
  (lsp-bridge-ref-open-file-in-request-window t)
  (lsp-bridge-ref-kill-temp-buffer-p nil)
  (lsp-bridge-find-def-fallback-function #'my-after-lsp-find-def-failure)
  (lsp-bridge-find-ref-fallback-function #'my-after-lsp-find-ref-failure)
  (lsp-bridge-user-langserver-dir (expand-file-name "lsp.server.conf" user-emacs-directory))
  :config
  (if (eq system-type 'windows-nt) (setq lsp-bridge-python-command "python.exe"))

  (add-to-list 'lsp-bridge-default-mode-hooks 'rust-ts-mode-hook)

  (with-eval-after-load 'better-jumper
    (defun my-find-def ()
      (interactive)
      (better-jumper-set-jump)
      (if (or (eq major-mode 'emacs-lisp-mode)
              (eq major-mode 'lisp-interaction-mode))
          (let ((symb (symbol-at-point)))
            (if (and symb (not (fboundp symb)))
                (find-variable symb)
              (find-function symb)))
        (if lsp-bridge-mode
            (lsp-bridge-find-def)
          (if citre-mode
              (citre-jump)))))

    (defun my-find-ref ()
      (interactive)
      (better-jumper-set-jump)
      (if (or (eq major-mode 'emacs-lisp-mode)
              (eq major-mode 'lisp-interaction-mode))
          (let ((identifier (xref-backend-identifier-at-point 'elisp)))
            (xref--find-xrefs identifier 'references identifier nil))
        (if lsp-bridge-mode
            (lsp-bridge-find-references)
          (if citre-mode
              (call-interactively #'citre-jump-to-reference))))))

  (defun my-after-lsp-find-def-failure (position)
    (deactivate-mark t)
    (if citre-mode
        (let ((line (1+ (nth 1 position)))
              (col (nth 3 position)))
          (message "lsp-bridge find no reference try citre line: %d col: %d" line col)
          (forward-line line)
          (goto-char (+ (line-beginning-position) col))
          (citre-jump))))

  (defun my-after-lsp-find-ref-failure (position)
    (deactivate-mark t)
    (if citre-mode
        (let ((line (1+ (nth 1 position)))
              (col (nth 3 position)))
          (message "lsp-bridge find no reference try citre line: %d col: %d" line col)
          (forward-line line)
          (goto-char (+ (line-beginning-position) col))
          (citre-jump-to-reference))))
  )

(provide 'init-lsp)
