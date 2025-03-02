;;; ...  -*- lexical-binding: t -*-

(require 'treesit)

;;;###autoload
(defun my-choose-c-style ()
  (if (string-match "linux" (buffer-file-name))
      (c-set-style "linux-kernel")
    (c-set-style "linux-user")))

;;;###autoload
(defun my-comment-dwim ()
  (interactive)
  (let ((lines (if (use-region-p)
                   (count-lines (region-beginning) (region-end))
                 1)))
    (if (eq lines 1)
        (setq comment-style 'indent)
      (setq comment-style 'extra-line))
    (if (and (use-region-p)
             (eq lines 1))
        (progn
          (comment-or-uncomment-region (region-beginning) (region-end)))
      (comment-line nil))))

;;;###autoload
(defun my-choose-c-ts-style ()
  (if (string-match "linux" (buffer-file-name))
      (setq-local c-ts-mode-indent-offset 8
                  tab-width 8
                  indent-tabs-mode t)
    (setq-local c-ts-mode-indent-offset 4
                tab-width 4
                indent-tabs-mode nil)))

;;;###autoload
(defun tweak-style (styles)
  (let* ((style (car styles))
         (rules (cdr style)))
    (setcdr style (append `(;; Opening bracket.
                            ((match "compound_statement" "compound_statement") standalone-parent c-ts-mode-indent-offset)
                            ((node-is "compound_statement") standalone-parent 0)
                          rules)))
  styles)

;;;###autoload
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

;;;###autoload
(defun my-fontify-subscript-expression-identifier (node override start end &rest _args)
  (let ((identifier (my-subscript-identifier node)))
    (when identifier
      (treesit-fontify-with-override
       (treesit-node-start identifier) (treesit-node-end identifier)
       'font-lock-variable-name-face override start end))))

;;;###autoload
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
