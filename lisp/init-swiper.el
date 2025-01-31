;;; ...  -*- lexical-binding: t -*-

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
  )

(use-package avy
  :custom (avy-all-windows t)
  :config
  (avy-setup-default))

(provide 'init-swiper)
