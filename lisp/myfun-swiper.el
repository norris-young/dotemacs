;;; ...  -*- lexical-binding: t -*-

(require 'ivy)
(require 'swiper)
(require 'counsel)

;;;###autoload
(defun my-rename-file (newname)
  (interactive (list (ivy-read "new file name: " 'read-file-name-internal
                               :initial-input (buffer-file-name))))
  (let ((oname (buffer-file-name)))
    (if (not (equal oname newname))
        (progn
          (set-visited-file-name newname t t)
          (rename-file oname newname)))))

;;;###autoload
(defun ivy-yank-action (x)
  (kill-new x))

;;;###autoload
(defun ivy-copy-to-buffer-action (x)
  (with-ivy-window (insert x)))

;;;###autoload
(defun counsel-jump-in-buffer ()
  "Jump in buffer with `counsel-imenu' or `counsel-org-goto' if in org-mode"
  (interactive)
  (call-interactively
   (cond
    ((eq major-mode 'org-mode) 'counsel-org-goto)
    (t 'counsel-imenu))))

;;;###autoload
(defun counsel-rg-thing-at-point ()
  (interactive)
  (with-eval-after-load 'ivy
    (let ((thing (ivy-thing-at-point)))
     (when (use-region-p)
       (deactivate-mark))
     (counsel-rg (regexp-quote thing)))))

;;;###autoload
(defun counsel-rg-thing-in-directory (path)
  (interactive "DDirectory for ripgrep:")
  (counsel-rg nil path))

;;;###autoload
(defun counsel-rg-thing-at-point-in-directory (path)
  (interactive "DDirectory for ripgrep:")
  (with-eval-after-load 'ivy
    (let ((thing (ivy-thing-at-point)))
     (when (use-region-p)
       (deactivate-mark))
     (counsel-rg (regexp-quote thing) path))))
