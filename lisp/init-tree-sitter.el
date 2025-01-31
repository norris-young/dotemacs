;;; ...  -*- lexical-binding: t -*-

(use-package treesit-auto
  :mode ("\\.rs\\'" . rust-ts-mode)
  :hook ((after-init . global-treesit-auto-mode))
  :custom
  (treesit-auto-install 't)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (delete 'latex treesit-auto-langs)
  (if (not (file-directory-p (expand-file-name "tree-sitter" user-emacs-directory)))
      (let* ((treesit-language-source-alist (treesit-auto--build-treesit-source-alist))
             (to-install (seq-filter (lambda (lang) (not (treesit-ready-p lang t)))
                                     treesit-auto-langs)))
        (mapc 'treesit-install-language-grammar to-install)))

  ;; (add-to-list 'treesit-auto-recipe-list
  ;;              (make-treesit-auto-recipe
  ;;               :lang 'c
  ;;               :ts-mode 'c-or-c++-ts-mode
  ;;               :remap 'c-or-c++-mode
  ;;               :url "https://github.com/tree-sitter/tree-sitter-c"))
  (add-hook 'c-ts-mode-hook #'c-ts-mode-setup)
  )

(use-package treesit-fold
  :bind (:map
         my-codefold-map
         ("t" . treesit-fold-toggle)
         ("m" . treesit-fold-close-all)
         ("M" . treesit-fold-open-all)
         ("c" . treesit-fold-close)
         ("o" . treesit-fold-open)
         ("O" . treesit-fold-open-recursively))
  :hook
  (after-init . global-treesit-fold-mode)
  (after-init . global-treesit-fold-indicators-mode)
  :config
  (add-hook 'treesit-fold-mode-hook #'treesit-fold-line-comment-mode)
  )


(provide 'init-tree-sitter)
