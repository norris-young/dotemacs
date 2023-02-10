(setq-default initial-scratch-message
              (concat ";; Hello, " user-login-name " - Emacs ♥ you!\n\n"))

(use-package help-fns+ :defer 1)

(use-package package
  :commands (my-generate-autoloads)
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

(provide 'init-lisp)
