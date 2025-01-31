;;; ...  -*- lexical-binding: t -*-

(defvar my-autoloads-dir
  (concat (file-name-as-directory my-lisp-dir) "autoloads"))
(defvar my-autoloads-file
  (expand-file-name "my-autoloads.el" my-lisp-dir))

(add-to-list 'load-path my-lisp-dir)
(add-to-list 'load-path my-autoloads-dir)

(setq native-comp-async-report-warnings-errors 'silent)
(if (not (file-exists-p my-autoloads-file))
    (loaddefs-generate my-lisp-dir my-autoloads-file))
(load my-autoloads-file)

(package-subdirs-recurse #'add-loadpath my-packages-dir)
(add-loadpath my-sitelisp-dir)
(package-subdirs-recurse #'add-loadpath my-sitelisp-dir)

(if (not (file-directory-p my-autoloads-dir))
    (progn
      (require 'bytecomp)
      (make-directory my-autoloads-dir)
      (let ((byte-compile-log-warning-function (lambda (&rest _))))
        (package-subdirs-recurse #'my-collect-package-generated-autoloads
                                 my-packages-dir))
      (native-compile-async my-lisp-dir nil nil "myfun.*")
      ))

(cl-dolist (alf (directory-files my-autoloads-dir nil "^[^.].*"))
  (load (file-name-base alf) nil t))

;; Should set before loading `use-package'
(setq use-package-always-defer t)
(setq use-package-always-demand nil)
(setq use-package-expand-minimally nil)
(setq use-package-enable-imenu-support t)

;; (use-package auto-compile
;;   :init
;;   (setq load-prefer-newer t)
;;   :demand
;;   :config
;;   (auto-compile-on-load-mode)
;;   (auto-compile-on-save-mode))

(provide 'init-autoloads)
