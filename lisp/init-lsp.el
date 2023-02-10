(use-package yasnippet
  :hook (after-init . yas-global-mode))

(use-package lsp-bridge
  :bind (:map my-function-map
         ("d" . my-find-def)
         ("r" . my-find-ref)
         ("b" . xref-go-back))
  :hook (after-init . global-lsp-bridge-mode)
  :custom
  (acm-enable-citre t)
  (lsp-bridge-find-def-fallback-function #'my-after-lsp-find-def-failure)
  (lsp-bridge-find-ref-fallback-function #'my-after-lsp-find-ref-failure)
  :config
  (defun my-find-def ()
    (interactive)
    (xref-push-marker-stack (point-marker))
    (if (or (eq major-mode 'emacs-lisp-mode)
            (eq major-mode 'lisp-interaction-mode))
        (let ((symb (symbol-at-point)))
          (if (and symb (not (fboundp symb)))
              (find-variable symb)
            (find-function symb)))
      (lsp-bridge-find-def)))

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
      (progn
        (xref-push-marker-stack (point-marker))
        (lsp-bridge-find-references))))

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
