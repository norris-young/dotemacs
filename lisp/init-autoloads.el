(defvar my-autoloads-dir
  (concat (file-name-as-directory my-lisp-dir) "autoloads"))

(if (not (file-directory-p my-autoloads-dir))
    (progn
      (make-directory my-autoloads-dir)
      (add-hook 'after-init-hook (lambda ()
                                   (package-subdirs-recurse
                                    #'my-collect-package-generated-autoloads
                                    my-packages-dir)))))

(add-to-list 'load-path my-autoloads-dir)

(cl-dolist (alf (directory-files my-autoloads-dir nil "^[^.].*"))
  (load (file-name-base alf) nil t))

(provide 'init-autoloads)
