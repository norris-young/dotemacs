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

(eval-when-compile (require 'better-jumper))
(use-package better-jumper
  :bind (:map
         my-function-map
         ("f" . better-jumper-jump-forward)
         ("b" . better-jumper-jump-backward))
  :custom
  (better-jumper-add-jump-behavior 'replace)
  :hook (after-init . better-jumper-mode)
  :config
  ;; Set jumper in 2 cases:
  ;; 1. jump more than 50 lines or advise some jump functions

  ;; (defconst better-jumper-line-threshold 50)
  ;; (defun my-post-command-set-jumper ()
  ;;   (if (and (not (eq this-command #'better-jumper-jump-forward))
  ;;            (not (eq this-command #'better-jumper-jump-backward)))
  ;;       (let* ((oldp (window-old-point))
  ;;              (newp (window-point))
  ;;              (oldl (line-number-at-pos oldp))
  ;;              (newl (line-number-at-pos newp)))
  ;;         (if (> (abs (- oldl newl))
  ;;                better-jumper-line-threshold)
  ;;             (better-jumper-set-jump oldp)))))
  ;; (add-hook 'post-command-hook #'my-post-command-set-jumper)

  (defun my-set-jump (&rest _)
    (better-jumper-set-jump))

  (with-eval-after-load 'meow
    (advice-add #'meow-beginning-of-thing :before #'my-set-jump)
    (advice-add #'meow-end-of-thing :before #'my-set-jump))
  (with-eval-after-load 'counsel
    (advice-add #'counsel-jump-in-buffer :before #'my-set-jump))
  (with-eval-after-load 'swiper
    (advice-add #'swiper-isearch :before #'my-set-jump))
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
  (lsp-bridge-user-langserver-dir "~/.emacs.d/lsp.server.conf")
  (lsp-bridge-remote-start-automatically t)
  (lsp-bridge-remote-heartbeat-interval 600)
  :config
  (eval-when-compile (require 'lsp-bridge))
  (if (eq system-type 'windows-nt)
      (setq lsp-bridge-python-command "python.exe")
    (setq lsp-bridge-python-command "~/.emacs.d/lsp.bridge.pyenv/bin/python"))

  (add-to-list 'lsp-bridge-default-mode-hooks 'rust-ts-mode-hook)
  (cl-delete 'org-mode-hook lsp-bridge-default-mode-hooks)
  (advice-add #'lsp-bridge-mode :before
              (lambda (&rest _)
                (when-let* ((project (project-current))
                            (project-root (nth 2 project)))
                  (when (file-exists-p (expand-file-name ".project.lsp.config" project-root))
                    (setq-local lsp-bridge-user-langserver-dir (file-local-name project-root))
                    (setq-local lsp-bridge-user-multiserver-dir (file-local-name project-root))))))

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
        (let ((line (nth 1 position))
              (col (nth 3 position)))
          (message "lsp-bridge find no reference try citre line: %d col: %d" (1+ line) col)
          (goto-char 1)
          (forward-line line)
          (goto-char (+ (line-beginning-position) col))
          (call-interactively 'citre-jump))))

  (defun my-after-lsp-find-ref-failure (position)
    (deactivate-mark t)
    (if citre-mode
        (let ((line (nth 1 position))
              (col (nth 3 position)))
          (message "lsp-bridge find no reference try citre line: %d col: %d" (1+ line) col)
          (goto-char 1)
          (forward-line line)
          (goto-char (+ (line-beginning-position) col))
          (call-interactively 'citre-jump-to-reference))))

  (defun is-lsp-bridge-process-buffer (buffer)
    (let* ((epc-con (cl-struct-slot-value 'lsp-bridge-epc-manager 'connection lsp-bridge-epc-process))
           (epc-process (if epc-con (cl-struct-slot-value 'lsp-bridge-epc-connection 'process epc-con))))
      (or (eq buffer (process-buffer lsp-bridge-internal-process))
          (eq buffer (process-buffer epc-process)))))
  )

(provide 'init-lsp)
