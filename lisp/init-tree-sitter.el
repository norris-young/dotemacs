(use-package treesit-auto
  :hook ((after-init . global-treesit-auto-mode))
  :custom
  (treesit-auto-install 'promot)
  (treesit-auto-langs '(bash c cpp css go html java javascript json python rust typescript))
  :config
  (defun c-ts-mode-setup ()
    ;; Tweak font lock settings
    (setq-local treesit-font-lock-settings
                (append treesit-font-lock-settings
                        (treesit-font-lock-rules

                         :language 'c
                         :feature 'assignment-redef
                         :override t
                         '((assignment_expression
                            left: (field_expression field: (_) @font-lock-variable-name-face)))

                         :language 'c
                         :feature 'keyword-extra
                         :override t
                         '(([(storage_class_specifier) (type_qualifier)] @font-lock-keyword-face))

                         :language 'c
                         :feature 'constant-extra
                         :override t
                         '((["#ifdef" "#ifndef"] (identifier) @font-lock-constant-face)
                           ((identifier) @font-lock-constant-face
                            (:match "^[A-Z_][A-Z_\\d]*$" @font-lock-constant-face)))

                         :language 'c
                         :feature 'operator-extra
                         :override t
                         '((conditional_expression ["?" ":"] @font-lock-operator-face))

                         :language 'c
                         :feature 'update
                         :override t
                         '((update_expression argument: (identifier) @variable))

                         :language 'c
                         :feature 'label-redef
                         :override t
                         '(((statement_identifier) @font-lock-preprocessor-face)))))

    (add-to-list 'treesit-font-lock-feature-list
                 '(assignment-redef keyword-extra constant-extra operator-extra update label-redef)
                 t)
    (setq-local treesit-font-lock-level 5)
    (treesit-font-lock-recompute-features)
    (treesit-font-lock-recompute-features nil '(label variable error))
    )

  (add-hook 'c-ts-mode-hook #'c-ts-mode-setup)
  )

;; (use-package ts-fold
;;   :bind (:map my-codefold-map
;;          ("t" . ts-fold-toggle)
;;          ("m" . ts-fold-close-all)
;;          ("M" . ts-fold-open-all)
;;          ("c" . ts-fold-close)
;;          ("o" . ts-fold-open)
;;          ("O" . ts-fold-open-recursively))
;;   :hook (tree-sitter-mode . ts-fold-mode)
;;   :config
;;   (global-ts-fold-indicators-mode)
;;   (add-hook 'ts-fold-mode-hook #'ts-fold-line-comment-mode)
;;   )

(provide 'init-tree-sitter)
