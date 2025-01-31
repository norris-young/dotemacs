;;; ...  -*- lexical-binding: t -*-

(defvar my-autoloads-dir
  (concat (file-name-as-directory my-lisp-dir) "autoloads"))

(add-to-list 'load-path my-autoloads-dir)

(setq native-comp-async-report-warnings-errors 'silent)
(if (not (file-directory-p my-autoloads-dir))
    (progn
      (make-directory my-autoloads-dir)
      (loaddefs-generate my-lisp-dir (expand-file-name "my-autoloads.el" my-autoloads-dir))
      (load (expand-file-name "my-autoloads.el" my-autoloads-dir))
      (let ((byte-compile-log-warning-function (lambda (&rest _))))
        (package-subdirs-recurse #'my-collect-package-generated-autoloads
                                 my-packages-dir))))
(load (expand-file-name "my-autoloads.el" my-autoloads-dir))
(native-compile-async my-lisp-dir nil nil "myfun.*")

(package-subdirs-recurse #'add-loadpath my-packages-dir)
(add-loadpath my-sitelisp-dir)
(package-subdirs-recurse #'add-loadpath my-sitelisp-dir)

(cl-dolist (alf (directory-files my-autoloads-dir nil "^[^.].*"))
  (load (file-name-base alf) nil t))

(provide 'init-autoloads)
