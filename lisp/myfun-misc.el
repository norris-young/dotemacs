;;; ...  -*- lexical-binding: t -*-

(require 'smartparens)
(require 'project)
(require 'gdb-mi)
(require 'winum)

;;;###autoload
(defun my-wrap-with-pair (c)
  (interactive "c")
  (let ((active-pair (char-to-string c)))
    (cl-dolist (pair sp-pair-list)
      (if (or (equal (car pair) active-pair)
              (equal (cdr pair) active-pair))
          (progn
            (sp-wrap-with-pair (car pair))
            (cl-return))))))

;;;###autoload
(defun my-find-file-in-same-window (ff filename &optional wildcards)
  (let ((buf (get-file-buffer filename)))
    (if buf
        (switch-to-buffer buf)
      (apply ff `(,filename ,wildcards)))))

;;;###autoload
(defun move-to-gud-after-first-memory-udpate ()
  (winum-select-window-7)
  (advice-remove #'gdb-read-memory-handler
                 #'move-to-gud-after-first-memory-udpate))

;;;###autoload
(defun revert-project-buffer ()
  (interactive)
  (dolist (buf (project-buffers (project-current)))
    (with-current-buffer buf
      (when (buffer-file-name buf)
        (revert-buffer nil t)))))

;;;###autoload
(defun project-kill-other-buffers ()
  (interactive)
  (let ((bufs (delq (current-buffer) (project--buffers-to-kill (project-current)))))
    (mapc #'kill-buffer bufs)))
