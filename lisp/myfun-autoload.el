;;; ...  -*- lexical-binding: t -*-

(require 'package)

;;;###autoload
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

;;;###autoload
(defun add-loadpath (path &rest _)
  ;; 注意：`add-to-list' 函数的第三个参数必须为 t ，表示加到列表末尾
  ;; 这样Emacs会从父目录到子目录的顺序搜索Elisp插件，顺序反过来会导致Emacs无法正常启动
  (add-to-list 'load-path path t))

;;;###autoload
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
    ;; (message "native compilation for package [%s] in [%s] started" name pkg-dir)
    ;; (native-compile-async pkg-dir t)
    )
  )

;;;###autoload
(defun my-generate-autoloads (path)
  (interactive (list (completing-read "Generate path:" 'read-file-name-internal
                                      nil nil my-packages-dir)))
  (let ((pkg (file-name-base (directory-file-name path))))
    (if (equal pkg "packages")
        (package-subdirs-recurse #'my-collect-package-generated-autoloads path)
      (progn
        (my-collect-package-generated-autoloads path pkg)
        (package-subdirs-recurse #'my-collect-package-generated-autoloads path pkg))))
  )
