(use-package treesit-auto
  :mode ("\\.rs\\'" . rust-ts-mode)
  :hook ((after-init . global-treesit-auto-mode))
  :custom
  (treesit-auto-install 'promot)
  :config

  (add-to-list 'treesit-auto-recipe-list
               (make-treesit-auto-recipe
                :lang 'c
                :ts-mode 'c-or-c++-ts-mode
                :remap 'c-or-c++-mode
                :url "https://github.com/tree-sitter/tree-sitter-c"))

  (defun my-subscript-identifier (node)
    (pcase (treesit-node-type node)
      ;; Recurse.
      ("subscript_expression"
       (my-subscript-identifier (treesit-node-child node 0 t)))
      ("field_expression"
       (treesit-node-child-by-field-name node "field"))
      ("pointer_expression"
       (treesit-node-child-by-field-name node "argument"))
      ("identifier" node)))

  (defun my-fontify-subscript-expression-identifier (node override start end &rest _args)
    (let ((identifier (my-subscript-identifier node)))
      (when identifier
        (treesit-fontify-with-override
         (treesit-node-start identifier) (treesit-node-end identifier)
         'font-lock-variable-name-face override start end))))

  (defun c-ts-mode-setup ()
    ;; Tweak font lock settings
    (setq-local treesit-font-lock-settings
                (append treesit-font-lock-settings
                        (treesit-font-lock-rules

                         :language 'c
                         :feature 'assignment-redef
                         :override t
                         '((assignment_expression
                            left: (identifier) @font-lock-variable-name-face)
                           (assignment_expression
                            left: (field_expression field: (_) @font-lock-variable-name-face))
                           (assignment_expression
                            left: (pointer_expression
                                   (identifier) @font-lock-variable-name-face))
                           (assignment_expression
                            left: (subscript_expression
                                   argument: (_) @my-fontify-subscript-expression-identifier))
                           (init_declarator declarator: (_) @c-ts-mode--fontify-declarator))

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
                         '((update_expression argument: (identifier) @font-lock-variable-name-face))

                         :language 'c
                         :feature 'label-redef
                         :override t
                         '(((statement_identifier) @font-lock-preprocessor-face)))))

    (add-to-list 'treesit-font-lock-feature-list
                 '(assignment-redef keyword-extra constant-extra operator-extra update label-redef)
                 t)
    (setq-local treesit-font-lock-level 5)
    (treesit-font-lock-recompute-features)
    (treesit-font-lock-recompute-features nil '(label variable assignment error))
    )

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
  :hook (after-init . global-treesit-fold-mode)
  :config
  (global-treesit-fold-indicators-mode)
  (add-hook 'treesit-fold-mode-hook #'treesit-fold-line-comment-mode)
  )

(provide 'init-tree-sitter)
