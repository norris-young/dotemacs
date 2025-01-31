;;; ...  -*- lexical-binding: t -*-

(require 'package)
(require 'ivy)

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
    (message "byte compiling for package [%s] in [%s]..." name pkg-dir)
    ;(native-compile-directory pkg-dir)
    ;; (message "native compilation for package [%s] in [%s] started" name pkg-dir)
    (native-compile-async pkg-dir t)
    )
  )

;;;###autoload
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
