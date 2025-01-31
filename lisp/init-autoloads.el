;;; ...  -*- lexical-binding: t -*-

(defvar my-autoloads-dir
  (concat (file-name-as-directory my-lisp-dir) "autoloads"))

(if (not (file-directory-p my-autoloads-dir))
    (progn
      (make-directory my-autoloads-dir)
      (loaddefs-generate my-lisp-dir (expand-file-name "my-autoloads.el" my-autoloads-dir))
      (let ((byte-compile-log-warning-function (lambda (&rest _))))
        (package-subdirs-recurse #'my-collect-package-generated-autoloads
                                 my-packages-dir))))

(native-compile-async my-lisp-dir nil nil "myfun.*")
(add-to-list 'load-path my-autoloads-dir)

(cl-dolist (alf (directory-files my-autoloads-dir nil "^[^.].*"))
  (load (file-name-base alf) nil t))

(provide 'init-autoloads)
