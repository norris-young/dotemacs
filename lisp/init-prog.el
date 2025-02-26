;;; ...  -*- lexical-binding: t -*-

(use-package imenu-list
  :bind (:map my-buffer-map
         ("i" . imenu-list-smart-toggle)
         :map imenu-list-major-mode-map
         ("d" . imenu-list-display-dwim))
  :custom
  (imenu-list-size 0.12))

(use-package yaml-ts-mode
  :defer t
  :init
  (add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-ts-mode)))

(provide 'init-prog)
