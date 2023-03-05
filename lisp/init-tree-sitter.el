;; (use-package treesit-auto
;;   :hook (after-init . global-treesit-auto-mode)
;;   :config
;;   (setq treesit-auto-install 'prompt))

(use-package tree-sitter
  :defer 1
  :config
  (require 'tree-sitter-langs)
  (add-hook 'prog-mode-hook #'tree-sitter-mode)
  (add-hook 'tree-sitter-mode-hook #'tree-sitter-hl-mode))
  ;; This makes every node a link to a section of code
  ;; (setq tree-sitter-debug-jump-buttons t
  ;;       ;; and this highlights the entire sub tree in your code
  ;;       tree-sitter-debug-highlight-jump-region t))

(use-package ts-fold
  :bind (:map my-codefold-map
         ("t" . ts-fold-toggle)
         ("m" . ts-fold-close-all)
         ("M" . ts-fold-open-all)
         ("c" . ts-fold-close)
         ("o" . ts-fold-open)
         ("O" . ts-fold-open-recursively))
  :hook (tree-sitter-mode . ts-fold-mode)
  :config
  (global-ts-fold-indicators-mode)
  (add-hook 'ts-fold-mode-hook #'ts-fold-line-comment-mode)
  )

(provide 'init-tree-sitter)
