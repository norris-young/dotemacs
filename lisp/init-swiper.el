;; flx package is used for ivy fuzzy match engine
(use-package ivy
  :defer 0.5
  :bind (("C-x b". ivy-switch-buffer)
         :map my-buffer-map
         ("b" . ivy-switch-buffer)
         :map my-search-map
         ("r" . ivy-resume)
         :map ivy-switch-buffer-map
         ("C-j" . ivy-next-line)
         ("C-k" . ivy-previous-line)
         :map ivy-reverse-i-search-map
         ("C-j" . ivy-next-line)
         ("C-k" . ivy-previous-line)
         :map ivy-minibuffer-map
         ("C-j" . ivy-next-line)
         ("C-k" . ivy-previous-line)
         ("M-RET" . ivy-alt-done)
         ("C-<return>" . ivy-immediate-done))
  :custom
  (ivy-use-virtual-buffers t)
  (ivy-initial-inputs-alist nil)
  (ivy-count-format "(%d/%d) ")
  :load (flx)
  :config
  (defun ivy-yank-action (x)
    (kill-new x))

  (defun ivy-copy-to-buffer-action (x)
    (with-ivy-window (insert x)))

  (ivy-set-actions t
   '(("i" ivy-copy-to-buffer-action "insert")
     ("y" ivy-yank-action "yank")))

  (setq ivy-re-builders-alist '((t . ivy--regex-ignore-order)))
  (ivy-mode 1))

(use-package swiper
  :bind (:map my-search-map
         ("s" . swiper-isearch)
         ("w" . swiper-isearch-thing-at-point)))

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
         :map my-file-map
         ("f" . counsel-find-file)
         :map my-search-map
         ("g" . counsel-rg)
         ("j" . counsel-jump-in-buffer))
  :config
  (defun counsel-jump-in-buffer ()
    "Jump in buffer with `counsel-imenu' or `counsel-org-goto' if in org-mode"
    (interactive)
    (call-interactively
     (cond
      ((eq major-mode 'org-mode) 'counsel-org-goto)
      (t 'counsel-imenu)))))

(provide 'init-swiper)
