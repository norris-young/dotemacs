(use-package yasnippet
  :hook (after-init . yas-global-mode))

(use-package xref
  :autoload xref-push-marker-stack)

(use-package lsp-bridge
  :bind (:map my-function-map
         ("d" . my-find-def)
         ("r" . my-find-ref)
         ("b" . xref-go-back))
  :hook (after-init . global-lsp-bridge-mode)
  :custom
  (acm-enable-tabnine nil)
  (acm-enable-citre nil)
  (lsp-bridge-find-def-fallback-function #'my-after-lsp-find-def-failure)
  (lsp-bridge-find-ref-fallback-function #'my-after-lsp-find-ref-failure)
  (lsp-bridge-user-langserver-dir (expand-file-name "lsp.server.conf" user-emacs-directory))
  :config
  (if (eq system-type 'windows-nt) (setq lsp-bridge-python-command "python.exe"))

  (add-to-list 'lsp-bridge-default-mode-hooks 'rust-ts-mode-hook)

  (defun my-find-def ()
    (interactive)
    (xref-push-marker-stack (point-marker))
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

  (defun my-after-lsp-find-def-failure (position)
    (deactivate-mark t)
    (if citre-mode
        (let ((line (1+ (nth 1 position)))
              (col (nth 3 position)))
          (message "lsp-bridge find no reference try citre line: %d col: %d" line col)
          (goto-line line)
          (goto-char (+ (line-beginning-position) col))
          (citre-jump))))

  (defun my-find-ref ()
    (interactive)
    (if (or (eq major-mode 'emacs-lisp-mode)
            (eq major-mode 'lisp-interaction-mode))
        (let ((identifier (xref-backend-identifier-at-point 'elisp)))
          (xref--find-xrefs identifier 'references identifier nil))
      (if lsp-bridge-mode
          (progn
            (xref-push-marker-stack (point-marker))
            (lsp-bridge-find-references))
        (if citre-mode
            (call-interactively #'citre-jump-to-reference)))))

  (defun my-after-lsp-find-ref-failure (position)
    (deactivate-mark t)
    (if citre-mode
        (let ((line (1+ (nth 1 position)))
              (col (nth 3 position)))
          (message "lsp-bridge find no reference try citre line: %d col: %d" line col)
          (goto-line line)
          (goto-char (+ (line-beginning-position) col))
          (citre-jump-to-reference))))
  )

(provide 'init-lsp)
