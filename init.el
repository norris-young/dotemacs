;;; ...  -*- lexical-binding: t -*-

(require 'cl-lib)

(setq user-init-file (or load-file-name (buffer-file-name)))
(setq user-emacs-directory (file-name-directory user-init-file))
(defconst my-emacs-d (file-name-as-directory user-emacs-directory)
  "Directory of emacs.d.")

(defconst my-sitelisp-dir (concat my-emacs-d "site-lisp")
  "Directory of site-lisp.")

(defconst my-packages-dir (concat my-emacs-d "packages")
  "Directory of packages.")

(defconst my-lisp-dir (concat my-emacs-d "lisp")
  "Directory of personal configuration.")

(defun package-subdirs-recurse (func search-dir &optional pp)
  (let* ((dir (file-name-as-directory search-dir)))
    (dolist (subdir
             ;; 过滤出不必要的目录，提升Emacs启动速度
             (cl-remove-if
              #'(lambda (subdir)
                  (or
                   ;; 不是目录的文件都移除
                   (not (file-directory-p (concat dir subdir)))
                   ;; 父目录、 语言相关和版本控制目录都移除
                   (member subdir '("." ".."
                                    "dist" "node_modules" "__pycache__"
                                    "RCS" "CVS" "rcs" "cvs" ".git" ".github"))))
              (directory-files dir)))
      (let* ((subdir-path (concat dir (file-name-as-directory subdir)))
             (sp (directory-file-name subdir))
             (cp (if (not pp) sp
                   (concat pp "-" sp))))
        ;; 目录下有 .el .so .dll 文件的路径才添加到 `load-path' 中，提升Emacs启动速度
        (when (cl-some #'(lambda (subdir-file)
                           (and (file-regular-p (concat subdir-path subdir-file))
                                ;; .so .dll 文件指非Elisp语言编写的Emacs动态库
                                (member (file-name-extension subdir-file) '("el" "so" "dll"))))
                       (directory-files subdir-path))
          (funcall func subdir-path cp))
        ;; 继续递归搜索子目录
        (package-subdirs-recurse func subdir-path cp)))))

(defun add-loadpath (path &rest _)
  ;; 注意：`add-to-list' 函数的第三个参数必须为 t ，表示加到列表末尾
  ;; 这样Emacs会从父目录到子目录的顺序搜索Elisp插件，顺序反过来会导致Emacs无法正常启动
  (add-to-list 'load-path path t))

(package-subdirs-recurse #'add-loadpath my-packages-dir)
(add-loadpath my-sitelisp-dir)
(package-subdirs-recurse #'add-loadpath my-sitelisp-dir)

(defun require-init (pkg &optional disabled)
  "Load PKG if DISABLED is nil."
  (when (not disabled)
    (load (file-truename (format "%s/%s" my-lisp-dir pkg)) t t)))

(use-package auto-compile
  :init
  (setq load-prefer-newer t)
  :demand
  :config
  (auto-compile-on-load-mode)
  (auto-compile-on-save-mode))

(setq custom-file (expand-file-name (concat my-emacs-d "custom.el")))
(if (file-exists-p custom-file) (load custom-file t t))

;; Should set before loading `use-package'
(setq use-package-always-defer t)
(setq use-package-always-demand nil)
(setq use-package-expand-minimally nil)
;; (setq use-package-enable-imenu-support nil)

(require 'package)
(setq native-comp-async-report-warnings-errors 'silent)
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
    (rename-file file target)
    (message "byte compiling for package [%s] in [%s]..." name pkg-dir)
    ;(native-compile-directory pkg-dir)
    ;; (message "native compilation for package [%s] in [%s] started" name pkg-dir)
    (native-compile-async pkg-dir t)
    )
  )

(defun my-generate-autoloads (path)
  (interactive (list (ivy-read "Generate path:" 'read-file-name-internal
                               :initial-input my-packages-dir)))
  (let ((pkg (file-name-base (directory-file-name path))))
    (if (equal pkg "packages")
        (package-subdirs-recurse #'my-collect-package-generated-autoloads path)
      (progn
        (my-collect-package-generated-autoloads path pkg)
        (package-subdirs-recurse #'my-collect-package-generated-autoloads path pkg))))
  )

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
  (require-init 'init-swiper)
  (require-init 'init-ui)
  (require-init 'init-window)
  (require-init 'init-c)
  (require-init 'init-lsp)
  (require-init 'init-prog)
  )

;; (setq garbage-collection-messages t) ; for debug
(defun post-init-gc ()
  "Do the gc we deferred in early-init.el"
  (setq gc-cons-threshold (* 128 1024 1024)) ; 128M
  (setq gc-cons-percentage 0.1) ; original value
  (garbage-collect))

(run-with-idle-timer 4 nil #'post-init-gc)
