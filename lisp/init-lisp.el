(setq-default initial-scratch-message
              (concat ";; Hello, " user-login-name " - Emacs ♥ you!\n\n"))

(use-package help-fns+ :defer 1)

(use-package package
  :config
  (defun my-collect-package-generated-autoloads (pkg-dir name)
    (let* ((filename (format "%s-autoloads.el" name))
           (file (expand-file-name filename pkg-dir))
           (target (expand-file-name
                    filename
                    (file-name-as-directory my-autoloads-dir))))
      (delete-file file)
      (message "generating autoloads for package [%s] in [%s]..." name pkg-dir)
      (package-generate-autoloads name pkg-dir)
      (delete-file target)
      (rename-file file target)))

  (defun my-generate-autoloads (path pkg)
    (interactive (list (ivy-read "Generate path:" 'read-file-name-internal
                                 :initial-input my-packages-dir)
                       (completing-read "Package name:" '(""))))
    (if (> (length pkg) 0)
        (progn
          (my-collect-package-generated-autoloads path pkg)
          (package-subdirs-recurse #'my-collect-package-generated-autoloads path pkg))
      (package-subdirs-recurse #'my-collect-package-generated-autoloads path)))
  )

(use-package edebug
  :bind (:map edebug-mode-map
         ("A" . 'my-elisp-add-to-watch))
  :config
  ;; Simple watch window from emacswiki @https://www.emacswiki.org/emacs/SourceLevelDebugger
  (defun my-elisp-add-to-watch (&optional region-start region-end)
    "Add the current variable to the *EDebug* window"
    (interactive "r")
    (let ((statement
             (if (and region-start region-end (use-region-p))
               (buffer-substring region-start region-end)
             (symbol-name (elisp--current-symbol)))))
      ;; open eval buffer
      (edebug-visit-eval-list)
      ;; jump to the end of it and add a newline
      (goto-char (point-max))
      (newline)
      ;; insert the variable
      (insert statement)
      ;; update the list
      (edebug-update-eval-list)
      ;; jump back to where we were
      (edebug-where)))
  )

(use-package edebug-x
  :hook (edebug-mode . edebug-x-mode))

(provide 'init-lisp)
