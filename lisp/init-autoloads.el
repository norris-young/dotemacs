(defvar my-autoloads-dir
  (concat (file-name-as-directory my-lisp-dir) "autoloads"))

(add-to-list 'load-path my-autoloads-dir)

(cl-dolist (alf (directory-files my-autoloads-dir nil "^[^.].*"))
  (load (file-name-base alf) nil t))

(provide 'init-autoloads)
