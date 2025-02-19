;;; ...  -*- lexical-binding: t -*-

(require 'cl-lib)

(setq user-init-file (or load-file-name (buffer-file-name)))
(setq user-emacs-directory (file-name-directory user-init-file))
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(if (file-exists-p custom-file) (load custom-file t t))

(defconst my-emacs-d (file-name-as-directory user-emacs-directory)
  "Directory of emacs.d.")

(defconst my-sitelisp-dir (concat my-emacs-d "site-lisp")
  "Directory of site-lisp.")

(defconst my-packages-dir (concat my-emacs-d "packages")
  "Directory of packages.")

(defconst my-lisp-dir (concat my-emacs-d "lisp")
  "Directory of personal configuration.")

(defun require-init (pkg &optional disabled)
  "Load PKG if DISABLED is nil."
  (when (not disabled)
    (load (file-truename (format "%s/%s" my-lisp-dir pkg)) t t)))

;; @see https://www.reddit.com/r/emacs/comments/3kqt6e/2_easy_little_known_steps_to_speed_up_emacs_start/
;; Normally file-name-handler-alist is set to
;; (("\\`/[^/]*\\'" . tramp-completion-file-name-handler)
;; ("\\`/[^/|:][^/|]*:" . tramp-file-name-handler)
;; ("\\`/:" . file-name-non-special))
;; Which means on every .el and .elc file loaded during start up, it has to runs those regexps against the filename.
(let* ((file-name-handler-alist nil))
  (require-init 'init-autoloads)
  (require-init 'init-lisp)
  (require-init 'init-meow)
  (require-init 'init-tree-sitter)
  (require-init 'init-git)
  (require-init 'init-input)
  (require-init 'init-misc)
  (require-init 'init-org)
  (require-init 'init-completion)
  (require-init 'init-ui)
  (require-init 'init-window)
  (require-init 'init-c)
  (require-init 'init-lsp)
  (require-init 'init-prog)
  (require-init 'init-gc)
  )
