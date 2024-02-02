;; flx package is used for ivy fuzzy match engine
(use-package ivy
  :defer 0.5
  :bind (("C-x b". ivy-switch-buffer)
         :map
         my-file-map
         ("R" . my-rename-file)
         :map
         my-buffer-map
         ("b" . ivy-switch-buffer)
         :map
         my-search-map
         ("r" . ivy-resume))
  :custom
  (ivy-use-virtual-buffers t)
  (ivy-initial-inputs-alist nil)
  (ivy-count-format "(%d/%d) ")
  :load (flx)
  :config

  (defun my-rename-file (newname)
    (interactive (list (ivy-read "new file name: " 'read-file-name-internal
                                 :initial-input (buffer-file-name))))
    (let ((oname (buffer-file-name)))
      (if (not (equal oname newname))
          (progn
            (set-visited-file-name newname t t)
            (rename-file oname newname)))))

  (defun ivy-yank-action (x)
    (kill-new x))

  (defun ivy-copy-to-buffer-action (x)
    (with-ivy-window (insert x)))

  (ivy-set-actions t '(("i" ivy-copy-to-buffer-action "insert")
                       ("y" ivy-yank-action "yank")))

  (setq ivy-re-builders-alist '((t . ivy--regex-ignore-order)))
  (ivy-mode 1))

(use-package swiper
  :bind (:map
         my-search-map
         ("s" . swiper-isearch)
         ("S" . swiper-isearch-thing-at-point)))

(use-package counsel
  :bind (("M-x"     . counsel-M-x)
         ("M-y"     . counsel-yank-pop)
         ("C-x C-f" . counsel-find-file)
         ("<f1> f"  . counsel-describe-function)
         ("<f1> v"  . counsel-describe-variable)
         ("<f1> l"  . counsel-find-library)
         ("<f2> i"  . counsel-info-lookup-symbol)
         ("<f2> u"  . counsel-unicode-char)
         ("<f2> j"  . counsel-set-variable)
         :map
         my-file-map
         ("f" . counsel-find-file)
         :map
         my-search-map
         ("g" . counsel-rg)
         ("G" . counsel-rg-thing-at-point)
         ("d" . counsel-rg-thing-in-directory)
         ("D" . counsel-rg-thing-at-point-in-directory)
         ("j" . counsel-jump-in-buffer))
  :custom
  (counsel-find-file-ignore-regexp "\\.o\\'\\|\\.o\\.d\\'\\|\\`#\\|.*\\..*~\\'\\|\\`\\..*\\.cmd\\'")
  :config
  (setq counsel-find-file-speedup-remote nil)
  (defun counsel-jump-in-buffer ()
    "Jump in buffer with `counsel-imenu' or `counsel-org-goto' if in org-mode"
    (interactive)
    (call-interactively
     (cond
      ((eq major-mode 'org-mode) 'counsel-org-goto)
      (t 'counsel-imenu))))

  (defun counsel-rg-thing-at-point ()
    (interactive)
    (let ((thing (ivy-thing-at-point)))
      (when (use-region-p)
        (deactivate-mark))
      (counsel-rg (regexp-quote thing))))

  (defun counsel-rg-thing-in-directory (path)
    (interactive "DDirectory for ripgrep:")
    (counsel-rg nil path))

  (defun counsel-rg-thing-at-point-in-directory (path)
    (interactive "DDirectory for ripgrep:")
    (let ((thing (ivy-thing-at-point)))
      (when (use-region-p)
        (deactivate-mark))
      (counsel-rg (regexp-quote thing) path)))
  )

(use-package avy
  :bind (:map
         my-visit-map
         ("v" . avy-goto-word-1)
         ("l" . avy-goto-line))
  :custom (avy-all-windows t)
  :config
  (avy-setup-default))

(provide 'init-swiper)
