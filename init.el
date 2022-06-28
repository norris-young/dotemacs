;;; Code:

(setq user-init-file (or load-file-name (buffer-file-name)))
(setq user-emacs-directory (file-name-directory user-init-file))
(defconst my-emacs-d (file-name-as-directory user-emacs-directory)
  "Directory of emacs.d.")

(defconst my-site-lisp-dir (concat my-emacs-d "site-lisp")
  "Directory of site-lisp.")

(defconst my-lisp-dir (concat my-emacs-d "lisp")
  "Directory of personal configuration.")

(defun add-subdirs-to-load-path (&rest _)
  "Add subdirectories to `load-path'.
Don't put large files in `site-lisp' directory, e.g. EAF.
Otherwise the startup will be very slow. "
  (let ((default-directory my-site-lisp-dir))
    (normal-top-level-add-subdirs-to-load-path)))

(defun require-init (pkg &optional disabled)
  "Load PKG if DISABLED is nil."
  (when (not disabled)
    (load (file-truename (format "%s/%s" my-lisp-dir pkg)) t t)))

(setq custom-file (expand-file-name (concat my-emacs-d "custom.el")))
(if (file-exists-p custom-file) (load custom-file t t))

(require 'package)
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)

;; Setup `use-package'
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; Should set before loading `use-package'
(eval-and-compile
  (setq use-package-always-ensure t)
  ;; (setq use-package-always-defer nil)
  ;; (setq use-package-always-demand nil)
  ;; (setq use-package-expand-minimally nil)
  ;; (setq use-package-enable-imenu-support nil)
  )

(eval-when-compile
  (require 'use-package))

;; @see https://www.reddit.com/r/emacs/comments/3kqt6e/2_easy_little_known_steps_to_speed_up_emacs_start/
;; Normally file-name-handler-alist is set to
;; (("\\`/[^/]*\\'" . tramp-completion-file-name-handler)
;; ("\\`/[^/|:][^/|]*:" . tramp-file-name-handler)
;; ("\\`/:" . file-name-non-special))
;; Which means on every .el and .elc file loaded during start up, it has to runs those regexps against the filename.
(let* ((file-name-handler-alist nil))
  (require-init 'init-ui)
  (require-init 'init-misc)
  (require-init 'init-swiper)
  (require-init 'init-git)
  (require-init 'init-window)
  (require-init 'init-meow)
  )

;; (setq garbage-collection-messages t) ; for debug
(defun post-init-gc ()
  "Do the gc we deferred in early-init.el"
  (setq gc-cons-threshold (* 16 1024 1024)) ; 16M
  (setq gc-cons-percentage 0.1) ; original value
  (garbage-collect))

(run-with-idle-timer 4 nil #'post-init-gc)
